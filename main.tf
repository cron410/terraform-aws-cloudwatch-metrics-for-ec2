terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.14.1"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  nonprod_instance_ids = [for InstanceId in local.nonprod_disk_paths.Dimensions : InstanceId.InstanceId]
  nonprod_disk_paths   = jsondecode(file("ec2_alarm/nonprod_disk_paths.json"))
  nonprod_disk_path    = [for path in local.nonprod_disk_paths.Dimensions : path.path]
  prod_instance_ids    = [for InstanceId in local.prod_disk_paths.Dimensions : InstanceId.InstanceId]
  prod_disk_paths      = jsondecode(file("ec2_alarm/prod_disk_paths.json"))
  prod_disk_path       = [for path in local.prod_disk_paths.Dimensions : path.path]
  #  instance_id = [for InstanceId in data.external.disks.result.Dimensions : InstanceId.InstanceId]
  #  disk_path = [for path in data.external.disks.result.Dimensions : path.path]
  #  #change the keys on the instance list so we can find them by name
  #  nonprod_instance_sanitized = {
  #    for key, value in data.aws_instance.nonprod_instance :
  #      value.tags.Name => value
  #  }
  #  nonprod_instance_disks = distinct(flatten([
  #    for nonprod_instance in local.nonprod_instance_sanitized : [
  #      for disk_path in local.disk_paths : {
  #        nonprod_instance = nonprod_instance
  #        disk_path = disk_path
  #      }
  #    ]
  #  ]))
}

module "nonprod_ec2_alarms" {
  count       = length(local.nonprod_instance_ids)
  source      = "./ec2_alarm"
  instance_id = local.nonprod_instance_ids[count.index]
  region      = var.region
  profile     = var.profile
  # tag_name           = var.tag_name
  # tag_value          = var.tag_value
  disk_path          = local.nonprod_disk_path[count.index]
  threshold_ec2_disk = var.threshold_ec2_disk
  threshold_ec2_cpu  = var.threshold_ec2_cpu
  threshold_ec2_mem  = var.threshold_ec2_mem
  alarm_actions      = var.sns_topics_nonprod
  ok_actions         = var.sns_topics_nonprod
  actions_enabled    = true
  depends_on         = [null_resource.aws_temp_data_regenerate]
}

module "prod_ec2_alarms" {
  count       = length(local.prod_instance_ids)
  source      = "./ec2_alarm"
  instance_id = local.prod_instance_ids[count.index]
  region      = var.region
  profile     = var.profile
  # tag_name           = var.tag_name
  # tag_value          = var.tag_value
  disk_path          = local.prod_disk_path[count.index]
  threshold_ec2_disk = var.threshold_ec2_disk
  threshold_ec2_cpu  = var.threshold_ec2_cpu
  threshold_ec2_mem  = var.threshold_ec2_mem
  alarm_actions      = var.sns_topics_prod
  ok_actions         = var.sns_topics_prod
  actions_enabled    = true
  depends_on         = [null_resource.aws_temp_data_regenerate]
}

resource "null_resource" "aws_temp_data_regenerate" {
  provisioner "local-exec" {
    command     = "bash instances.sh"
    working_dir = "./ec2_alarm"
    environment = {
      PROFILE       = var.profile
      REGION        = var.region
      OUTPUT_FOLDER = "ec2_alarm"
    }
  }
  triggers = {
    always_run = timestamp()
  }
}
