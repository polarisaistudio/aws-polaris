# Local Terraform Deployment Guide

This guide shows you how to deploy the email forwarding infrastructure locally from your machine instead of using GitHub Actions.

## Prerequisites

Before you start, ensure you have:

- ✅ **AWS CLI** configured with credentials
- ✅ **Terraform** >= 1.0 installed
- ✅ **Go** >= 1.21 installed
- ✅ **Make** installed
- ✅ AWS IAM user with AdministratorAccess (or sufficient permissions)

## Quick Start

All production-ready values for `polarisaistudio.com` are **already set as defaults in `variables.tf`**. You don't need a `terraform.tfvars` file!

### Step 1: Configure AWS Credentials

Ensure your AWS credentials are configured:

```bash
aws configure
```

Enter your:

- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

**Verify it works:**

```bash
aws sts get-caller-identity
```

### Step 2: Build the Lambda Function

```bash
cd lambda/forwarder
make clean
make build
cd ../..
```

**Verify the build:**

```bash
ls -lh lambda/forwarder/lambda.zip
# Should show ~10MB file
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads the required provider plugins.

### Step 4: Validate Configuration

```bash
terraform fmt -check
terraform validate
```

### Step 5: Review the Plan

**IMPORTANT**: Always review what Terraform will create before applying!

```bash
terraform plan
```

You should see it will create:

- DNS records (MX, SPF, DKIM, DMARC, A, AAAA, CNAME)
- SES domain identity
- SES receipt rule set and rules
- S3 bucket for email storage
- Lambda function
- IAM role and policies
- CloudWatch log group

### Step 6: Apply (Deploy)

**When you're ready to deploy:**

```bash
terraform apply
```

Type `yes` when prompted.

Deployment takes about 5-10 minutes.

### Step 7: Verify Deployment

After successful apply, check the outputs:

```bash
terraform output
```

You should see:

- `hosted_zone_id`: Your Route 53 zone ID
- `nameservers`: DNS nameservers (already configured)
- `domain_name`: polarisaistudio.com
- `ses_verification_token`: SES verification token
- `dkim_tokens`: 3 DKIM tokens
- `s3_bucket_name`: Email storage bucket
- `lambda_function_name`: Forwarder function name

## Configuration Review

The default configuration in `variables.tf` is set to:

```hcl
domain_name = "polarisaistudio.com"
aws_region  = "us-east-1"

forward_mapping = {
  "info"    = "polarisaistudio@gmail.com"
  "contact" = "polarisaistudio@gmail.com"
  "support" = "polarisaistudio@gmail.com"
  "admin"   = "polarisaistudio@gmail.com"
}

catch_all_forward = ""
from_email = "noreply@polarisaistudio.com"
github_pages_repo = "polarisaistudio.github.io"
email_retention_days = 7
s3_bucket_prefix = "ses-email-forwarder"
ses_rule_set_name = "email-forwarding-rules"

tags = {
  Environment = "production"
  Project     = "EmailForwarding"
  ManagedBy   = "Terraform"
  Domain      = "polarisaistudio.com"
}
```

**To override any value**, create a `terraform.tfvars` file or use `-var` flags:

```bash
terraform apply -var="domain_name=other.com"
```

## What Gets Created

### DNS Records in Route 53 (existing zone)

- **MX**: Email routing to SES
- **SPF**: Email authentication
- **SES Verification**: Domain verification
- **DKIM** (3 records): Email signing
- **DMARC**: Email policy
- **A** (4 records): GitHub Pages IPv4
- **AAAA** (4 records): GitHub Pages IPv6
- **CNAME**: www subdomain to GitHub Pages

### Email Infrastructure

- **SES Domain Identity**: polarisaistudio.com
- **S3 Bucket**: Email storage with 7-day retention
- **Lambda Function**: Go-based email forwarder
- **IAM Role**: Lambda execution permissions
- **Receipt Rules**: Email processing workflow

## Post-Deployment Steps

### 1. Verify SES Domain

```bash
aws ses get-identity-verification-attributes \
  --identities polarisaistudio.com
