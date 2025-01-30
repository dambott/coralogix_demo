# README

update terraform.tf to point to a valid bucket as the backend configuration storage
In terraform.tfvars :
  set region, cluster name, cluster version
  set the NodeGroup and Instance type for your nodes
  set the min,max and desired sizes as needed

In provider.tf:
  set S3bucketName and S3region to match the name and region of the state S3 bucket