#!/bin/bash

body=$(cat  << EOF
{
  "totalrecords": 0,
  "list": [
    {
      "id": 0,
      "cfgStatus": "Yes",	        
	  "name": "Peer_Public",
      "classId": "test",
      "nwType": "Interconnect",
	  "paccessNetworkInfoValue": "notconfigured",
      "paccessNetworkInfoOption": "No",
      "pvisitedNetworkIDValue": "notconfigured",
      "pcalledPartyIDOption": "No",
      "pvisitedNetworkIDOption": "No",
      "diameterType": "None",
      "ccfh": "Continue",
      "imsNetwork": "No",
      "omrNetwork": "No",
      "surrogatePeer": "No",
      "trunkAuthentication": "No",
      "requireRegistration": "Yes",
      "subTraffic": "No",
      "operId": "",
      "omrIpRealm": "",
      "surrogatePeerAor": "",
      "surrogateAuthUserName": "",
      "surrogateAuthPassword": "",
      "surrogateNumberList": "",
      "surrogateRegType": "No",
      "trunkAuthenticationAor": "",
      "trunkAuthenticationUserName": "",
      "trunkAuthenticationPassword": "",
      "sourceType": "Single",
      "sourceAddressList": [
        {
          "ipAddressType": "IPv4",
          "ipAddress": "$Pub_Peer_IP",
          "subnetMask": 32,
          "port": $Pub_Peer_Port
        }
      ],
      "trustLevel": "High",
      "hostAddressType": "IPv4",
      "host": "$Pub_Peer_IP",
      "port": $Pub_Peer_Port,
      "protocol": [
        "UDP"
      ],
      "maxUdpMtu": 0,
      "paramProfId": {
        "idList": [
          {
            "idNum": 3,
            "name": "Interconnect_Para_Profile"
          }
        ]
      },
      "mediaProfId": {
        "idList": [
          {
            "idNum": 3,
            "name": "Interconnect_Media_Profile"
          }
        ]
      },
      "serviceProfile": {
        "idList": [
          {
            "idNum": 3,
            "name": "Interconnect_SerProf"
          }
        ]
      },
      "securityProfile": {
        "idList": [
          {
            "idNum": 3,
            "name": "Interconnect_Sec_Prof"
          }
        ]
      },
      "note": "",
      "timeZone": "",
      "tgrpId": "",
      "enforceIpSec": "No",
      "routingPolicy": null,
      "reRoutingPolicy": null,
      "mapScfCorrId": "No",
      "prefixLen": 0,
      "scfId": 5,
      "correlationId": 6,
      "recordingEnable": "No",
      "recordingPreference": "No",
      "srsPeer": null,
      "portAllocId": {
        "idList": [
          {
            "idNum": 2,
            "name": "Pub-20k-30k"
          }
        ]
      },
      "recordingRelCallOnFailure": "No",
      "pCalledPartyIDOption": "No",
      "pVisitedNetworkIDOption": "No",
      "pVisitedNetworkIDValue": "notconfigured",
      "pAccessNetworkInfoOption": "No",
      "pAccessNetworkInfoValue": "notconfigured",
      "shakenEnabled": "Disabled",
      "shakenAnonymousHandling": "Reject",
      "shakenDestClaim": "Reject",
      "shakenStaleInterval": 0,
      "shakenAuthServiceType": "Internal",
      "shakenSKSURI": "empty",
      "shakenAuthCertificatePair": {
        "idList": [
          {
            "idNum": 0,
            "name": null
          }
        ]
      },
      "shakenX5UVerifier": "empty",
      "shakenVeriServiceType": "Internal",
      "shakenVerCertificatePair": {
        "idList": [
          {
            "idNum": 0,
            "name": null
          }
        ]
      },
      "dynamicRouting": "None",
      "survivability": "None",
      "survivabilityRegistrationInterval": 30,
      "hostInstanceIdx": 0
    }
  ],
  "operationId": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/sipconfiguration/peers'
