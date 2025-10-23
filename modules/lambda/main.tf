# Reusable Lambda Module

# ==============================================================================
# IAM Role for Lambda
# ==============================================================================

resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_additional" {
  count = length(var.iam_policy_statements) > 0 ? 1 : 0
  name  = "additional-permissions"
  role  = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for stmt in var.iam_policy_statements : {
        Effect   = stmt.effect
        Action   = stmt.actions
        Resource = stmt.resources
      }
    ]
  })
}

# ==============================================================================
# Lambda Function Build and Deployment
# ==============================================================================

# Build the Lambda function using local-exec
# Always rebuild to ensure latest code is deployed
resource "null_resource" "lambda_build" {
  triggers = {
    # Always rebuild - use timestamp to force rebuild on every apply
    always_build = timestamp()
  }

  provisioner "local-exec" {
    command     = var.build_command
    working_dir = "${path.root}/${var.source_dir}"
  }
}

# Use the ZIP file created by the build command
locals {
  lambda_zip_path = "${path.root}/${var.source_dir}/lambda.zip"
}

# Archive data source to get the hash
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/${var.source_dir}/bootstrap"
  output_path = local.lambda_zip_path

  depends_on = [null_resource.lambda_build]
}

# Deploy the Lambda function
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.runtime
  architectures    = [var.architecture]
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = var.environment_variables
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.lambda_additional,
    null_resource.lambda_build,
  ]

  lifecycle {
    # Ensure the build happens before deployment
    replace_triggered_by = [
      null_resource.lambda_build,
    ]
  }
}

# ==============================================================================
# CloudWatch Logs
# ==============================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = var.cloudwatch_retention_days
  tags              = var.tags
}
