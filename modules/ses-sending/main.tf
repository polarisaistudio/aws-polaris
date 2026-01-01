# SES Sending Domain Module
# Configures SES for sending emails from a subdomain (e.g., mail.polarisaistudio.com)

# SES domain identity for sending subdomain
resource "aws_ses_domain_identity" "sending" {
  domain = "${var.subdomain}.${var.domain_name}"
}

# DKIM for sending subdomain
resource "aws_ses_domain_dkim" "sending" {
  domain = aws_ses_domain_identity.sending.domain
}

# Mail-from domain (for SPF alignment and bounce handling)
resource "aws_ses_domain_mail_from" "sending" {
  domain           = aws_ses_domain_identity.sending.domain
  mail_from_domain = "bounce.${var.subdomain}.${var.domain_name}"
}

# Outputs for DNS records
output "verification_token" {
  description = "SES domain verification token for TXT record"
  value       = aws_ses_domain_identity.sending.verification_token
}

output "dkim_tokens" {
  description = "DKIM tokens for CNAME records (3 required)"
  value       = aws_ses_domain_dkim.sending.dkim_tokens
}

output "domain" {
  description = "The full sending domain"
  value       = aws_ses_domain_identity.sending.domain
}

output "mail_from_domain" {
  description = "The mail-from domain for bounce handling"
  value       = aws_ses_domain_mail_from.sending.mail_from_domain
}

output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.sending.arn
}
