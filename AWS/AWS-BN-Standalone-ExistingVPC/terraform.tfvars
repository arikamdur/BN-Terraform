# Update following before running script

instance_type     = "c5.large"
bn_version        = "3.9.1"
region            = "us-east-1"
mySG_id           = "sg-0310ba1d4a82c0c50"
public_subnet_id  = "subnet-09ec6a422fca730d4"
private_subnet_id = "subnet-0104f3ecc20a878bc"
mgmt_subnet_id    = "subnet-05ece9189ebb4a490"

#suffix resource names
mySuffix = "_001"

# default tags
myEnvironment = "Test"
myService     = "Test Traffic"