#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "cfgStatus": "Yes",
      "peer": {
        "idList": [
          {
            "idNum": 21,
            "name": "Peer_Public"
          }
        ]
      },
      "sipIf": {
        "idList": [
          {
            "idNum": 21,
            "name": "Interconnect_Interface"
          }
        ]
      },
      "vlanLogicalIfIdx": 1,
      "kaInterval": 0,
      "note": "",
      "kaSipIf": {
        "idList": [
          {
            "idNum": 21,
            "name": "Interconnect_Interface"
          }
        ]
      },
      "kaTryCount": 1,
      "kaMaxFwds": 70,
      "kaSuccRespCodes": [
        0
      ],
      "incomingOPTIONSHandling": "Local",
      "groupId": 0
    }
  ],
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/sipconfiguration/interfacespeerassociation'
