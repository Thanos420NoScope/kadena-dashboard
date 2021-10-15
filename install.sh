#!/bin/bash

##################
# Script by Thanos 
##################

log_file=/tmp/install.log

decho () {
  echo `date +"%H:%M:%S"` $1
  echo `date +"%H:%M:%S"` $1 >> $log_file
}

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  exit "${code}"
}
trap 'error ${LINENO}' ERR

clear

cat <<'FIG'

__/\\\________/\\\__/\\\\\\\\\\\\________/\\\\\\\\\_____________________________
__\/\\\_____/\\\//__\/\\\////////\\\____/\\\\\\\\\\\\\__________________________
___\/\\\__/\\\//_____\/\\\______\//\\\__/\\\/////////\\\________________________
____\/\\\\\\//\\\_____\/\\\_______\/\\\_\/\\\_______\/\\\_______________________
_____\/\\\//_\//\\\____\/\\\_______\/\\\_\/\\\\\\\\\\\\\\\______________________
______\/\\\____\//\\\___\/\\\_______\/\\\_\/\\\/////////\\\_____________________
_______\/\\\_____\//\\\__\/\\\_______/\\\__\/\\\_______\/\\\____________________
________\/\\\______\//\\\_\/\\\\\\\\\\\\/___\/\\\_______\/\\\___________________
_________\///________\///__\////////////_____\///________\///___________________

FIG

# Check if executed as root user
if [ "$(id -u)" = "0" ]; then
   echo "This script cannot be run as root" 1>&2
   exit 3
fi

# Check if user has sudo access
if groups | grep "\<sudo\>" &> /dev/null; then
   echo "User has sudo access" 1>&2
else
   exit 3
fi

# Get current username
user="$USER" 1>&2

decho "Make sure you double check information before hitting enter!"

# --- USER INPUTS --- #
read -e -p "Please enter your node's Domain Name: " whereami
if [[ $whereami == "" ]]; then
    decho "WARNING: No domain given, exiting!"
    exit 3
fi

read -e -p "Please enter your Email Address: " email
if [[ $email == "" ]]; then
    decho "WARNING: No email address given, exiting!"
    exit 3
fi

# --- SYSTEM SETUP --- #

# Check for systemd.
systemctl --version >/dev/null 2>&1 || { decho "systemd is required. Are you using Ubuntu 20.04?" >&2; exit 1; }

# Update packages.
decho "Updating system..."

sudo apt-get update -y >> $log_file 2>&1

# Install required packages
decho "Installing base packages and dependencies..."
decho "This may take a while..."

sudo apt-get install -y certbot librocksdb-dev curl default-jre screen gnupg unzip sqlite3 >> $log_file 2>&1
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add - >> $log_file 2>&1
sudo apt-get install -y mongodb >> $log_file 2>&1
sudo apt-get install -y jq >> $log_file 2>&1
sudo apt install postgresql postgresql-contrib -y  >> $log_file 2>&1
sudo systemctl enable postgresql  >> $log_file 2>&1
sudo systemctl start postgresql  >> $log_file 2>&1
sudo -u postgres psql -c "CREATE USER datauser WITH PASSWORD 'datapass';"  >> $log_file 2>&1
sudo -u postgres psql -c "CREATE DATABASE data;"  >> $log_file 2>&1


# --- NODE BINARY SETUP --- #

node=https://github.com/kadena-io/chainweb-node/releases/download/2.10/chainweb-2.10.ghc-8.10.7.ubuntu-20.04.cd8cbe0.tar.gz
miner=https://github.com/kadena-io/chainweb-miner/releases/download/v1.0.3/chainweb-miner-1.0.3-ubuntu-18.04.tar.gz

decho "Downloading Node..."
mkdir -p /home/$user/kda
cd /home/$user/kda/
wget --no-check-certificate $node >> $log_file 2>&1
tar -xvf chainweb-2.10.ghc-8.10.7.ubuntu-20.04.cd8cbe0.tar.gz >> $log_file 2>&1
wget --no-check-certificate $miner >> $log_file 2>&1
tar -xvf chainweb-miner-1.0.3-ubuntu-18.04.tar.gz >> $log_file 2>&1

# Create config.yaml
decho "Creating config files..."

