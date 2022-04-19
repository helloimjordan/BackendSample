#!/bin/bash
# Freshen up
apt update && apt install wget curl tmux docker-compose -y


# By default on DO debian 10 machine, sbin not added to PATH, so we need to add for proper detection tool functionality
export PATH=$PATH:/usr/sbin

# Create user for honeypot setup
useradd -c "user" -m user
echo "user:password" | chpasswd
usermod -aG sudo user

# Honeypot install
# source: https://github.com/telekom-security/tpotce
cd /opt
git clone https://github.com/telekom-security/tpotce
cd tpotce/
cat > /root/tpot.conf <<EOL
# tpot configuration file
# myCONF_TPOT_FLAVOR=[STANDARD, SENSOR, INDUSTRIAL, COLLECTOR, NEXTGEN]
myCONF_TPOT_FLAVOR='STANDARD'
myCONF_WEB_USER='user' 
myCONF_WEB_PW='password'
EOL
./install.sh --conf=/root/tpot.conf

# Tshark and Termshark install
# source: https://github.com/gcla/termshark
# source: https://www.wireshark.org/docs/man-pages/tshark.html
DEBIAN_FRONTEND=noninteractive apt-get -y install tshark
cd /opt
wget https://github.com/gcla/termshark/releases/download/v2.3.0/termshark_2.3.0_linux_x64.tar.gz
tar xvzf termshark*.tar.gz && rm termshark*.tar.gz && mv termshark* termshark

# OSquery install
# source: https://osquery.io/
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
apt-get update
apt-get install osquery -y 
cp /opt/osquery/share/osquery/osquery.example.conf /etc/osquery/osquery.conf
sudo systemctl start osqueryd

# Splunk install
# source: https://www.splunk.com/en_us/download.html
wget -O splunk-8.2.4-87e2dda940d1-linux-2.6-amd64.deb 'https://download.splunk.com/products/splunk/releases/8.2.4/linux/splunk-8.2.4-87e2dda940d1-linux-2.6-amd64.deb'
dpkg -i splunk-8.2.4-87e2dda940d1-linux-2.6-amd64.deb
rm splunk-8.2.4-87e2dda940d1-linux-2.6-amd64.deb
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
cat > /opt/splunk/etc/system/local/web.conf <<EOL
[settings]
httpport = 8010
appServerPorts = 8011
enableSplunkWebSSL = false
splunk_dashboard_app_name = splunk-dashboard-app
dashboard_html_allow_embeddable_content = true
dashboard_html_wrap_embed = false
simplexml_dashboard_create_version = 1.0
pdfgen_trusted_hosts = *.splunk.com, 127.0.0.1/24
EOL
cat > /opt/splunk/etc/system/local/user-seed.conf <<EOL
[user_info]
USERNAME = username
PASSWORD = password
EOL
/opt/splunk/bin/splunk restart

# Velociraptor install
# source: https://docs.velociraptor.app/
cd /opt/
git clone https://github.com/weslambert/velociraptor-docker.git
cd velociraptor-docker
docker-compose up -d
echo "127.0.0.1  VelociraptorServer" >> /etc/cloud/templates/hosts.debian.tmpl

# Wazuh install 
# souce: https://wazuh.com/
cd /opt/
echo "127.0.0.1 wazuh" >> /etc/cloud/templates/hosts.debian.tmpl
git clone -b stable https://github.com/wazuh/wazuh-docker.git
cd wazuh-docker
sed -i "2s/.*/version: '3.3'/" docker-compose.yml
sed -i '37s/.*/      - "9201:9200"/' docker-compose.yml
sed -i '57s/.*/      - 5601:5601/' docker-compose.yml
docker-compose up -d
curl -so wazuh-agent-4.2.6.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.2.6-1_amd64.deb && sudo WAZUH_MANAGER='wazuh' WAZUH_AGENT_GROUP='default' dpkg -i ./wazuh-agent-4.2.6.deb
systemctl daemon-reload && systemctl enable wazuh-agent && systemctl start wazuh-agent

# Nessus install
# source: https://www.tenable.com/products/nessus
docker run --name "nessus" -d -p 8840:8834 --restart unless-stopped -e USERNAME=username -e PASSWORD=password tenableofficial/nessus 

# Packetwall
# This script starts dumpcap and listens on interface eth1 (internal traffic). It then searches the pcap files, and per each 
# HTTP or log rule, outputs a 0 or 1, which is then curled to Django backend for waterfall graph on front end of web app component
mkdir /opt/graph
cd /opt/graph
cat > capture.sh <<EOL
#!/bin/bash

