#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "name": "Interconnect_Sec_Prof",
      "nwType": "Interconnect",
      "imsNetwork": "No",
      "subTraffic": "No",
      "sesnRateIn": 30,
      "sesnRateOut": 30,
      "maxActiveSesns": 3600,
      "maxEmergencySesns": 0,
      "maxActiveSesnsIn": 1800,
      "maxActiveSesnsOut": 1800,
      "burstRate": 0,
      "burstRateInterval": 3,
      "txnRateIn": 100,
      "txnRateOut": 100,
      "txnBurstRate": 3,
      "txnBurstRateInterval": 3,
      "malformedMsgCount": 450,
      "dynBlkListThreshold": 200,
      "dynBlkListPeriod": 60,
      "monitorInterval": 15,
      "dynamicPktRate": "Yes",
      "pktRate": 0,
      "subSesnRateIn": 3,
      "subSesnRateOut": 3,
      "subMaxActiveSesns": 5,
      "subMaxActiveSesnsIn": 5,
      "subMaxActiveSesnsOut": 5,
      "subBurstRate": 0,
      "subBurstRateInterval": 0,
      "subTxnRateIn": 100,
      "subTxnRateOut": 100,
      "subTxnBurstRate": 0,
      "subTxnBurstRateInterval": 3,
      "subMalformedMsgCount": 45,
      "subDynBlkListThreshold": 200,
      "subDynBlkListPeriod": 60,
      "subMonitorInterval": 15,
      "subDynamicPktRate": "Yes",
      "subPktRate": 0,
      "note": ""
    }
  ],
  "maintainId": "false",
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/common/securityprofiles'
