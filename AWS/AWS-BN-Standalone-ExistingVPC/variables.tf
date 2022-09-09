variable "instance_type" {}
variable "bn_version" {}
variable "region" {}
variable "mySG_id" {}
variable "public_subnet_id" {}
variable "private_subnet_id" {}
variable "mgmt_subnet_id" {}

# Names of resources created will be suffixed with this string for ease of identification.
variable "mySuffix" {}

# Default tags added in resources created by this script for ease of identification.
variable "myEnvironment" {}
variable "myService" {}