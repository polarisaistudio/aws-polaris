variable "aws_region" {
  description = "AWS region for SES email receiving (must be us-east-1, us-west-2, or eu-west-1)"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = contains(["us-east-1", "us-west-2", "eu-west-1"], var.aws_region)
    error_message = "SES email receiving is only available in us-east-1, us-west-2, and eu-west-1."
  }
}

variable "domain_name" {
  description = "The custom domain name for email forwarding (e.g., example.com)"
  type        = string
  default     = "polarisaistudio.com"
}

variable "forward_mapping" {
  description = "Map of email addresses to forward. Key is the recipient (e.g., 'info'), value is the forward-to address"
  type        = map(string)
  default = {
    "info"    = "polarisaistudio@gmail.com"
    "contact" = "polarisaistudio@gmail.com"
    "support" = "polarisaistudio@gmail.com"
    "admin"   = "polarisaistudio@gmail.com"
  }
}

variable "catch_all_forward" {
  description = "Optional catch-all email address to forward all unmatched emails. Leave empty to disable"
  type        = string
  default     = "polarisaistudio@gmail.com"
}

variable "s3_bucket_prefix" {
  description = "Prefix for the S3 bucket name (will be suffixed with account ID)"
  type        = string
  default     = "ses-email-forwarder"
}

variable "ses_rule_set_name" {
  description = "Name for the SES receipt rule set"
  type        = string
  default     = "email-forwarding-rules"
}

variable "email_retention_days" {
  description = "Number of days to retain emails in S3 before deletion"
  type        = number
  default     = 1
}

variable "from_email" {
  description = "Optional: Email address to use as sender when forwarding. Defaults to noreply@domain_name"
  type        = string
  default     = "noreply@polarisaistudio.com"
}

variable "github_pages_repo" {
  description = "GitHub Pages repository (e.g., username.github.io). Leave empty to skip GitHub Pages DNS records"
  type        = string
  default     = "polarisaistudio.github.io"
}

variable "preserve_reply_to" {
  description = "Preserve Reply-To header with original sender (requires SES production mode, not sandbox). Set to true after getting SES production access."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "EmailForwarding"
    ManagedBy   = "Terraform"
    Domain      = "polarisaistudio.com"
  }
}

variable "vercel_enabled" {
  description = "Enable Vercel wildcard subdomain DNS configuration (*.app.domain.com)"
  type        = bool
  default     = true
}

variable "vercel_subdomain" {
  description = "Subdomain to delegate to Vercel (e.g., 'app' creates *.app.polarisaistudio.com)"
  type        = string
  default     = "ams"
}

variable "vercel_nameservers" {
  description = "Vercel nameservers for NS delegation. Get these from Vercel project settings."
  type        = list(string)
  default     = ["ns1.vercel-dns.com", "ns2.vercel-dns.com"]
}

# ==============================================================================
# Resend Configuration (DEPRECATED - migrated to SES)
# ==============================================================================

variable "resend_enabled" {
  description = "Enable Resend email DNS configuration for sending emails via subdomain (DEPRECATED - use SES sending instead)"
  type        = bool
  default     = false
}

variable "resend_subdomain" {
  description = "Subdomain for Resend email (e.g., 'mail' creates mail.polarisaistudio.com)"
  type        = string
  default     = "mail"
}

variable "resend_dkim_key" {
  description = "DKIM public key from Resend dashboard. Get this from Resend after adding your domain."
  type        = string
  default     = "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDE21Hhd1tNJgVHBeaT4gZ8rVAfsgRbepNxAip3pvOdG/cwWGg3AGDrdKXQXiqerr5TX9NMfxbH+bj1IuQdp3VEmClgrXi0DtmZyfy5ZknzUHwT5g9cmMjAFTC++TWvUHBgC/JPr2cRBuMnMMVimbvg0aKIOptVTMqy5jjGmWAkjQIDAQAB"
}

# ==============================================================================
# SES Sending Domain Configuration
# ==============================================================================

variable "ses_sending_enabled" {
  description = "Enable SES sending domain DNS configuration (e.g., mail.polarisaistudio.com)"
  type        = bool
  default     = true
}

variable "ses_sending_subdomain" {
  description = "Subdomain for SES sending email (e.g., 'mail' creates mail.polarisaistudio.com)"
  type        = string
  default     = "mail"
}
