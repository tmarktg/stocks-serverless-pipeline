output "api_endpoint" {
  description = "REST API endpoint for GET /movers"
  value       = "${module.api_gateway.api_endpoint}/movers"
}

output "frontend_url" {
  description = "Public URL of the S3 static website"
  value       = module.s3_frontend.website_url
}

output "dynamodb_table" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "ingestion_lambda" {
  description = "Ingestion Lambda function name"
  value       = module.ingestion_lambda.function_name
}
