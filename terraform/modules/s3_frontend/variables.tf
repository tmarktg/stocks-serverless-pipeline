variable "bucket_name" {
  type = string
}

variable "frontend_dir" {
  description = "Absolute path to the frontend source directory"
  type        = string
}

variable "api_endpoint" {
  description = "API Gateway base URL (without /movers suffix)"
  type        = string
}
