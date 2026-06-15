variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "stocks-serverless"
}

variable "table_name" {
  description = "DynamoDB table name for storing daily top movers"
  type        = string
  default     = "stock-movers"
}

variable "cron_schedule" {
  description = "EventBridge cron expression for ingestion (default: 9 PM UTC / 5 PM ET weekdays)"
  type        = string
  default     = "cron(0 21 ? * MON-FRI *)"
}

variable "massive_api_key" {
  description = "Massive.com API key — pass via TF_VAR_massive_api_key or -var flag. Never hardcode."
  type        = string
  sensitive   = true
}
