# Outputs from modules

# DNS Outputs
output "hosted_zone_id" {
  description = "Route 53 hosted zone ID (using existing zone for polarisaistudio.com)"
  value       = module.dns.hosted_zone_id
}

output "nameservers" {
  description = "Route 53 nameservers (existing hosted zone)"
  value       = module.dns.nameservers
}

# Email Forwarding Outputs
output "domain_name" {
  description = "The domain name configured for email forwarding"
  value       = var.domain_name
}

output "ses_verification_token" {
  description = "SES domain verification token"
  value       = module.email_forwarding.ses_verification_token
}

output "dkim_tokens" {
  description = "DKIM tokens for email authentication"
  value       = module.email_forwarding.dkim_tokens
}

output "mx_record" {
  description = "MX record configured for the domain"
  value       = "10 inbound-smtp.${var.aws_region}.amazonaws.com"
}

output "s3_bucket_name" {
  description = "S3 bucket used for email storage"
  value       = module.email_forwarding.s3_bucket_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function handling email forwarding"
  value       = module.email_forwarding.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.email_forwarding.lambda_function_arn
}

output "ses_rule_set_name" {
  description = "Name of the active SES receipt rule set"
  value       = module.email_forwarding.ses_rule_set_name
}

output "forward_mapping" {
  description = "Email forwarding mapping configuration"
  value       = var.forward_mapping
  sensitive   = false
}

output "domain_verification_status" {
  description = "Domain verification status message"
  value       = "Domain verification is complete. DNS records have been configured."
}

# Email Verification Outputs
output "email_identities_requiring_verification" {
  description = "Email addresses that need to be verified in SES"
  value       = module.email_forwarding.email_identities_requiring_verification
}

output "verification_instructions" {
  description = "Instructions for verifying email addresses"
  value       = module.email_forwarding.verification_instructions
}
