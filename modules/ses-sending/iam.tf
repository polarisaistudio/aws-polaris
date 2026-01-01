# IAM User for Application SES Access
# Creates a dedicated IAM user for the AMS Training application to send emails via SES

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM user for application SES access
resource "aws_iam_user" "ses_sender" {
  name = "ams-training-ses-sender"
  path = "/service-accounts/"

  tags = {
    Purpose = "SES email sending for AMS Training application"
    Domain  = "${var.subdomain}.${var.domain_name}"
  }
}

# IAM policy for sending emails - scoped to specific identity
resource "aws_iam_user_policy" "ses_sender" {
  name = "ses-send-email"
  user = aws_iam_user.ses_sender.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSendEmail"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        # Restrict to specific domain identity
        Resource = "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.subdomain}.${var.domain_name}"
      },
      {
        Sid    = "AllowSendFromAddress"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "ses:FromAddress" = "*@${var.subdomain}.${var.domain_name}"
          }
        }
      }
    ]
  })
}

# Access key for the IAM user
resource "aws_iam_access_key" "ses_sender" {
  user = aws_iam_user.ses_sender.name
}

# Outputs for application configuration
output "ses_access_key_id" {
  description = "AWS Access Key ID for SES sending"
  value       = aws_iam_access_key.ses_sender.id
  sensitive   = false
}

output "ses_secret_access_key" {
  description = "AWS Secret Access Key for SES sending (sensitive)"
  value       = aws_iam_access_key.ses_sender.secret
  sensitive   = true
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.ses_sender.arn
}
