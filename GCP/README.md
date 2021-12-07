### Setup

Don't forget to create service account from GCP Console and download JSON key

This contains your authentication required for Terraform to communicate with the Google API.

You can get it under 

`Google Cloud Platform -> IAM & Admin -> Service Accounts -> Click on Compute Engine default service account -> Keys -> Add Key(JSON) -> Download`

Put the downloaded file right were your Terraform config file is and name it `account.json`.