variable "service_name" {
  type = string
}

variable "hec_token" {
  type = string
}

variable "splunk_ack_timeout" {
  type = string
}

variable "lambda_arn" {
  type = string
}

variable "tags" {
  type = map
}

variable "use_custom_kinesis_destination_policy" {
  type    = bool
  default = false
}

variable "accountIds" {
  default = []
} 

variable "backup_mode" {
  default = "FailedEventsOnly"
}

variable "splunk_hec_endpoint" {
  type = string
  description = "splunk-hec-endpoint"
}