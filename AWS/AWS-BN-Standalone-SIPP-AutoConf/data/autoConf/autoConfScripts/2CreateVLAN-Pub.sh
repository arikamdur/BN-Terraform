#!/bin/bash

body=$(cat  << EOF
{
   "list":[
      {
         "id":0,
         "vlanName":"PubVlan",
         "cfgStatus":"Yes",
         "deployInProgress":"true",
         "gatewayIpAddress":"$ETH1_GW",
         "gatewayIpAddressSecond":"",
         "subnetMask":"$ETH1_SMask",
         "subnetMaskSecond":"$ETH1_SMask",
         "vlanId":"0",
         "ipAddressType":"IPv4",
         "logicalEthLink":{
            "idList":[
               {
                  "idNum":2,
                  "name":"SessionIf 1"
               }
            ]
         },

         "primaryEthPortLocation":"",
         "primaryIpAddress":"$ETH1_IP",
         "primaryIpAddressId":0,
         "primaryIpAddressSecond":"",
         "primaryPublicIpAddress":"$ETH1_EIP",
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
