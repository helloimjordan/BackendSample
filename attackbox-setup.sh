#!/bin/bash
# freshen up and install tools
apt update && apt upgrade -y
apt install -y wget p7zip-full git libffi-dev build-essential python3-pip sshpass

cd /opt
# install atomic-operator
# https://www.atomic-operator.com/.8.3/
git clone https://github.com/swimlane/atomic-operator.git
cd atomic-operator
python3 setup.py install
atomic-operator get_atomics
cd ..
