output "firehose_arn" {
  value = "${aws_kinesis_firehose_delivery_stream.data-firehose.arn}"
}

output "log_group_destination" {
  value = "${aws_cloudwatch_log_destination.kinesis_destination.arn}"
}

output "s3_bucket_name" {
  value = "${aws_s3_bucket.kinesis_backup_bucket.id}"
}

output "cloudwatch_role_arn" {
  value = "${aws_iam_role.cloudwatch_to_fh_trust_role.arn}"
}