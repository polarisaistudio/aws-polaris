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

variable "vercel_enabled" {
  description = "Enable Vercel wildcard subdomain DNS configuration"
  type        = bool
  default     = true
}

variable "vercel_subdomain" {
  description = "Subdomain to delegate to Vercel (e.g., 'app' for *.app.domain.com)"
  type        = string
  default     = "ams"
}

variable "vercel_nameservers" {
  description = "Vercel nameservers for NS delegation"
  type        = list(string)
  default     = ["ns1.vercel-dns.com", "ns2.vercel-dns.com"]
}

# ==============================================================================
# Resend Configuration
# ==============================================================================

variable "resend_enabled" {
  description = "Enable Resend email DNS configuration"
  type        = bool
  default     = false
}

variable "resend_subdomain" {
  description = "Subdomain for Resend email (e.g., 'mail' for mail.domain.com)"
  type        = string
  default     = "mail"
}

variable "resend_dkim_key" {
  description = "DKIM public key from Resend (the 'p=' value without quotes)"
  type        = string
  default     = ""
}
