# Log Group ARN
output "log_group_arn" {
  value = data.aws_cloudwatch_log_group.found_log-group.arn
}

# Log Group Name
output "log_group_id" {
  value = data.aws_cloudwatch_log_group.found_log-group.id
}
