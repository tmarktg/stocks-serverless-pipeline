resource "aws_s3_bucket" "frontend" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

locals {
  static_files = {
    "index.html" = "text/html"
    "style.css"  = "text/css"
    "app.js"     = "application/javascript"
  }
}

resource "aws_s3_object" "static" {
  for_each = local.static_files

  bucket       = aws_s3_bucket.frontend.id
  key          = each.key
  source       = "${var.frontend_dir}/${each.key}"
  content_type = each.value
  etag         = filemd5("${var.frontend_dir}/${each.key}")
}

# Terraform injects the live API URL into config.js at deploy time
resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.js"
  content      = "window.API_URL = '${var.api_endpoint}/movers';"
  content_type = "application/javascript"
  etag         = md5("window.API_URL = '${var.api_endpoint}/movers';")
}
