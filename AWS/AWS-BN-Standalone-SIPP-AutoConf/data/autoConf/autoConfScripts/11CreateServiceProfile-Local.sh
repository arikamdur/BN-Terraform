#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "name": "Local_SerProf",
      "nwType": "Local",
      "imsNetwork": "No",
      "subTraffic": "No",
      "inMsgProfiler": {
        "idList": [
          {
            "idNum": 1,
            "name": "SystemInMsgProfiler"
          }
        ]
      },
      "outMsgProfiler": {
        "idList": [
          {
            "idNum": 2,
            "name": "SystemOutMsgProfiler"
          }
        ]
      },
      "mediaInactivityMonitor": "Enabled",
      "emergencyProfile": {
        "idList": [
          {
            "idNum": 1,
            "name": "Default"
          }
        ]
      },
      "sipMsgRouting": "No",
      "tgrpMapping": "No",
      "transcodingProfile": null,
      "maxRoutingReattempts": 5,
      "redirectMode": "Forward",
      "dstPathList": "",
      "privacy": "Enabled",
      "dscCheckTopTransp": "Enabled",
      "dscCheckDialogTransp": "Enabled",
      "dscCheckIdentityTransp": "Disabled",
      "dscCheckAcctTransp": "Disabled",
      "dscCheckHeaderTransp": "Disabled",
      "dscCheckBodyTransp": "Disabled",
      "dscCheckMediaTransp": "Disabled",
      "dscCheckFuncTransp": "Disabled",
      "staticTopTransp": "Disabled",
      "staticDialogTransp": "Disabled",
      "staticIdentityTransp": "Enabled",
      "staticAcctTransp": "Enabled",
      "staticHeaderTransp": "Enabled",
      "staticBodyTransp": "Enabled",
      "staticMediaTransp": "Disabled",
      "staticFuncTransp": "Enabled",
      "mediaInactMonPeriod": 180,
      "strictOfferAnswerMode": "Yes",
      "note": "",
      "maxAllowReg": 32000,
      "minRegInterval": 1800,
      "maxRegInterval": 3600,
      "forwardRegExp": 50,
      "subscrRegEv": "No",
      "subscrPer": 30,
      "relRegExp": "No",
      "feNatTravMode": "ShortReg",
      "feNatTravInterval": 60,
      "antiTromboning": "No",
      "recvIsupTreatment": "Transparent",
      "sendIsupTreatment": "Transparent",
      "lrbt": "Disabled",
      "lrbtTimer": 60,
      "ringMsgType": "Default-transparent",
      "rel100Type": null,
      "lrbtRuleList": null
    }
  ],
  "maintainId": "false",
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/common/serviceprofiles'
