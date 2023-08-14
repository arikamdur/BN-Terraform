#!/bin/bash

#primaryIpAddressId from create vlan goes into sigIfIndex

body=$(cat  << EOF
{
  "list": [
    {
      "id": 0,
      "name": "Interconnect_Interface",
      "pvisitedNetworkIDOption": "No",
      "pvisitedNetworkIDValue": "notconfigured",
      "pcalledPartyIDOption": "No",
      "paccessNetworkInfoValue": "notconfigured",
      "paccessNetworkInfoOption": "No",
      "cfgStatus": "Yes",
      "domain": "",
      "nwType": "Interconnect",
      "rxService": "No",
      "diameterType": "None",
      "ccfh": "Continue",
      "regPortReuse": "Yes",
      "sipConnect": "No",
      "sipConnectType": "None",
      "imsNetwork": "No",
      "subTraffic": "No",
      "accType": "IEEE-802.3",
      "operId": null,
      "transportAddressType": "IPv4",
      "sigIfIndex": 2,
      "sigIfName": "ETH1_IP",
      "vlanLogicalIfIdx": 2,
      "vlanName": "PubVlan",
      "port": 5060,
      "transpProt": "UDP-TCP",
      "maxAllowedUdpMTU": 0,
      "sigTos": 0,
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
      "allowOnlyAssociatedPeers": "No",
      "tlsProfile": null,
      "srtpProfile": null,
      "msTeams": "MSTeamsDisabled",
      "trustLevel": "High",
      "note": "",
      "timeZone": " ",
      "enforceIPSec": "No",
      "tgrpContext": "",
      "routingPolicy": null,
      "reRoutingPolicy": null,
      "recordingEnable": "No",
      "recordingPreference": "No",
      "srsPeer": null,
      "recordingRelCallOnFailure": "No",
      "portAllocId": {
        "idList": [
          {
            "idNum": 2,
            "name": "Pub-20k-30k"
          }
        ]
      },
      "pilotName": "",
      "regIpPortAllocId": null,
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
      "dynamicRouting": null,
      "survivability": null,
      "survivabilityRegistrationInterval": null
    }
  ],
  "operationId": 0,
  "totalrecords": 0
}
EOF
)

curl -u SBCMANAGER:sbcmgr -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "$body" -k 'https://'$ETH0_IP':8443/sbc/application/sipconfiguration/interfaces'
