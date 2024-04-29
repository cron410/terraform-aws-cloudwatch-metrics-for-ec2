//### Required input variables from module code block.

variable "region" {
  description = "AWS region"
  type        = string
}

//# AWS CLI profile name from ~/.aws/credentials or ~/.aws/config
variable "profile" {
  description = "AWS CLI credential profile"
  type        = string
}

variable "instance_id" {
  type = string
}

variable "disk_path" {
  description = "Mounted path of Disk to be monitored"
  type        = string
}
variable "alarm_actions" {
  type = list(string)
}
variable "ok_actions" {
  type = list(string)
}

variable "actions_enabled" {
  type = string
}

variable "threshold_ec2_disk" {
  description = "Disk treshold to alarm"
  type        = string
}

variable "threshold_ec2_cpu" {
  description = "Disk treshold to alarm"
  type        = string
}

variable "threshold_ec2_mem" {
  description = "Memory treshold to alarm"
  type        = string
}

#variable tag_name {}
#variable tag_value {}
