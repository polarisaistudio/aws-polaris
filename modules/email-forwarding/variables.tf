variable "domain_name" {
  description = "The domain name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "forward_mapping" {
  description = "Map of email addresses to forward"
  type        = map(string)
}

variable "catch_all_forward" {
  description = "Catch-all email address"
  type        = string
  default     = ""
}

variable "from_email" {
  description = "From email address for forwarding"
  type        = string
}

variable "email_retention_days" {
  description = "Number of days to retain emails in S3"
  type        = number
  default     = 7
}

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
  default     = "ses-email-forwarder"
}

variable "ses_rule_set_name" {
  description = "Name for the SES receipt rule set"
  type        = string
  default     = "email-forwarding-rules"
}

variable "preserve_reply_to" {
  description = "Preserve Reply-To header with original sender (requires SES production mode, not sandbox)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
