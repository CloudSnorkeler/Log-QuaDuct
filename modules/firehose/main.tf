################################################################
#
#                   Local Data Sources
#
################################################################
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}

locals {
  policy      = data.aws_iam_policy_document.kinesis_destination_policy_doc.json

  merged_accountIds = distinct(compact(var.accountIds))
}

################################################################
#
#                   Kinesis Data Firehose
#
################################################################
resource "aws_kinesis_firehose_delivery_stream" "data-firehose" {
  name        = var.service_name
  destination = "splunk"

  s3_configuration {
    role_arn           = aws_iam_role.kinesis_role.arn
    bucket_arn         = aws_s3_bucket.kinesis_backup_bucket.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  splunk_configuration {
    hec_endpoint               = var.splunk_hec_endpoint
    hec_token                  = var.hec_token
    hec_acknowledgment_timeout = var.splunk_ack_timeout
    hec_endpoint_type          = "Raw"
    s3_backup_mode             = var.backup_mode
    processing_configuration {
      enabled = "true"
      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${var.lambda_arn}:$LATEST"
        }

        parameters {
          parameter_name  = "RoleArn"
          parameter_value = aws_iam_role.kinesis_role.arn
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_ts_logs.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_logs.name
    }
  }

  tags = var.tags
}


################################################################
#
#                   Firehose IAM Access
#
################################################################
#Firehose Role
resource "aws_iam_role" "kinesis_role" {
  name               = "${var.service_name}-${data.aws_region.current.name}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_role_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "kinesis_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "kinesis_role_attach" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = aws_iam_policy.kinesis_firehose_iam_policy.arn
}
#Firehose Policy Doc
data "aws_iam_policy_document" "firehose_policy" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.kinesis_backup_bucket.arn}",
      "${aws_s3_bucket.kinesis_backup_bucket.arn}/*",
    ]

    effect = "Allow"
  }

  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration",
    ]

    resources = [
      "${var.lambda_arn}:$LATEST",
    ]
  }


  statement {
    actions = ["logs:PutLogEvents"]
    resources = [
      "${aws_cloudwatch_log_group.kinesis_ts_logs.arn}",
      "${aws_cloudwatch_log_stream.kinesis_logs.arn}",
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "kinesis_firehose_iam_policy" {
  name   = "${var.service_name}-firehose-policy-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.firehose_policy.json
}

resource "aws_iam_role_policy_attachment" "kenisis_fh_role_attachment" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = aws_iam_policy.kinesis_firehose_iam_policy.arn
}

# Logging Group for Flood Firehose
resource "aws_cloudwatch_log_group" "kinesis_ts_logs" {
  name              = "/aws/kinesisfirehose/${data.aws_region.current.name}-${var.service_name}"
  retention_in_days = 90

  tags = var.tags
}

# Create the stream
resource "aws_cloudwatch_log_stream" "kinesis_logs" {
  name           = "${var.service_name}-${data.aws_region.current.name}-firehose-cw-stream"
  log_group_name = aws_cloudwatch_log_group.kinesis_ts_logs.name
}

locals {
  bucket-name = "logquaduct-security-${module.CONSTANTS.account_nickname}-${module.CONSTANTS.account_environment}-${var.service_name}-kinesis-${data.aws_region.current.name}"
}

resource "aws_s3_bucket" "kinesis_backup_bucket" {
  bucket = local.bucket-name
  acl    = "private"

  tags = var.tags

  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }

}

################################################################
#
#         Core Cloudwatch Log Group + Subscription Filter
#
################################################################

resource "aws_iam_role" "cloudwatch_to_fh_trust_role" {
  name               = "${var.service_name}-CW-AGG-Role-${data.aws_region.current.name}"
  description        = "Role for CloudWatch Log Group subscription"
  assume_role_policy = "${data.aws_iam_policy_document.cloudwatch_to_fh_trust_policy.json}"
  tags               = "${var.tags}"
}

data "aws_iam_policy_document" "cloudwatch_to_fh_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}



data "aws_iam_policy_document" "cloudwatch_to_fh_access_policy" {
  statement {
    actions = [
      "firehose:*",
    ]

    effect = "Allow"

    resources = [
      "${aws_kinesis_firehose_delivery_stream.data-firehose.arn}",
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    effect = "Allow"

    resources = [
      "${aws_iam_role.cloudwatch_to_fh_trust_role.arn}",
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_to_fh_access_policy" {
  name        = "${var.service_name}-CW-AGG-Policy-${data.aws_region.current.name}"
  description = "Cloudwatch to Firehose Subscription Policy"
  policy      = "${data.aws_iam_policy_document.cloudwatch_to_fh_access_policy.json}"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_to_fh" {
  role       = "${aws_iam_role.cloudwatch_to_fh_trust_role.name}"
  policy_arn = "${aws_iam_policy.cloudwatch_to_fh_access_policy.arn}"
}

resource "aws_cloudwatch_log_destination" "kinesis_destination" {

  name       = "${var.service_name}-cw-destination"
  role_arn   = aws_iam_role.cloudwatch_to_fh_trust_role.arn
  target_arn = aws_kinesis_firehose_delivery_stream.data-firehose.arn
}

data "aws_iam_policy_document" "kinesis_destination_policy_doc" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        for accountId in local.merged_accountIds :
        format("%s", accountId)
      ]
    }

    actions = [
      "logs:PutSubscriptionFilter",
    ]

    resources = [
      "${aws_cloudwatch_log_destination.kinesis_destination.arn}",
    ]
  }
}

resource "aws_cloudwatch_log_destination_policy" "kinesis_destination_policy" {
  destination_name = "${aws_cloudwatch_log_destination.kinesis_destination.name}"
  access_policy    = local.policy
}
