# Main Terraform Configuration for AWS Email Forwarding and DNS

# Email Forwarding Module
module "email_forwarding" {
  source = "./modules/email-forwarding"

  domain_name          = var.domain_name
  aws_region           = var.aws_region
  forward_mapping      = var.forward_mapping
  catch_all_forward    = var.catch_all_forward
  from_email           = var.from_email
  email_retention_days = var.email_retention_days
  s3_bucket_prefix     = var.s3_bucket_prefix
  ses_rule_set_name    = var.ses_rule_set_name
  preserve_reply_to    = var.preserve_reply_to
  tags                 = var.tags
}

# SES Sending Domain Module (for application email sending)
module "ses_sending" {
  source = "./modules/ses-sending"

  domain_name = var.domain_name
  subdomain   = var.ses_sending_subdomain
}

# DNS Module
module "dns" {
  source = "./modules/dns"

  domain_name            = var.domain_name
  aws_region             = var.aws_region
  ses_verification_token = module.email_forwarding.ses_verification_token
  dkim_tokens            = module.email_forwarding.dkim_tokens
  github_pages_repo      = var.github_pages_repo

  # Vercel configuration
  vercel_enabled     = var.vercel_enabled
  vercel_subdomain   = var.vercel_subdomain
  vercel_nameservers = var.vercel_nameservers

  # Resend configuration (disabled - migrated to SES)
  resend_enabled   = var.resend_enabled
  resend_subdomain = var.resend_subdomain
  resend_dkim_key  = var.resend_dkim_key

  # SES sending domain configuration
  ses_sending_enabled            = var.ses_sending_enabled
  ses_sending_subdomain          = var.ses_sending_subdomain
  ses_sending_verification_token = module.ses_sending.verification_token
  ses_sending_dkim_tokens        = module.ses_sending.dkim_tokens
}
