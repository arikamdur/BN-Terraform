#!/bin/bash

body=$(cat  << EOF
{
   "list":[
      {
         "id":0,
         "vlanName":"PvtVlan",
         "cfgStatus":"Yes",
         "deployInProgress":"true",
         "gatewayIpAddress":"$ETH2_GW",
         "gatewayIpAddressSecond":"",
         "subnetMask":"$ETH2_SMask",
         "subnetMaskSecond":"$ETH2_SMask",
         "vlanId":"0",
         "ipAddressType":"IPv4",
         "logicalEthLink":{
            "idList":[
               {
                  "idNum":3,
                  "name":"SessionIf 2"
               }
            ]
         },

         "primaryEthPortLocation":"",
         "primaryIpAddress":"$ETH2_IP",
         "primaryIpAddressId":0,
         "primaryIpAddressSecond":"",
         "primaryPublicIpAddress":"",
         "primaryPublicIpAddressSecond":"",
         "secondaryEthPortLocation":"",
         "secondaryIpAddressList":[
            {
               "secondaryIpAddress":"",
               "secondaryIpAddressId":0,
               "secondaryIpAddressSecond":"",
               "secondaryPublicIpAddress":"",
               "secondaryPublicIpAddressSecond":""
            }
         ],
         "note":""
      }
   ],
   "operationId":0,
   "totalrecords":0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/system/ipconfiguration/vlaninterfaces'
