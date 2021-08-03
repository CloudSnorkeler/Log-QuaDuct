################################################################
#
#                   Local Data Sources
#
################################################################
data "aws_region" "current" {}

################################################################
#
#                       Lambda Script
#
# ################################################################

#Creating an archive of lambda script
data "archive_file" "lambda_archive" {
  type = "zip"
  source_file = "../../../modules/data_processing_source/${var.lambda_script}"
  output_path = "../../../modules/data_processing_source/${var.lambda_script}.zip"
}

#Deploy/configure the lambda processor
resource "aws_lambda_function" "lambda_processor" {
  filename      = "../../../modules/data_processing_source/${var.lambda_script}.zip"
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.handler_method
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  source_code_hash = data.archive_file.lambda_archive.output_base64sha256
  tags = var.tags
}

################################################################
#
#                   Lambda IAM Access
#
################################################################

#Permit Kinesis to Invoke the processor lambda
resource "aws_lambda_permission" "kinesis_invoker" {
  statement_id = "AllowExecutionFromKinesis"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_processor.function_name
  principal = "kinesis.amazonaws.com"

}


resource "aws_iam_role" "lambda_role" {
  name = "${var.service_name}-${data.aws_region.current.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_trust.json
  tags = var.tags
}

data "aws_iam_policy_document" "lambda_role_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "cust-policy" {
  name        = "${var.service_name}-lambda-policy-${data.aws_region.current.name}"
  description = "Managed By Terraform."

  policy = var.cust_lambda_policy
}


resource "aws_iam_role_policy_attachment" "lambda-role-attach-cust-pol" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.cust-policy.arn}"
}