touch /home/$user/kda/config.yaml
cat << EOF > /home/$user/kda/config.yaml
chainweb:
  # The defining value of the network. To change this means being on a
  # completely independent Chainweb.
  chainwebVersion: mainnet01

  # The number of requests allowed per second per client to certain endpoints.
  # If these limits are crossed, you will receive a 429 HTTP error.
  throttling:
    local: 0.1
    mining: 5
    global: 1000
    putPeer: 11

  mining:
    # Settings for how a Node can provide work for remote miners.
    coordination:
      enabled: false
      # "public" or "private".
      mode: private
      # The number of "/mining/work" calls that can be made in total over a 5
      # minute period.
      limit: 1200
      # When "mode: private", this is a list of miner account names who are
      # allowed to have work generated for them.
      miners:
      - account: 017749fc26f8bf8b5a67204ad9d38b75999da983096f16d18a77af86cba41f4a
        predicate: keys-all
        public-keys:
        - 017749fc26f8bf8b5a67204ad9d38b75999da983096f16d18a77af86cba41f4a

  p2p:
    # Your node's network identity.
    peer:
      # Filepath to the "fullchain.pem" of the certificate of your domain.
      # If "null", this will be auto-generated.
      certificateChainFile: /etc/letsencrypt/live/$whereami/fullchain.pem
      # Filepath to the "privkey.pem" of the certificate of your domain.
      # If "null", this will be auto-generated.
      keyFile: /etc/letsencrypt/live/$whereami/privkey.pem

      # You.
      hostaddress:
        # This should be your public IP or domain name.
        hostname: $whereami
        # The port you'd like to run the Node on. 443 is a safe default.
        port: 8443

    # Initial peers to connect to in order to join the network for the first time.
    # These will share more peers and block data to your Node.
    peers:
      - address:
          hostname: us-w1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-w2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-w3.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-e1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-e2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: us-e3.chainweb.com
          port: 443
        id: null
      - address:
          hostname: fr1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: fr2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: fr3.chainweb.com
          port: 443
        id: null
      - address:
          hostname: jp1.chainweb.com
          port: 443
        id: null
      - address:
          hostname: jp2.chainweb.com
          port: 443
        id: null
      - address:
          hostname: jp3.chainweb.com
          port: 443
        id: null

logging:
  # All structural (JSON, etc.) logs.
  telemetryBackend:
    enabled: true
    configuration:
      handle: stdout
      color: auto
      # "text" or "json"
      format: text

  # Simple text logs.
  backend:
    handle: stdout
    color: auto
    # "text" or "json"
    format: text

  logger:
    log_level: warn

  filter:
    rules:
      - key: component
        value: cut-monitor
        level: info
      - key: component
        value: pact-tx-replay
        level: info
      - key: component
        value: connection-manager
        level: info
      - key: component
        value: miner
        level: info
      - key: component
        value: local-handler
        level: info
    default: error
EOF

# --- SYSTEMD SETUP FOR NODE --- #
touch /home/$user/kadena-node.service
cat <<EOF > /home/$user/kadena-node.service
[Unit]
Description=Kadena Node

[Service]
User=$user
KillMode=process
KillSignal=SIGINT
WorkingDirectory=/home/$user/kda
ExecStart=/home/$user/kda/chainweb-node --config-file=/home/$user/kda/config.yaml --p2p-hostname=$whereami --p2p-port=8443 --service-port=1848 --service-interface "*" --rosetta --log-level=warn --header-stream --allowReadsInLocal
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sudo mv /home/$user/kadena-node.service /etc/systemd/system/kadena-node.service


# --- DOMAIN-SPECIFIC CERTIFICATE CREATION --- #
sudo certbot certonly --non-interactive --agree-tos -m $email --standalone --cert-name $whereami -d $whereami >> $log_file 2>&1
sudo chown -R $user /etc/letsencrypt/

# --- ENABLE THE NODE --- #
sudo systemctl daemon-reload
sudo systemctl enable kadena-node

# --- DOWNLOAD A DATABASE SNAPSHOT --- #
decho "Downloading recent database snapshot..."
decho "This may take a while..."
sudo systemctl stop kadena-node
mkdir -p /home/$user/.local/share/chainweb-node/
cd /home/$user/.local/share/chainweb-node/
rm -rf mainnet01
wget https://anedak.com/kadenasync.zip
decho "Unzipping"
unzip kadenasync.zip >> $log_file 2>&1
rm kadenasync.zip
sudo systemctl start kadena-node

# --- Chainweb-data SETUP --- #
decho "Building Chainweb-data, this will take a while"
cd /home/$user/
git clone https://github.com/kadena-io/chainweb-data  >> $log_file 2>&1
cd chainweb-data
sudo touch /etc/nix/nix.conf
sudo su -c "echo 'sandbox = false' >> /etc/nix/nix.conf"
sudo su -c "echo 'substituters = https://nixcache.chainweb.com https://nixcache.reflex-frp.org https://cache.nixos.org/' >> /etc/nix/nix.conf"
sudo su -c "echo 'trusted-public-keys = nixcache.chainweb.com:FVN503ABX9F8x8K0ptnc99XEz5SaA4Sks6kNcZn2pBY= ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' >> /etc/nix/nix.conf"
sudo chmod a+rwx /etc/nix/
sudo systemctl restart nix-daemon
nix-build  >> $log_file 2>&1
cp result/bin/chainweb-data /home/$user/kda/
touch /home/$user/kda/chainweb-data.service
cat <<EOF > /home/$user/kda/chainweb-data.service
[Unit]
Description=chainweb-data

