#!/bin/sh

source /etc/profile



Pub_Peer_Port=5060
Pvt_Peer_Port=5060




# Certain sections work only for IPV4
# Script assumes gateway is 1st ip of subnet
# Copy all files to any folder. CD to that folder and run ./basic_config.sh
#Refrences:
#https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
#To Do
#test for HA system

echo "This script works on bordernet-3.9.1-315"

#VARS
#######
ETH0_MAC=$(cat /sys/class/net/eth0/address)
ETH1_MAC=$(cat /sys/class/net/eth1/address)
ETH2_MAC=$(cat /sys/class/net/eth2/address)

# Internal IP of AWS
ETH0_IP=$(ifconfig eth0 2>/dev/null|awk '/inet / {print $2}')
ETH1_IP=$(ifconfig eth1 2>/dev/null|awk '/inet / {print $2}')
ETH2_IP=$(ifconfig eth2 2>/dev/null|awk '/inet / {print $2}')

# Netmask needed to calculate gateway. (I assume gateway is 1st ip of subnet)
ETH1_NM=$(ifconfig eth1 2>/dev/null|awk '/inet / {print $4}')
ETH2_NM=$(ifconfig eth2 2>/dev/null|awk '/inet / {print $4}')

# Elastic IP of AWS
ETH0_EIP=$(curl --fail --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/$ETH0_MAC/public-ipv4s)
ETH1_EIP=$(curl --fail --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/$ETH1_MAC/public-ipv4s)
ETH2_EIP=$(curl --fail --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/$ETH2_MAC/public-ipv4s)



# Functions
###########

ipvalid() {
  # Set up local variables
  local ip=${1:-NO_IP_PROVIDED}
  local IFS=.; local -a a=($ip)
  # Start with a regex format test
  [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
  # Test values of quads
  local quad
  for quad in {0..3}; do
    [[ "${a[$quad]}" -gt 255 ]] && return 1
  done
  return 0
}

# This function calculates GW from IP and Mask. I assume gateway is 1st ip of subnet. Basically it just adds 1 in last octet of subnet address. echo is required to return GW string from function.
findGW() {
IFS=. read -r i1 i2 i3 i4 <<< "$1"
IFS=. read -r m1 m2 m3 m4 <<< "$2"
local MY_GW=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$(((i4 & m4)+1))")
echo "$MY_GW"
}

#Convert Netmask to CIDR notation. convert IP to a long octal string and sum its bits
IPprefix_by_netmask () {
   c=0 x=0$( printf '%o' ${1//./ } )
   while [ $x -gt 0 ]; do
       let c+=$((x%2)) 'x>>=1'
   done
   echo $c ; }

#GW and subnet mask required for VLAN creation
##############################
ETH1_GW=$(findGW "$ETH1_IP" "$ETH1_NM")
#echo "Gateway on eth1 $ETH1_GW"

ETH2_GW=$(findGW "$ETH2_IP" "$ETH2_NM")
#echo "Gateway on eth2 $ETH2_GW"

ETH1_SMask=$(IPprefix_by_netmask "$ETH1_NM")
#echo "subnet mask on eth1 $ETH1_SMask"

ETH2_SMask=$(IPprefix_by_netmask "$ETH2_NM")
#echo "subnet mask on eth2 $ETH2_SMask"

echo "eth0 IP: $ETH0_IP and Elastic IP: $ETH0_EIP"
echo "eth1 IP: $ETH1_IP Prefix: $ETH1_SMask GW: $ETH1_GW and Elastic IP: $ETH1_EIP. SessionIF 1 will be Public (Interconeect) side."
echo "eth2 IP: $ETH2_IP Prefix: $ETH2_SMask GW: $ETH2_GWand Elastic IP: $ETH2_EIP. SessionIF 2 will be Private (Local) side."


#Ask for peer IP and Port
#########################

while !(ipvalid "$Pub_Peer_IP")
do
  read -p "Enter Pub_Peer IP: " Pub_Peer_IP
done
echo $Pub_Peer_IP

while [[ "$Pub_Peer_Port" -gt 65535 ]] || [[ "$Pub_Peer_Port" -lt 1024 ]]
do
  read -p "Enter Pub_Peer Port: " Pub_Peer_Port
done
echo $Pub_Peer_Port



while !(ipvalid "$Pvt_Peer_IP")
do
  read -p "Enter Pvt_Peer IP: " Pvt_Peer_IP
done
echo $Pvt_Peer_IP

while [[ "$Pvt_Peer_Port" -gt 65535 ]] || [[ "$Pvt_Peer_Port" -lt 1024 ]]
do
  read -p "Enter Pvt_Peer Port: " Pvt_Peer_Port
done
echo $Pvt_Peer_Port


until $(echo >/dev/tcp/localhost/8443); do echo $(date) Waiting For RESTful API Service To Become Available...; sleep 5; done;


#If you set your script up this way(notice two dots), Any variables initialised in parent script should become available to the main script and any scripts it sources.
#. /tmp/mytestScript
echo -e "\n1##########"
. ./1CreateVLAN-Pvt.sh
echo -e "\n2##########"
. ./2CreateVLAN-Pub.sh
echo -e "\n3##########"
. ./3CreateMediaProfile-Local.sh
echo -e "\n4##########"
. ./4CreateMediaProfile-Interconnect.sh
echo -e "\n5##########"
. ./5CreatePATpvt.sh
echo -e "\n6##########"
. ./6CreatePATpub.sh
echo -e "\n7##########"
. ./7CreateParamProfile-Local.sh
echo -e "\n8##########"
. ./8CreateParamProfile-Interconnect.sh
echo -e "\n9##########"
. ./9CreateSecurityProfile-Local.sh
echo -e "\n10##########"
. ./10CreateSecurityProfile-Interconnect.sh
echo -e "\n11##########"
. ./11CreateServiceProfile-Local.sh
echo -e "\n12##########"
. ./12CreateServiceProfile-Interconnect.sh
echo -e "\n13##########"
. ./13CreateInterface-Local.sh
echo -e "\n14##########"
. ./14CreateInterface-Interconnect.sh
echo -e "\n15##########"
. ./15CreatePeer-Local.sh
echo -e "\n16##########"
. ./16CreatePeer-Interconnect.sh
echo -e "\n17##########"
. ./17CreateInterfacespeerassociation-Local.sh
echo -e "\n18##########"
. ./18CreateInterfacespeerassociation-Interconnect.sh
echo -e "\n19##########"
. ./19CreateStaticRouting.sh
echo -e "\nEND##########"

