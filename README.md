# Prerequisites
BETA & UNSECURE  
1- You need to change defaults passwords yourself after installation   
2- Does NOT work on AWS  
3- FRESH server with Ubuntu 20  
4- M.2 drive recommended  
5- Domain name pointed at the server  

# Installation  
DO NOT run as root
Make sure the user has sudo permissions

### Install Nix  
`printf 'n\ny\ny\n' | sh <(curl -L https://nixos.org/nix/install) --daemon`  
`exec bash --login`  

### Install the dashboard  
Answer the 2 questions  
If there is any errors during the install there is a log at /tmp/install.log  
`wget https://raw.githubusercontent.com/Thanos420NoScope/kadena-dashboard/master/install.sh && chmod +x install.sh && ./install.sh`  

# Initial data fill  
Backfill the database to get previous data  
This takes about 24hours  

`cd ~/kda`  
`./chainweb-data backfill --service-host=127.0.0.1 --service-port=1848 --p2p-host=127.0.0.1 --p2p-port=8443  --dbuser=datauser --dbpass=datapass --dbname=data && ./chainweb-data gaps --service-host=127.0.0.1 --service-port=1848 --p2p-host=127.0.0.1 --p2p-port=8443  --dbuser=datauser --dbpass=datapass --dbname=data && ./faststats.sh && ./richnmod.sh && ./getips.sh`  

# Conect to Metabase  
Go to your domain in a browser  
Default settings are  

some@email.com  
mysecretpassword1  

In admin section change SITE URL

# Change passwords  
Metabase  
Postgres  

# Enable crontabs  
Remove # in crontabs to enable them  
If your server cant keep up, make the crons happen less olften  
`crontab -e`  

# View existing dashboards  

Kadena Statistics	https://YOURURL/public/dashboard/f0513f15-8d0d-4e50-950f-35f6a72c0fe2  
Exchanges Wallet	https://YOURURL/public/dashboard/744d2814-8b18-4dcb-8b07-ace39d49d5b0  
Pool Blocks	    https://YOURURL/public/dashboard/13fd07aa-08ef-4440-ac35-025b8584ba58  

# Update

```bash
cd /root/kda
systemctl stop kadena-node
rm chainweb-node
wget https://github.com/kadena-io/chainweb-node/releases/download/2.12/chainweb-2.12.ghc-8.10.7.ubuntu-20.04.0aba2d1.tar.gz
tar -xvf chainweb-2.12.ghc-8.10.7.ubuntu-20.04.0aba2d1.tar.gz
systemctl start kadena-node
```
