data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ── Ingestion Lambda Role ────────────────────────────────────────────────────

resource "aws_iam_role" "ingestion" {
  name               = "${var.project_name}-ingestion-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ingestion_basic_execution" {
  role       = aws_iam_role.ingestion.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ingestion_inline" {
  name = "${var.project_name}-ingestion-policy"
  role = aws_iam_role.ingestion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBWrite"
        Effect = "Allow"
        Action = ["dynamodb:PutItem"]
        Resource = module.dynamodb.table_arn
      },
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.massive_api_key.arn
      }
    ]
  })
}

# ── Retrieval Lambda Role ────────────────────────────────────────────────────

resource "aws_iam_role" "retrieval" {
  name               = "${var.project_name}-retrieval-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "retrieval_basic_execution" {
  role       = aws_iam_role.retrieval.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "retrieval_inline" {
  name = "${var.project_name}-retrieval-policy"
  role = aws_iam_role.retrieval.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBRead"
        Effect = "Allow"
        Action = ["dynamodb:Scan"]
        Resource = module.dynamodb.table_arn
      }
    ]
  })
}
