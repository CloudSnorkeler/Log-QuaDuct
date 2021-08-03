################################################################
#
#                   Local Data Sources
#
################################################################

locals {
  #creates subscription filer name
  sub_filter_name = var.cw_log_group_override_name == "" ? "${var.service_name}-subscription-filter" : "${var.service_name}-${local.log_group_name}-subscription-filter"
  
  #creates logs group
  gen_log_group_value = "${var.service_name}-log-group"

  #generates log group name
  log_group_name = var.cw_log_group_override_name == "" ?  local.gen_log_group_value : var.cw_log_group_override_name
  
  #determines if log group is required
  log_group_needed = var.cw_log_group_override_name == "" ? 1 : 0

  prefix = "logquaduct"
}

################################################################
#
#                Cloudwatch Subscription Filter
#
################################################################

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-log-filter" {
  name            = local.sub_filter_name
  destination_arn = var.cloudwatch_agg_arn
  log_group_name  = local.log_group_name
  filter_pattern  = var.filter_pattern
  depends_on = ["aws_cloudwatch_log_group.log-group"]
}

resource "aws_cloudwatch_log_group" "log-group" {
  count = local.log_group_needed
  name = local.log_group_name
  tags = var.tags
  retention_in_days = var.logRetention
  
}

data "aws_cloudwatch_log_group" "found_log-group" {
  # the resource name will be either a custom name (var.cust_log_group_name) or the default calculated name "${var.service_name}-log-group"
  name       = local.log_group_name
  depends_on = ["aws_cloudwatch_log_group.log-group"]
}

