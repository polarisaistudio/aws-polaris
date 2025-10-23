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

# DNS Module
module "dns" {
  source = "./modules/dns"

  domain_name            = var.domain_name
  aws_region             = var.aws_region
  ses_verification_token = module.email_forwarding.ses_verification_token
  dkim_tokens            = module.email_forwarding.dkim_tokens
  github_pages_repo      = var.github_pages_repo
}