# Start the capture on the wire
function setup() {
  echo "" > flags.txt
  mkdir wire
  mkdir capture
  # change to eth1 during prod
  nohup dumpcap -i eth1 -f "ip||ip6" -b duration:10 -b files:2 -w wire/wall.pcapng 2>&1
}

# End gracefully
function shutdown()
{
  killall dumpcap
  rm -rf capture/ && rm -rf rules/ && rm -rf wire/
        rm nohup.out
  exit 0
}
trap shutdown SIGINT

# CAPTURE RULES
# Port 80
function rule01() {
  rule1=$(tshark -r capture/$i -Y 'tcp.port==80 || udp.port==80')
  if [ -z "$rule1" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

# Port 443
function rule02() {
  rule2=$(tshark -r capture/$i -Y 'tcp.port==443 || udp.port==443')
  if [ -z "$rule2" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

# Port 3389
function rule03() {
  rule3=$(tshark -r capture/$i -Y 'tcp.port==3389 || udp.port==3389')
  if [ -z "$rule3" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

# Port 3306
function rule04() {
  rule4=$(tshark -r capture/$i -Y 'tcp.port==3306 || udp.port==3306')
  if [ -z "$rule4" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

# Port 25
function rule05() {
  rule5=$(tshark -r capture/$i -Y 'tcp.port==25 || udp.port==25')
  if [ -z "$rule5" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

# syslog 
function rule06() {
  syslog='../../var/log/syslog'
  fileSize1=$(stat -c%s $syslog)
  sleep 3;
  newFileSize1=$(stat -c%s $syslog)
  if [ "$fileSize1" == "$fileSizeNew1" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

# kern.log 
function rule07() {
  kern='../../var/log/kern.log'
  fileSize2=$(stat -c%s $kern)
  sleep 3;
  newFileSize2=$(stat -c%s $kern)
  if [ "$fileSize2" == "$fileSizeNew2" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

# auth.log
function rule08() {
  auth='../../var/log/auth.log'
  fileSize3=$(stat -c%s $auth)
  sleep 3;
  newFileSize3=$(stat -c%s $auth)
  if [ "$fileSize3" == "$fileSizeNew3" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

# dpkg.log
function rule09() {
  dpkg='../../var/log/dpkg.log'
  fileSize4=$(stat -c%s $dpkg)
  sleep 3;
  newFileSize4=$(stat -c%s $dpkg)
  if [ "$fileSize4" == "$fileSizeNew4" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

# copy from wire and move to a place we can properly search
function movepcaps() {
  movethispcap=$(ls wire/ | grep pcapng | head -n 1)
  echo "moving this pcap: " $movethispcap
  mv /opt/graph/wire/$movethispcap /opt/graph/capture/
}

#MAIN
# Set everything up and wait
setup &
# Grab IP to curl to Django with round of results
ip=$(hostname -I | awk '{print $1}')
ip=\"$ip\"
sleep 10

# Begin the search
while true; do
  movepcaps
  PACKETS=$(ls capture/ | grep pcapng)
  DAT=$(date +"%j_%H_%M_%S")
  for i in $PACKETS; do
    echo "searching..."
    rule09 && rule08 && rule07 && rule06 && rule05 && rule04 && rule03 && rule02 && rule01
    # flags variable needs to be in this format to curl - flags="010101010"
    sleep 1
    flags=$(awk 'BEGIN { ORS = "" } { print }' flags.txt | cut -c1-9) # we only send one round of results at a time
    flags=\"$flags\"
    echo $flags
    sleep 10
    rm /opt/graph/wire/$movethispcap
    # change IP and endpoint to Django backend 
    # curl  http://127.0.0.1:8000/specialEndpoint  -H 'content-type: application/json'  -d '{"row": "'$flags'", "ip": "'$ip'"}'
    echo "" > flags.txt # Clear flags.txt for next round of output
  done
done
EOL

crontab -l > mycron
echo "@reboot /opt/splunk/bin/splunk start" >> mycron
echo "@reboot /opt/packetwall/capture.sh" >> mycron
echo "@reboot /opt/velociraptor-docker/velociraptor/velociraptor --config /opt/velociraptor-docker/velociraptor/client.config.yaml client" >> mycron
crontab mycron
rm mycron
chmod +x capture.sh
nohup /opt/graph/capture.sh &

# Final setup
echo "Don't forget to remove this script"
echo "and do history -c && history -w before packing up"
reboot
