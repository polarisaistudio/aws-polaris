variable "domain_name" {
  description = "The domain name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ses_verification_token" {
  description = "SES domain verification token"
  type        = string
}

variable "dkim_tokens" {
  description = "DKIM tokens from SES"
  type        = list(string)
}

variable "github_pages_repo" {
  description = "GitHub Pages repository (e.g., username.github.io)"
  type        = string
  default     = ""
}
