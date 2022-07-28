#!/bin/bash
sudo su
apt-get install -y pkg-config dh-autoreconf ncurses-dev build-essential libssl-dev libpcap-dev libncurses5-dev libsctp-dev cmake
cd /root
wget https://github.com/SIPp/sipp/releases/download/v3.6.1/sipp-3.6.1.tar.gz
tar -xzvf sipp-3.6.1.tar.gz
cd sipp-3.6.1
./build.sh --common