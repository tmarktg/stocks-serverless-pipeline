data "aws_caller_identity" "current" {}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = var.table_name
}

module "ingestion_lambda" {
  source        = "./modules/lambda"
  function_name = "${var.project_name}-ingestion"
  handler       = "handler.lambda_handler"
  source_dir    = "${path.root}/../lambdas/ingestion"

  role_arn = aws_iam_role.ingestion.arn

  environment_variables = {
    TABLE_NAME  = module.dynamodb.table_name
    SECRET_NAME = aws_secretsmanager_secret.massive_api_key.name
  }
}

module "retrieval_lambda" {
  source        = "./modules/lambda"
  function_name = "${var.project_name}-retrieval"
  handler       = "handler.lambda_handler"
  source_dir    = "${path.root}/../lambdas/retrieval"

  role_arn = aws_iam_role.retrieval.arn

  environment_variables = {
    TABLE_NAME = module.dynamodb.table_name
  }
}

module "eventbridge" {
  source            = "./modules/eventbridge"
  rule_name         = "${var.project_name}-daily-cron"
  schedule          = var.cron_schedule
  lambda_arn        = module.ingestion_lambda.function_arn
  lambda_name       = module.ingestion_lambda.function_name
}

module "api_gateway" {
  source             = "./modules/api_gateway"
  api_name           = "${var.project_name}-api"
  lambda_invoke_arn  = module.retrieval_lambda.invoke_arn
  lambda_name        = module.retrieval_lambda.function_name
  aws_region         = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
}

module "s3_frontend" {
  source        = "./modules/s3_frontend"
  bucket_name   = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"
  frontend_dir  = "${path.root}/../frontend"
  api_endpoint  = module.api_gateway.api_endpoint
}

resource "aws_cloudwatch_metric_alarm" "ingestion_errors" {
  alarm_name          = "${var.project_name}-ingestion-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 86400
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "Ingestion Lambda failed — stock data may not have been recorded"

  dimensions = {
    FunctionName = module.ingestion_lambda.function_name
  }
}
