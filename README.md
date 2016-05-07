# tf_aws_deis_elb
Creates a public and private ELB for Deis on AWS. 

# Required
AWS CLI must be installed locally as it uses an terraform local provisioner to attach to an existing autoscaling group.  If you create your autoscaling group in the same tf file as the ELB feel free to remove the local provisioner. 

# Required Variables
* region - AWS region
* subnet_ids - comma seperate subnet_ids for the router
* autoscaler_name - exiting autoscaling group name to link the elb 
* public_security_group - security group of the public elb
* record_name - Wildcard DNS entry to point to the router
* dns_zone - AWS Route53 zone of the DNS entry

This is an example feel free to copy and delete whatever is not needed.