[Service]
User=$user
KillMode=process
KillSignal=SIGINT
WorkingDirectory=/home/$user/kda
ExecStart=/home/$user/kda/chainweb-data listen --service-host=127.0.0.1 --service-port=1848 --p2p-host=127.0.0.1 --p2p-port=8443  --dbuser=datauser --dbpass=datapass --dbname=data
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
sudo mv /home/$user/kda/chainweb-data.service /etc/systemd/system/chainweb-data.service
sudo systemctl enable chainweb-data >> $log_file 2>&1
sudo systemctl start chainweb-data >> $log_file 2>&1

# --- Metabase SETUP --- #
sudo apt install -y nginx >> $log_file 2>&1
sudo rm -rf /etc/nginx/sites-available/default
sudo rm -rf /etc/nginx/sites-enabled/default
decho "Setting up Metabase"
sudo mkdir -p /etc/nginx/sites-available/
cd /etc/nginx/sites-available/
sudo wget https://raw.githubusercontent.com/Thanos420NoScope/kadena-dashboard/master/metabase.conf
sudo sed -i "s/CHANGEME/$whereami/g" metabase.conf
sudo ln -s /etc/nginx/sites-available/metabase.conf /etc/nginx/sites-enabled/metabase.conf
sudo service nginx restart
cd /home/$user/kda
wget http://anedak.com/metabase.db.mv.db
wget https://downloads.metabase.com/v0.38.1/metabase.jar >> $log_file 2>&1
touch /home/$user/kda/metabase.service
cat <<EOF > /home/$user/kda/metabase.service
[Unit]

Description=Metabase

[Service]
User=$user
KillMode=process
KillSignal=SIGINT
WorkingDirectory=/home/$user/kda
ExecStart=java -jar /home/$user/kda/metabase.jar
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv /home/$user/kda/metabase.service /etc/systemd/system/metabase.service
sudo systemctl enable metabase >> $log_file 2>&1
sudo systemctl start metabase >> $log_file 2>&1

# --- Scripts SETUP --- #
decho "Setting up Scripts"
wget https://raw.githubusercontent.com/Thanos420NoScope/kadena-dashboard/master/faststats.sh
wget https://raw.githubusercontent.com/Thanos420NoScope/kadena-dashboard/master/richnmod.sh
wget https://raw.githubusercontent.com/Thanos420NoScope/kadena-dashboard/master/getips.sh
sed -i "s/CHANGEME/$user/g" richnmod.sh
sed -i "s/CHANGEME/$user/g" getips.sh
touch /home/$user/kda/gaps.sh
mkdir /home/$user/kda/nodes
cat <<EOF > /home/$user/kda/gaps.sh
/home/$user/kda/chainweb-data gaps --service-host=127.0.0.1 --service-port=1848 --p2p-host=127.0.0.1 --p2p-port=8443  --dbuser=datauser --dbpass=datapass --dbname=data
EOF

chmod +x /home/$user/kda/richnmod.sh
chmod +x /home/$user/kda/faststats.sh
chmod +x /home/$user/kda/gaps.sh
chmod +x /home/$user/kda/getips.sh
mongo admin --eval 'db.createCollection("balance")' >> $log_file 2>&1
mongo admin --eval 'db.createCollection("modules")' >> $log_file 2>&1
mongo admin --eval 'db.createCollection("ips")' >> $log_file 2>&1

sudo -u postgres psql data -c "CREATE TABLE blockbyminer()"
sudo -u postgres psql data -c "CREATE TABLE hashrate()"
sudo -u postgres psql data -c "CREATE TABLE latestblocks()"
sudo -u postgres psql data -c "CREATE TABLE blockutilization()"
sudo -u postgres psql data -c "CREATE TABLE txbysender()"
sudo -u postgres psql data -c "CREATE TABLE txperday()"
sudo -u postgres psql data -c "CREATE TABLE txbyhour()"
sudo -u postgres psql data -c "CREATE TABLE txbyday()"
sudo -u postgres psql data -c "CREATE TABLE latesttxs()"
sudo -u postgres psql data -c "CREATE TABLE kdaspent()"
sudo -u postgres psql data -c "CREATE TABLE kdapertx()"
sudo -u postgres psql data -c "CREATE TABLE gasused()"
sudo -u postgres psql data -c "ALTER USER datauser WITH SUPERUSER;"

# --- CRONTABS SETUP --- #
cat <(crontab -l) <(echo "#*/15 * * * * /home/$user/kda/faststats.sh") | crontab -
cat <(crontab -l) <(echo "#0 * * * * /home/$user/kda/richnmod.sh") | crontab -
cat <(crontab -l) <(echo "#0 8 * * * /home/$user/kda/gaps.sh") | crontab -
cat <(crontab -l) <(echo "#5 8 * * 6 /home/$user/kda/getips.sh") | crontab -

# Installation Completed
clear
echo 'Installation completed!'
echo 'Type "journalctl -fu metabase" to see the metabase log.'
echo 'Type "journalctl -fu chainweb-data" to see the data log.'
echo 'Type "journalctl -fu kadena-node" to see the node log.'