```

Should show `VerificationStatus: "Success"`

### 2. Check DNS Records

```bash
dig MX polarisaistudio.com
dig TXT polarisaistudio.com
dig A polarisaistudio.com
```

### 3. Verify Recipient Email (if in SES Sandbox)

If your AWS account is in SES sandbox mode:

1. Go to AWS Console → SES → Verified identities
2. Click "Create identity" → Email address
3. Enter: `polarisaistudio@gmail.com`
4. Check inbox and verify

### 4. Test Email Forwarding

Send a test email to:

```
info@polarisaistudio.com
```

Check `polarisaistudio@gmail.com` inbox.

### 5. Configure GitHub Pages

Follow [GITHUB-PAGES-SETUP.md](GITHUB-PAGES-SETUP.md) to:

- Set custom domain in GitHub Pages
- Enable HTTPS
- Test web traffic

### 6. Request SES Production Access

To send to any email (not just verified):

1. AWS Console → SES → Account dashboard
2. Click "Request production access"
3. Fill out the form
4. Wait for approval (~24 hours)

## Common Commands

### View Current State

```bash
terraform show
```

### List Resources

```bash
terraform state list
```

### Refresh Outputs

```bash
terraform output
```

### Update Infrastructure

```bash
# After making changes
terraform plan
terraform apply
```

### Destroy Everything

```bash
terraform destroy
```

⚠️ **Warning**: This will delete all resources!

## Troubleshooting

### "Error: Hosted zone not found"

**Problem**: Route 53 hosted zone doesn't exist

**Solution**:

```bash
# Verify zone exists
aws route53 list-hosted-zones --query "HostedZones[?Name=='polarisaistudio.com.']"
```

### "Error: Access Denied"

**Problem**: AWS credentials don't have permissions

**Solution**:

- Verify credentials: `aws sts get-caller-identity`
- Check IAM user has AdministratorAccess
- Run `aws configure` to update credentials

### "Error: Resource already exists"

**Problem**: Resources already created (maybe by GitHub Actions)

**Solution**:

```bash
# Import existing resources or destroy via GitHub Actions first
terraform import aws_route53_record.mx <zone-id>_polarisaistudio.com_MX
```

Or coordinate with GitHub Actions deployment.

### Lambda Build Fails

**Problem**: Go build errors

**Solution**:

```bash
cd lambda/forwarder
go mod tidy
make clean
make build
```

### DNS Records Don't Propagate

**Problem**: Changes not visible

**Solution**:

- Wait 5-15 minutes for Route 53 propagation
- Check with different DNS servers:
  ```bash
  dig @8.8.8.8 MX polarisaistudio.com
  dig @1.1.1.1 MX polarisaistudio.com
  ```

## State Management

### Local State

By default, Terraform stores state locally in `terraform.tfstate`.

**Important**:

- ✅ State file is in `.gitignore`
- ❌ Don't commit state files
- ✅ Back up state files regularly
- ⚠️ Coordinate with GitHub Actions to avoid conflicts

### Remote State (Optional)

To share state with GitHub Actions, configure S3 backend in `versions.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "email-forwarder/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-email-forwarder"
  }
}
```

See SETUP.md Step 5 for details.

## Best Practices

### Before Applying

- ✅ Always run `terraform plan` first
- ✅ Review all changes carefully
- ✅ Ensure Lambda is built
- ✅ Verify AWS credentials

### During Development

- ✅ Use `terraform fmt` to format code
- ✅ Run `terraform validate` before committing
- ✅ Test changes in a separate AWS account first
- ✅ Keep `terraform.tfvars` backed up (not in Git!)

### After Applying

- ✅ Verify all resources are working
- ✅ Test email forwarding
- ✅ Check CloudWatch logs
- ✅ Monitor AWS costs

## Cost Monitoring

```bash
# Check S3 bucket size
aws s3 ls s3://ses-email-forwarder-<account-id>/emails/ --summarize --human-readable --recursive

# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=ses-email-forwarder-forwarder \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum
```

## Security Notes

### Credentials

- ✅ `terraform.tfvars` is protected by `.gitignore`
- ✅ Never commit AWS credentials
- ✅ Use AWS CLI profiles for multiple accounts
- ✅ Rotate access keys regularly

### State Files

- ⚠️ State files contain sensitive data
- ✅ Store securely (encrypted S3 bucket)
- ❌ Never commit to Git
- ✅ Restrict access to state storage

## Comparison: Local vs GitHub Actions

| Aspect        | Local Deployment             | GitHub Actions                 |
| ------------- | ---------------------------- | ------------------------------ |
| Setup         | Quick, immediate             | Requires secrets configuration |
| Security      | Credentials on local machine | Credentials in GitHub Secrets  |
| CI/CD         | Manual deployment            | Automated on push/PR           |
| State         | Local file                   | Remote (S3) recommended        |
| Collaboration | Single developer             | Team-friendly                  |
| Audit Trail   | Local logs                   | GitHub workflow logs           |

## Next Steps

After successful local deployment:

1. ✅ Verify all DNS records in Route 53
2. ✅ Test email forwarding
3. ✅ Configure GitHub Pages custom domain
4. ✅ Request SES production access
5. ✅ Set up monitoring/alerts (optional)
6. ✅ Consider migrating to GitHub Actions for CI/CD

## Support

- Email issues: Check CloudWatch Logs for Lambda
- DNS issues: Use `dig` command to verify records
- Terraform issues: Run with `-debug` flag
- AWS issues: Check CloudTrail for API calls

---

**Ready to deploy?**

```bash
# Review one more time
terraform plan

# Deploy when ready
terraform apply
```

🚀 Good luck!
