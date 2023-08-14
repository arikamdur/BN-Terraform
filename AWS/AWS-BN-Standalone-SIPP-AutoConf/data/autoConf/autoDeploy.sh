#!/bin/sh


#What this script does
#deploys BN
#creates a script which is run after BN reboot to apply license and configure BN
#
#
source /etc/profile


#Create a log file
##################
dir=/tmp/autoConf
logfilename=/tmp/autoConf/autoConfLog.txt
mkdir -p /tmp/autoConf
test -f /tmp/autoConf/autoConfLog.txt || touch /tmp/autoConf/autoConfLog.txt



# Functions
###########
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


#VARS
#######
ETH0_IP=$(ifconfig eth0 2>/dev/null|awk '/inet / {print $2}')
# Netmask needed to calculate gateway. (I assume gateway is 1st ip of subnet)
ETH0_NM=$(ifconfig eth0 2>/dev/null|awk '/inet / {print $4}')

#GW and subnet mask required for deployment
##############################
ETH0_GW=$(findGW "$ETH0_IP" "$ETH0_NM")
#echo "Gateway on eth0 $ETH0_GW"


ETH0_SMask=$(IPprefix_by_netmask "$ETH0_NM")
#echo "subnet mask on eth0 $ETH0_SMask"

#############

touch /var/adm/bnet/.deploymentdata

echo "deploymentType=Standalone" >> /var/adm/bnet/.deploymentdata
echo "designatedRole=Primary" >> /var/adm/bnet/.deploymentdata
echo "saHostname=`hostname`" >> /var/adm/bnet/.deploymentdata
echo "saUtilityIp=$ETH0_IP" >> /var/adm/bnet/.deploymentdata
echo "saMgmtIp=$ETH0_IP" >> /var/adm/bnet/.deploymentdata
echo "saNetmask=$ETH0_SMask" >> /var/adm/bnet/.deploymentdata
echo "saGatewayIp=$ETH0_GW" >> /var/adm/bnet/.deploymentdata
echo "saPrimaryHALinkIp=$ETH0_IP" >> /var/adm/bnet/.deploymentdata
echo "saHaLinkNetmask=$ETH0_SMask" >> /var/adm/bnet/.deploymentdata
echo "saTranscNetwork=192.9.200.0" >> /var/adm/bnet/.deploymentdata
echo "reDeploy=no" >> /var/adm/bnet/.deploymentdata

echo "$(date) created file /var/adm/bnet/.deploymentdata" >> /tmp/autoConf/autoConfLog.txt
cat /var/adm/bnet/.deploymentdata >> /tmp/autoConf/autoConfLog.txt



#########################
#Create autoConf.sh

cat << 'EOF' > /tmp/autoConf/autoConf.sh
#!/bin/sh

source /etc/profile
echo "$(date) Creating autoConf.sh file" >> /tmp/autoConf/autoConfLog.txt

#Wait for bnetpps to run
bnetppsSTATUS="$(systemctl is-active bnetpps.service)"
while [[ "${bnetppsSTATUS}" != "active" ]]
do
  sleep 5
  bnetppsSTATUS="$(systemctl is-active bnetpps.service)"
  echo "${bnetppsSTATUS}" >> /tmp/autoConf/autoConfLog.txt
done
echo "${bnetppsSTATUS}" >> /tmp/autoConf/autoConfLog.txt


echo "$(date) ###Installing License###" >> /tmp/autoConf/autoConfLog.txt
systemctl stop bnetpps 
cp /tmp/autoConf/License/DialogicLab_TRL_VM*.txt /config/mibs/current/localmgmt/license/License_trial.xml
cd /config/mibs/current/localmgmt/license/
/opt/bnet/bin/ParseProvisioning *.xml
git add .
git commit -m 'applying new license'
systemctl start bnetpps

#RestAPI 
echo "$(date) ###ConfiguringBN###" >> /tmp/autoConf/autoConfLog.txt
cd /tmp/autoConf/autoConfScripts
chmod +x *.sh
./basic_config.sh >> /tmp/autoConf/autoConfLog.txt

#remove crone job @reboot
croncmd="/tmp/autoConf/autoConf.sh >> /tmp/autoConf/autoConfLog.txt"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ) | crontab -

echo "$(date) script finished" >> /tmp/autoConf/autoConfLog.txt
EOF

#Make file executable
chmod +x /tmp/autoConf/autoConf.sh

#Create a one time crone on reboot
croncmd="/tmp/autoConf/autoConf.sh >> /tmp/autoConf/autoConfLog.txt"
cronjob="@reboot $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

