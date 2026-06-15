variable "function_name" {
  type = string
}

variable "handler" {
  type    = string
  default = "handler.lambda_handler"
}

variable "source_dir" {
  description = "Absolute path to the Lambda source directory"
  type        = string
}

variable "role_arn" {
  type = string
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 128
}
