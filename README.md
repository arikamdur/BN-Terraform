<img src="terraform_logo.jpg"><br>

# Deploy BorderNet using Terraform 

The Following TF scripts are available :

<table border="0">
 <tr>
    <td><b style="font-size:30px">AWS</b></td>
    <td><b style="font-size:30px">Azure</b></td>
    <td><b style="font-size:30px">GCP</b></td>
    <td><b style="font-size:30px">Oracle</b></td>

 </tr>
 <tr>
<td>
1.Standalone <br>
2.Standalone with EMS<br>
3.Standalone with SIPP<br>
4.Standalone with SIPP - Performance<br>
5.Standalone with EMS & SIPP<br>
6.High Availability<br>  
7.High Availability with SIPP for Scaling<br> 
8.Geo Redundancy with SIPP<br>  
</td>
<td>
    1.Standalone<br>
    2.Standalone with EMS<br>
    3.Standalone with SIPP<br>
    4.Standalone with SIPP - Performance<br>
    5.Standalone with SIPP - Teams<br>
    6.Geo Redundancy with SIPP<br>
    7.Geo Redundancy with LB & SIPP<br>
</td>
<td>
    1.Standalone <br>
    2.Standalone with SIPP<br>
    3.Standalone with SIPP - Performance<br>
    4.Geo Redundancy with SIPP<br>
 
</td>
<td>
    1.Standalone <br>
 
</td>
 </tr>
</table>

### Set AWS Credentials in Windows PowerShell:
```
$env:AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxxx"
$env:AWS_SECRET_ACCESS_KEY="yyyyyyyyyyyyyyyyyyyyyyyyyyyy"
$env:AWS_DEFAULT_REGION="zzzzzzzzz"
```

### Set AWS Credentials in Linux Shell:
```
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="yyyyyyyyyyyyyyyyyyyyyyyyyyyy"
export AWS_DEFAULT_REGION="zzzzzzzzz"
```

### Terraform Commands
```
terraform init
terraform init -upgrade
terraform plan
terraform apply
terraform apply -refresh-only
terraform destroy

terraform show
terraform output
terraform console
terraform import
terraform taint (terraform apply -replace <name>)
terraform graph | dot -Tsvg > graph.svg
ssh ec2-user@$(terraform output -raw public_ip)
```

### Terraform State Commands
```
terraform state show
terraform state list
terraform state pull
terraform state rm
terraform state mv
terraform state push
```

## Contact
This repository was developed and maintained by [@Alex Nisanov](https://www.linkedin.com/in/alexnisanov/)  
[alex.nisanov@enghouse.com](mailto:alex.nisanov@enghouse.com)  

