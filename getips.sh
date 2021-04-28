#!/bin/bash

# Variables
ipList="/home/CHANGEME/kda/ips.txt"
temp="/home/CHANGEME/kda/temp.txt"
merged="/home/CHANGEME/kda/merged.txt"
noPort="/home/CHANGEME/kda/noport.txt"
runtime="3 minute"
endtime=$(date -ud "$runtime" +%s)

# Loop for 3 minutes
while [[ $(date -u +%s) -le $endtime ]]
do
# If peer list doesnt exist
        if [ ! -f $ipList ]; then
# Get initial peers from Known node
           echo "Getting initial peers"
           curl -sk "https://127.0.0.1:8443/chainweb/0.0/mainnet01/cut/peer?limit=1000" | jq -r '.items[].address| [.hostname, .port] | join(":")' >> $ipList
        else
# If it does, query peers of a random node
           echo "file exists, picking a random node to query"
           randomNode=$(shuf -n 1 $ipList)
           curl -sk --max-time 0.5 "https://$randomNode/chainweb/0.0/mainnet01/cut/peer?limit=1000" | jq -r '.items[].address| [.hostname, .port] | join(":")' >> $temp
# Combine new peers with known list
           echo "Adding new peers"
           touch $merged
           sort -u $temp $ipList > $merged
           rm $temp
           mv $merged $ipList
           sleep 1
        fi
done

# Remove port
sed 's/:.*//' $ipList >> $noPort
mongo admin --eval 'db.ips.remove({})'

# Get the location of each node
cat $noPort | while read node
        do
                curl https://ipapi.co/$node/json/ >> "/home/CHANGEME/kda/nodes/$node.json"
                mongoimport --db admin --collection ips --file /home/CHANGEME/kda/nodes/$node.json --type=json
                sleep 10
done

# Clean Directory for next import
rm /home/CHANGEME/kda/noport.txt
rm /home/CHANGEME/kda/nodes/*
rm /home/CHANGEME/kda/ips.txt
