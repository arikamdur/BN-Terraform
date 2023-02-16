#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "cfgStatus": "Yes",
      "incomingPeer": 11,
      "inIfType": "SIP",
      "incomingInterface": 11,
      "outIfType": "SIP",
      "outgoingInterface": 21,
      "outgoingPeer": 21,
      "incomingPeer_name": "Peer_Local",
      "incomingIntf_name": "Local_Interface",
      "outgoingIntf_name": "Interconnect_Interface",
      "outgoingPeer_name": "Peer_Public",
      "note": "",
      "outgoingGroupId": 0,
      "outgoingGroup_name": ""
    },
        {
      "id": 0,
      "cfgStatus": "Yes",
      "incomingPeer": 21,
      "inIfType": "SIP",
      "incomingInterface": 21,
      "outIfType": "SIP",
      "outgoingInterface": 11,
      "outgoingPeer": 11,
      "incomingPeer_name": "Peer_Public",
      "incomingIntf_name": "Interconnect_Interface",
      "outgoingIntf_name": "Local_Interface",
      "outgoingPeer_name": "Peer_Local",
      "note": "",
      "outgoingGroupId": 0,
      "outgoingGroup_name": ""
    }
  ],
  "maintainId": "false",
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/common/staticrouting'
