variable "lambda_script" {
  type = string
}

variable "function_name" {
  type = string
}

variable "handler_method" {
  type = string
}

variable "lambda_runtime" {
  type = string
}

variable "lambda_timeout" {
  type = string
}

variable "lambda_memory_size" {
  type = string
}

variable "tags" {
  type = map
}

variable "service_name" {
  type = string
}

variable "cust_lambda_policy" {
  type = string
} 