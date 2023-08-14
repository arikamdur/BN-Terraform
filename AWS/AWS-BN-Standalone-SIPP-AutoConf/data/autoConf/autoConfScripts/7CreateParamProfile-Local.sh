#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "name": "Local_Para_Profile",
      "nwType": "Local",
      "imsNetwork": "No",
      "subTraffic": "No",
      "t1Timer": 500,
      "t2Timer": 4000,
      "timerC": 240,
      "maxRetrans": 4,
      "supportedMethods": "INVITE CANCEL ACK BYE OPTIONS INFO NOTIFY PRACK REFER UPDATE",
      "referHandle": "Forward",
      "replaceHandle": "Forward",
      "historyInfoHandle": "No",
      "diversionHistoryHandle": "None",
      "minSE": 90,
	  "maxSE": 7200,
	  "sessionTimer": 1800,
      "reqRelRspinINV": "No",
      "initiateRelRsp": "No",
      "tgrpFormat": "Rfc4904",
      "insertTgrpInfo": "No",
	  "minMFValue": 1,
      "deployInProgress": "true",
      "forceFastStart": "No",
      "note": ""
    }
  ],
  "maintainId": "false",
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/sipconfiguration/paramprofiles'
