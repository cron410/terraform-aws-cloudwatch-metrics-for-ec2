# CloudWatch Alarms

This Terraform scirpt creates following Alarms to tagged EC2 instances.

- CPUUtilization
- mem_used_percent
- disk_used_percent

## Prerequisite

1. Proper AWS CLI permissions to run Terraform (EC2, CloudWatch, SNS)

2. A bunch of running EC2 instances with at least following tags
   - Name:Value (Used to name the CloudWatch Metrics)
   - Stack:Value (Used to fetch instance list)

3. CloudWatch Agent Must be running on all machines to fetch metrics like mem_used_percent and disk dimensions.



## Usage
The `null_resource` will trigger a JSON data regenerate for every run if the `depends_on` line is uncommented in each module block. Normally one would not need to regenerate data for every terraform run when interacting manually and the `depends_on` line can be commented out to drastically cut down on `terraform apply` or `terraform plan` operations. If this code is run in a pipeline on a schedule once or twice a week, leave it uncommented so the pipeline always has the correct instance data. Regenerating data too often can lead to AWS API limits. 

## Prod vs NonProd instance tags

There is a high liklihood that your environment is organized differently, so please edit the following lines in `instances.sh` with the correct tags for your machines. 
```
--query 'Reservations[*].Instances[?Tags[?Key==`Environment` && (Value!=`Production` && Value!=`DR` && Value!=`Prod`)]].[InstanceId]' \
    > nonprod_instance-ids.json
```
```
--query 'Reservations[*].Instances[*].[InstanceId]' \
    --filters "Name=tag:Environment,Values=DR,Production,Prod" \
    > prod_instance-ids.json
```  




           

## Old Example command

   - `terraform init`

   - `terraform plan -var "profile=default" -var "region=us-east-1" -var "tag_name=Stack" -var "tag_value=Test"`
   `-var "threshold_ec2_cpu=70" -var "threshold_ec2_mem=90" -var "threshold_ec2_disk=90"`
   `-var 'sns_arn=["arn:aws:sns:us-east-1:000000000000:test"]'`

   - `terraform apply -var "profile=default" -var "region=us-east-1" -var "tag_name=Stack" -var "tag_value=Test"`
   `-var "threshold_ec2_cpu=70" -var "threshold_ec2_mem=90" -var "threshold_ec2_disk=90"`
   `-var 'sns_arn=["arn:aws:sns:us-east-1:000000000000:test"]'`


