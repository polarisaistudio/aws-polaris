# Email Forwarding Module - SES, S3, Lambda, IAM

data "aws_caller_identity" "current" {}

# ==============================================================================
# SES Configuration
# ==============================================================================

resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_ses_domain_identity_verification" "main" {
  domain     = aws_ses_domain_identity.main.id
  depends_on = [aws_ses_domain_identity.main]
}

resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = var.ses_rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
}

resource "aws_ses_receipt_rule" "forward" {
  name          = "forward-emails"
  rule_set_name = aws_ses_receipt_rule_set.main.rule_set_name
  recipients    = [var.domain_name]
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = aws_s3_bucket.emails.id
    object_key_prefix = "emails/"
    position          = 1
  }

  lambda_action {
    function_arn    = module.forwarder_lambda.function_arn
    invocation_type = "Event"
    position        = 2
  }

  depends_on = [
    aws_s3_bucket_policy.emails,
    aws_lambda_permission.ses
  ]
}

resource "aws_ses_email_identity" "from" {
  for_each = toset(distinct([for addr in values(var.forward_mapping) : addr]))
  email    = each.value
}

# ==============================================================================
# S3 Bucket for Email Storage
# ==============================================================================

resource "aws_s3_bucket" "emails" {
  bucket = "${var.s3_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "emails" {
  bucket = aws_s3_bucket.emails.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "emails" {
  bucket = aws_s3_bucket.emails.id

  rule {
    id     = "delete-old-emails"
    status = "Enabled"

    filter {
      prefix = "emails/"
    }

    expiration {
      days = var.email_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "emails" {
  bucket                  = aws_s3_bucket.emails.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "emails" {
  bucket = aws_s3_bucket.emails.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSESPuts"
      Effect = "Allow"
      Principal = {
        Service = "ses.amazonaws.com"
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.emails.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        StringLike = {
          "AWS:SourceArn" = "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${var.ses_rule_set_name}:receipt-rule/*"
        }
      }
    }]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "emails" {
  bucket = aws_s3_bucket.emails.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==============================================================================
# Lambda Function (using reusable module)
# ==============================================================================

module "forwarder_lambda" {
  source = "../lambda"

  function_name = "${var.s3_bucket_prefix}-forwarder"
  source_dir    = "lambda/forwarder"
  runtime       = "provided.al2023"
  architecture  = "arm64"
  timeout       = 30
  memory_size   = 256

  environment_variables = {
    FORWARD_MAPPING   = jsonencode(var.forward_mapping)
    CATCH_ALL_FORWARD = var.catch_all_forward
    FROM_EMAIL        = var.from_email
    DOMAIN_NAME       = var.domain_name
    S3_BUCKET         = aws_s3_bucket.emails.id
    S3_PREFIX         = "emails/"
    PRESERVE_REPLY_TO = var.preserve_reply_to ? "true" : "false"
  }

  iam_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:DeleteObject"
      ]
      resources = ["${aws_s3_bucket.emails.arn}/*"]
    },
    {
      effect = "Allow"
      actions = [
        "ses:SendRawEmail",
        "ses:SendEmail"
      ]
      resources = ["*"]
    }
  ]

  cloudwatch_retention_days = 7
  tags                      = var.tags
}

resource "aws_lambda_permission" "ses" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = module.forwarder_lambda.function_name
  principal      = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}
