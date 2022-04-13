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
    # curl results to django
    # then clear flags file so we arent sending repeat data
    # truncate -s 0 flags.txt
  done
done