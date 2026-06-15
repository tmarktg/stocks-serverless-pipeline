resource "aws_secretsmanager_secret" "massive_api_key" {
  name                    = "${var.project_name}/massive-api-key"
  description             = "Massive.com API key for stock data ingestion"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "massive_api_key" {
  secret_id     = aws_secretsmanager_secret.massive_api_key.id
  secret_string = jsonencode({ api_key = var.massive_api_key })
}
