#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "name": "Pub-20k-30k",
      "application": "Media",
      "ipAddressType": "IPv4",
      "vlanLogicalIf": {
        "idList": [
          {
            "name": "PubVlan"
          }
        ]
      },
      "ipIfIndex": {
        "idList": [
          {
            "name": "$ETH1_IP"
          }
        ]
      },
      "startPort": 20001,
      "endPort": 30000,
      "transportProtocol": "UDP",
      "note": ""
    }
  ],
  "maintainId": "false",
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/system/ipconfiguration/portallocation'
