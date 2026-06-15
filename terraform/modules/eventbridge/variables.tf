variable "rule_name" {
  type = string
}

variable "schedule" {
  description = "EventBridge cron or rate expression"
  type        = string
}

variable "lambda_arn" {
  type = string
}

variable "lambda_name" {
  type = string
}
