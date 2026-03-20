variable "project" { type = string }
variable "region" { type = string }

variable "cluster_name" { type = string }
variable "service_name" { type = string }
variable "lb_arn_suffix" { type = string }
variable "tg_arn_suffix" { type = string }

variable "cpu_alarm_threshold" { type = number }
variable "dashboard_json_path" { type = string }