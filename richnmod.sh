#!/bin/sh

# For each 20 times
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
do
# Copy the DB to avoid locks
   cp /home/CHANGEME/.local/share/chainweb-node/mainnet01/0/sqlite/pact-v1-chain-$i.sqlite /home/CHANGEME/kda/
# Get most recent balance of each account
   sqlite3 -header -csv /home/CHANGEME/kda/pact-v1-chain-$i.sqlite "select rowkey as acct_id, txid, cast(ifnull(json_extract(rowdata, '$.balance.decimal'), json_extract(rowdata, '$.balance')) as REAL) as 'balance'
   from 'coin_coin-table' as coin
   INNER JOIN (
    select
     rowkey as acct_id,
     max(txid) as last_txid
    from 'coin_coin-table'
    group by acct_id
   ) latest ON coin.rowkey = latest.acct_id AND coin.txid = latest.last_txid
   order by balance desc;" > /home/CHANGEME/kda/richlist-chain-$i.csv
# Get list of deployed modules
   sqlite3 -header -csv /home/CHANGEME/kda/pact-v1-chain-$i.sqlite "select rowkey as name, txid, rowdata as 'code' from 'SYS:Modules'" > /home/CHANGEME/kda/modules-dirty-chain-$i.csv
# Add chain id at the start of each line
   sed -i -e "s/^/$i,/" /home/CHANGEME/kda/modules-dirty-chain-$i.csv
# Remove chain id from header
   tail -c +2 /home/CHANGEME/kda/modules-dirty-chain-$i.csv > /home/CHANGEME/kda/modules-washed-chain-$i.csv
# Add the correct header
   sed '/^,/ s/./chainid&/' /home/CHANGEME/kda/modules-washed-chain-$i.csv > /home/CHANGEME/kda/modules-ready-chain-$i.csv
done

# Combine richlists & modules from all chains
cat /home/CHANGEME/kda/richlist-chain-*.csv >> /home/CHANGEME/kda/richlist.csv
cat /home/CHANGEME/kda/modules-ready-chain-*.csv >> /home/CHANGEME/kda/modules.csv

# Remove old data from mongo
mongo admin --eval 'db.modules.remove({})'
mongo admin --eval 'db.balance.remove({})'

# Add new data to mongo
mongoimport --db admin --collection modules --file /home/CHANGEME/kda/modules.csv --type=csv --headerline
mongoimport --db admin --collection balance --file /home/CHANGEME/kda/richlist.csv --type=csv --headerline

# Clean the directory
rm /home/CHANGEME/kda/richlist.csv /home/CHANGEME/kda/richlist-chain-*.csv /home/CHANGEME/kda/pact-v1-chain-* /home/CHANGEME/kda/modules*
