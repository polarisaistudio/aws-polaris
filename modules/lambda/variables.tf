variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_dir" {
  description = "Directory containing the Lambda source code (relative to root)"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "bootstrap"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "provided.al2023"
}

variable "architecture" {
  description = "Lambda architecture (x86_64 or arm64)"
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be either x86_64 or arm64."
  }
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "build_command" {
  description = "Command to build the Lambda function (runs in source_dir)"
  type        = string
  default     = "make build"
}

variable "iam_policy_statements" {
  description = "Additional IAM policy statements for the Lambda execution role"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
