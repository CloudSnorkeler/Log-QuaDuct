variable "service_name" {
  type = string
}

variable "cloudwatch_agg_arn" {
  type = string
}

variable "tags" {
  type = map
}

variable "cw_log_group_override_name" {
  type = string
  default = ""
}

variable "filter_pattern" {
  type = string
  default = ""
}

variable "logRetention" {
  type = string
  default = "90"
}