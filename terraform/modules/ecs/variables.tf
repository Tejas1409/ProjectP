variable "project" { type = string }
variable "region" { type = string }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "alb_sg_id" { type = string }
variable "target_group_arn" { type = string }

variable "container_port" { type = number }
variable "cpu" { type = number }
variable "memory" { type = number }

variable "image_uri" { type = string }
variable "log_group_name" { type = string }