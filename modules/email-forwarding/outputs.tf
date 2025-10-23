output "ses_verification_token" {
  description = "SES domain verification token"
  value       = aws_ses_domain_identity.main.verification_token
}

output "dkim_tokens" {
  description = "DKIM tokens for email authentication"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

output "s3_bucket_name" {
  description = "S3 bucket used for email storage"
  value       = aws_s3_bucket.emails.id
}

output "lambda_function_name" {
  description = "Name of the Lambda function handling email forwarding"
  value       = module.forwarder_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.forwarder_lambda.function_arn
}

output "ses_rule_set_name" {
  description = "Name of the active SES receipt rule set"
  value       = aws_ses_receipt_rule_set.main.rule_set_name
}

output "email_identities_requiring_verification" {
  description = "Email addresses that need to be verified in SES (check inbox for verification emails)"
  value       = [for addr in values(var.forward_mapping) : addr]
}

output "verification_instructions" {
  description = "Instructions for verifying email addresses"
  value       = <<-EOT

    ⚠️  EMAIL VERIFICATION REQUIRED ⚠️

    AWS SES is in SANDBOX mode. To receive forwarded emails, verify these addresses:
    ${join("\n    ", [for addr in distinct(values(var.forward_mapping)) : "- ${addr}"])}

    Steps:
    1. Check the inbox for each email address above
    2. Look for email from: no-reply-aws@amazon.com
    3. Click the verification link in each email
    4. Confirm you see "Successfully verified" message

    To check verification status:
    aws sesv2 list-email-identities --region ${var.aws_region}

    For production use (no verification needed):
    - Request production access: AWS Console → SES → Account dashboard
    - See SES-VERIFICATION.md for detailed instructions
  EOT
}
