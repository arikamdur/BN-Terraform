#!/bin/bash
sudo su
apt-get update
apt-get install -y pkg-config dh-autoreconf ncurses-dev build-essential libssl-dev libpcap-dev libncurses5-dev libsctp-dev cmake
cd /root
wget https://github.com/SIPp/sipp/releases/download/v3.6.1/sipp-3.6.1.tar.gz
wget https://csversions.s3.eu-central-1.amazonaws.com/perf.tar
tar -xzvf sipp-3.6.1.tar.gz
tar -xvf perf.tar
cd sipp-3.6.1
./build.sh --full