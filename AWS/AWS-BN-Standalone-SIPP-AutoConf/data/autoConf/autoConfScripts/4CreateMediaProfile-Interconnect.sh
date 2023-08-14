#!/bin/bash

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "name": "Interconnect_Media_Profile",
      "nwType": "Interconnect",
      "bandwidthLimitation": 0,
      "bwlCauseCode": 503,
      "deployInProgress": "true",
      "dtmfViaSipInfo": "No",
      "imsNetwork": "No",
      "inactivityDisconnection": "Dual",
      "interceptMedia": "Yes",
      "mediaInactivityTimer": 0,
      "mediaLatching": "None",
      "mediaTos": 255,
      "note": "my note",
      "omrHandling": "None",
      "preCondition": "Disable",
      "subTraffic": "No",
      "imageCodecPrefList": {
        "idList": [
          {
            "idNum": 95,
            "name": "AnyImage"
          }
        ]
      },
     "audioCodecPrefList": {
        "idList": [
          {
            "idNum": 29,
            "name": "G729"
          },
          {
            "idNum": 1,
            "name": "PCMU"
          },
          {
            "idNum": 18,
            "name": "PCMA"
          },
          {
            "idNum": 93,
            "name": "AnyAudio"
          }
        ]
      },
      "textCodecPrefList": {
        "idList": [
          {
            "idNum": 227,
            "name": "AnyText"
          }
        ]
      },
      "videoCodecPrefList": {
        "idList": [
          {
            "idNum": 94,
            "name": "AnyVideo"
          }
        ]
      }
    }
  ],
  "maintainId": "false",
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/sipconfiguration/mediaprofiles'
