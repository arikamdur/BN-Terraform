### Setup

Install OCI-CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

then run "oci session authenticate" to Authenticate with Oracle Cloud
you will need to select the OCI region, and once you do, it’s going to open a web browser and authenticate you agains the OCI tenancy.

Remember, the token is only valid for an hour. You can refresh it with

```oci session refresh --profile <profile_name>```

Once it expires, just start with

```oci session authenticate```

### Zones
1: af-johannesburg-1, 2: ap-chiyoda-1, 3: ap-chuncheon-1, 4: ap-dcc-canberra-1, 5: ap-hyderabad-1,
6: ap-ibaraki-1, 7: ap-melbourne-1, 8: ap-mumbai-1, 9: ap-osaka-1, 10: ap-seoul-1,
11: ap-singapore-1, 12: ap-sydney-1, 13: ap-tokyo-1, 14: ca-montreal-1, 15: ca-toronto-1,
16: eu-amsterdam-1, 17: eu-frankfurt-1, 18: eu-marseille-1, 19: eu-milan-1, 20: eu-stockholm-1,
21: eu-zurich-1, 22: il-jerusalem-1, 23: me-abudhabi-1, 24: me-dcc-muscat-1, 25: me-dubai-1,
26: me-jeddah-1, 27: sa-santiago-1, 28: sa-saopaulo-1, 29: sa-vinhedo-1, 30: uk-cardiff-1,
31: uk-gov-cardiff-1, 32: uk-gov-london-1, 33: uk-london-1, 34: us-ashburn-1, 35: us-gov-ashburn-1,
36: us-gov-chicago-1, 37: us-gov-phoenix-1, 38: us-langley-1, 39: us-luke-1, 40: us-phoenix-1,
41: us-sanjose-1)