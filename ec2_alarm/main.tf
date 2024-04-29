terraform {
  required_version = ">=1.0.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.11"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.2.3"
    }
  }
}

data "external" "disk_dimensions" {
  program     = ["bash", "disk_dimensions.sh"]
  working_dir = path.module
  query = {
    profile     = var.profile
    region      = var.region
    instance_id = var.instance_id
    disk_path   = var.disk_path
#   disk_path   = local.disk_paths[count.index]
  }
}

data "aws_instance" "each_instance" {
  instance_id = var.instance_id
}

resource "aws_cloudwatch_metric_alarm" "disk_used_percent_alarm" {
  #count = length(local.disk_paths)

  alarm_name = join(" - ", [
    "DiskSpace",
    data.aws_instance.each_instance.tags.Environment,
    var.disk_path,
    data.aws_instance.each_instance.tags.Name,
    var.region
  ])

  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "disk_used_percent"
  namespace                 = "CWAgent"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = var.threshold_ec2_disk
  alarm_description         = "This metric monitors ec2 disk utilization"
  insufficient_data_actions = []
  treat_missing_data        = "ignore"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  actions_enabled           = var.actions_enabled

  dimensions = data.external.disk_dimensions.result
  #  dimensions = data.external.disk_dimensions[count.index].result
  #  dimensions = {
  #    InstanceId = data.external.disk_dimensions.result.InstanceId
  #    path = data.external.disk_dimensions.result.path
  #    ImageId = data.external.disk_dimensions.result.ImageId
  #    InstanceType = data.external.disk_dimensions.result.InstanceType
  #    device = data.external.disk_dimensions.result.device
  #    fstype = data.external.disk_dimensions.result.fstype
  #  }
  tags = {
    Engagement  = tostring(data.aws_instance.each_instance.tags.Engagement)
    Environment = data.aws_instance.each_instance.tags.Environment
    MGMT        = "Managed by Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name = join(" - ", [
    "CPU Used",
    data.aws_instance.each_instance.tags.Name,
    var.region
  ])
  alarm_description         = "Average ec2 instance CPU utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = var.threshold_ec2_cpu
  insufficient_data_actions = []
  treat_missing_data        = "ignore"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  actions_enabled           = var.actions_enabled
  dimensions = {
    InstanceId = var.instance_id
  }
  tags = {
    Engagement  = tostring(data.aws_instance.each_instance.tags.Engagement)
    Environment = data.aws_instance.each_instance.tags.Environment
    MGMT        = "Managed by Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "mem_used_percent_alarm" {
  alarm_name = join(" - ", [
    "Memory Used",
    data.aws_instance.each_instance.tags.Name,
    var.region
  ])
  alarm_description         = "This metric monitors ec2 memory utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "mem_used_percent"
  namespace                 = "CWAgent"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = var.threshold_ec2_mem
  insufficient_data_actions = []
  treat_missing_data        = "ignore"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  actions_enabled           = var.actions_enabled
  dimensions = {
    InstanceId   = var.instance_id
    ImageId      = data.aws_instance.each_instance.ami
    InstanceType = data.aws_instance.each_instance.instance_type
  }
  tags = {
    Engagement  = tostring(data.aws_instance.each_instance.tags.Engagement)
    Environment = data.aws_instance.each_instance.tags.Environment
    MGMT        = "Managed by Terraform"
  }
}


resource "aws_cloudwatch_metric_alarm" "status-check-failed" {
  alarm_name = join(" - ", [
    "Status Check Failed",
    data.aws_instance.each_instance.tags.Name,
    var.region
  ])
  alarm_description         = "EC2 Status Check Failed"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "0.0"
  insufficient_data_actions = []
  treat_missing_data        = "ignore"
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  actions_enabled           = var.actions_enabled
  dimensions = {
    InstanceId = var.instance_id
  }
  tags = {
    Engagement  = tostring(data.aws_instance.each_instance.tags.Engagement)
    Environment = data.aws_instance.each_instance.tags.Environment
    MGMT        = "Managed by Terraform"
  }
}
