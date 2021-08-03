


####################################################################################################
#
#        Firehose + Data Transformation Lambda us-east-1
#
#####################################################################################################


module "cw_to_kinesis_data_transformation_data-coll_logs-us-east-1" {
  providers = {
    aws = "aws.receiver-east-1"
  }
  source              = "../../../modules/lambda/"
  service_name        = local.service_name
  lambda_script       = "cloudwatch-to-kinesis-data-processor.js"
  function_name       = "${local.service_name}-data-processor"
  handler_method      = "cloudwatch-to-kinesis-data-processor.handler"
  lambda_runtime      = "nodejs12.x"
  lambda_timeout      = 240
  lambda_memory_size  = 256
  tags                = local.tags
  cust_lambda_policy  = data.aws_iam_policy_document.data-coll_logs-us-east-1.json
}
#custom lambda iam policy
data "aws_iam_policy_document" "data-coll_logs-us-east-1" {
  statement {
    actions   = ["firehose:PutRecordBatch"]
    effect    = "Allow"
    resources = ["${module.kinesis_data_firehose_data-coll_logs-us-east-1.firehose_arn}"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream"
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["logs:GetLogEvents"]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

}

#kinesis Firehose Creation
module "kinesis_data_firehose_data-coll_logs-us-east-1" {
  providers = {
    aws = "aws.receiver-east-1"
  }
  source = "../../../modules/firehose/"
  service_name        = local.service_name
  hec_token           = local.hec_token
  splunk_hec_endpoint = local.splunk_hec_endpoint
  splunk_ack_timeout  = 400
  lambda_arn          = module.cw_to_kinesis_data_transformation_data-coll_logs-us-east-1.lambda_arn
  tags                = local.tags
  accountIds = local.sender_account_numbers
}

