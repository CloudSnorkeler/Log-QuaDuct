################################################################
#
#                   Local Data Sources
#
################################################################

locals {
  tags         = { "service-id" = var.hec_token }
  service_name = var.service-id
  hec_token    = "hec"
  sender_account_numbers = ["12345678910"] 
  splunk_hec_endpoint =  "<splunk Url>"
}

variable "hec_token" { type = string }
variable "service-id" { type = string }


