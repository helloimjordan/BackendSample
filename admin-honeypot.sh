#!/bin/bash
#SYSTEM UPDATE
apt update && apt install wget curl tmux docker-compose -y
mkdir apps && cd apps

export PATH=$PATH:/usr/sbin

useradd -c "user" -m user
echo "user:password" | chpasswd
usermod -aG sudo webuser

#HONEYPOT INSTALL
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

#tshark and termshark
DEBIAN_FRONTEND=noninteractive apt-get -y install tshark
cd /opt
wget https://github.com/gcla/termshark/releases/download/v2.3.0/termshark_2.3.0_linux_x64.tar.gz
tar xvzf termshark*.tar.gz && rm termshark*.tar.gz && mv termshark* termshark

#install osquery
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
apt-get update
apt-get install osquery -y 
cp /opt/osquery/share/osquery/osquery.example.conf /etc/osquery/osquery.conf
sudo systemctl start osqueryd

#splunk
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

#velociraptor
cd /opt/
git clone https://github.com/weslambert/velociraptor-docker.git
cd velociraptor-docker
docker-compose up -d
echo "127.0.0.1  VelociraptorServer" >> /etc/cloud/templates/hosts.debian.tmpl

#wazuh
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

#nessus
docker run --name "nessus" -d -p 8840:8834 --restart unless-stopped -e USERNAME=username -e PASSWORD=password tenableofficial/nessus 

#packetwall
mkdir /opt/graph
cd /opt/graph
cat > capture.sh <<EOL
#!/bin/bash
##FUNCTIONS
#start the capture on the wire
function setup() {
  echo "" > flags.txt 
  echo "" > formattedflags.txt
  mkdir wire
  mkdir capture
  mkdir -p rules/01
  mkdir -p rules/02
  mkdir -p rules/03
  mkdir -p rules/04
  mkdir -p rules/05
  mkdir -p rules/06
  mkdir -p rules/07
  mkdir -p rules/08
  mkdir -p rules/09
  nohup dumpcap -i eth0 -f "ip||ip6" -b duration:10 -b files:2 -w wire/wall.pcapng 2>&1
}

#end gracefully
function shutdown()
{
  killall dumpcap
  rm -rf capture/ && rm -rf rules/ && rm -rf wire/
	rm packetwall.sh && rm nohup.out && rm flags.txt
  exit 0
}
#trap shutdown SIGINT

##CAPTURE RULES
#HTTP Traffic (rule #1)
function rule01() {
  http=$(tshark -r capture/$i -Y 'tcp.port==80 || udp.port==80')
  if [ -z "$http" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

function rule02() {
  http=$(tshark -r capture/$i -Y 'tcp.port==443 || udp.port==443')
  if [ -z "$http" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

function rule03() {
  http=$(tshark -r capture/$i -Y 'tcp.port==3389 || udp.port==3389')
  if [ -z "$http" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

function rule04() {
  http=$(tshark -r capture/$i -Y 'tcp.port==3306 || udp.port==3306')
  if [ -z "$http" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}

function rule05() {
  http=$(tshark -r capture/$i -Y 'tcp.port==25 || udp.port==25')
  if [ -z "$http" ] ;then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt &
  fi
}


function rule06() {
  logfile='../../var/log/syslog'
  fileSize=$(stat -c%s $logfile)
  sleep 3;
  newFileSize=$(stat -c%s $logfile)

  if [ "$fileSize" == "$fileSizeNew" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

function rule07() {
  logfile='../../var/log/kern.log'
  fileSize=$(stat -c%s $logfile)
  sleep 3;
  newFileSize=$(stat -c%s $logfile)

  if [ "$fileSize" == "$fileSizeNew" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

function rule08() {
  logfile='../../var/log/auth.log'
  fileSize=$(stat -c%s $logfile)
  sleep 3;
  newFileSize=$(stat -c%s $logfile)

  if [ "$fileSize" == "$fileSizeNew" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

function rule09() {
  logfile='../../var/log/dpkg.log'
  fileSize=$(stat -c%s $logfile)
  sleep 3;
  newFileSize=$(stat -c%s $logfile)

  if [ "$fileSize" == "$fileSizeNew" ]; then
    sed -i '1i 0' flags.txt
    return
  else
    sed -i '1i 1' flags.txt
  fi
}

function movepcaps() {
  movethispcap=$(ls wire/ | grep pcapng | head -n 1)
  echo "moving this pcap: " $movethispcap
  mv /opt/graph/wire/$movethispcap /opt/graph/capture/
}

#MAIN PROGRAM
#set everything up and wait
setup &
sleep 10
#begin the search
while true; do
  movepcaps
  PACKETS=$(ls capture/ | grep pcapng)
  DAT=$(date +"%j_%H_%M_%S")
  DAT2=$(date +"%j")
  for i in $PACKETS; do
    echo "searching..."
    rule01 && rule02 && rule03 && rule04 && rule05 && rule06 && rule07 && rule08 && rule09
    x=$(awk 'BEGIN { ORS = "" } { print }' flags.txt | rev | cut -c1-9)
    echo $x
    sleep 10
    rm /opt/graph/wire/$movethispcap
    #curl  http://127.0.0.1:8000/DjangoEndpoint  -H 'content-type: application/json'  -d '{"row": "'$flags'", "ip": "'$ip'"}'
    echo "" > flags.txt
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

#FINAL SETUP
echo "Don't forget to remove this script"
echo "and do history -c && history -w before packing up"
reboot
