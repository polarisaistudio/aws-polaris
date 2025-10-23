# AWS Email Forwarding with Route 53 and SES

This Terraform project sets up automated email forwarding for a custom domain using AWS Route 53, SES, S3, and a Go-based Lambda function.

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Choose your deployment method (GitHub Actions, local, or GitLab)
- **[SETUP.md](SETUP.md)** - Complete GitHub Actions setup guide with AWS IAM configuration
- **[GITHUB-PAGES-SETUP.md](GITHUB-PAGES-SETUP.md)** - Configure custom domain for GitHub Pages
- **[README.md](README.md)** - This file: Architecture, features, and local deployment guide

## Architecture

```
┌─────────────────┐
│  Email Sender   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────┐
│   Route 53 MX   │─────▶│  Amazon SES  │
│     Records     │      │   (Receive)  │
└─────────────────┘      └──────┬───────┘
                                │
                    ┌───────────┴──────────┐
                    │                      │
                    ▼                      ▼
            ┌───────────────┐      ┌─────────────┐
            │   S3 Bucket   │      │   Lambda    │
            │ (Email Store) │◀─────│  (Forward)  │
            └───────────────┘      └──────┬──────┘
                                          │
                                          ▼
                                  ┌───────────────┐
                                  │  Amazon SES   │
                                  │    (Send)     │
                                  └───────┬───────┘
                                          │
                                          ▼
                                  ┌───────────────┐
                                  │   Recipient   │
                                  └───────────────┘
```

## Features

### Email Forwarding

- Custom domain email forwarding (e.g., `info@polarisaistudio.com` → `polarisaistudio@gmail.com`)
- Multiple email address mapping support
- Optional catch-all forwarding
- Automatic DNS configuration (MX, SPF, DKIM, DMARC)
- Email storage with automatic cleanup
- Go-based Lambda function for efficient processing
- Full email header preservation
- DKIM signing for deliverability

### GitHub Pages Integration

- Apex domain (polarisaistudio.com) points to GitHub Pages
- WWW subdomain (www.polarisaistudio.com) with automatic redirect
- IPv4 and IPv6 support
- HTTPS/SSL via GitHub Pages
- Email and web services on the same domain (no conflicts!)

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Domain name** that you control (this project uses existing Route 53 hosted zone: `polarisaistudio.com`)
3. **Terraform** >= 1.0
4. **Go** >= 1.21 (for building the Lambda function)
5. **Make** (for building the Lambda function)

**Note**: This configuration uses an **existing Route 53 hosted zone** for `polarisaistudio.com`. The Terraform code will NOT create a new hosted zone, but will add DNS records to the existing zone.

## Configuration

### 1. Create a `terraform.tfvars` file

```hcl
domain_name = "polarisaistudio.com"
aws_region  = "us-east-1"  # Must be us-east-1, us-west-2, or eu-west-1

forward_mapping = {
  "info"    = "polarisaistudio@gmail.com"
  "contact" = "polarisaistudio@gmail.com"
  "support" = "polarisaistudio@gmail.com"
  "admin"   = "polarisaistudio@gmail.com"
}

# Optional: Catch-all forwarding
catch_all_forward = "catch-all@gmail.com"

# Optional: Custom from address
from_email = "noreply@example.com"

# Optional: Email retention in S3
email_retention_days = 7

# Optional: Tags
tags = {
  Environment = "production"
  Project     = "EmailForwarding"
  ManagedBy   = "Terraform"
}
```

### 2. Variable Descriptions

| Variable               | Description                                     | Default          | Required |
| ---------------------- | ----------------------------------------------- | ---------------- | -------- |
| `domain_name`          | Your custom domain (e.g., example.com)          | -                | Yes      |
| `aws_region`           | AWS region (us-east-1, us-west-2, or eu-west-1) | us-east-1        | No       |
| `forward_mapping`      | Map of local parts to forward-to addresses      | See example      | Yes      |
| `catch_all_forward`    | Email address for unmatched recipients          | ""               | No       |
| `from_email`           | Sender address for forwarded emails             | noreply@{domain} | No       |
| `github_pages_repo`    | GitHub Pages repo (e.g., user.github.io)        | ""               | No       |
| `email_retention_days` | Days to keep emails in S3                       | 7                | No       |

## Deployment

### Step 1: Initialize Terraform

```bash
terraform init
```

### Step 2: Review the Plan

```bash
terraform plan
```

### Step 3: Apply the Configuration

```bash
terraform apply
```

### Step 4: Update Domain Nameservers

After `terraform apply`, you'll see the Route 53 nameservers in the output:

```
nameservers = [
  "ns-123.awsdns-12.com",
  "ns-456.awsdns-34.net",
  "ns-789.awsdns-56.org",
  "ns-012.awsdns-78.co.uk"
]
```

**Update your domain registrar** to use these nameservers. This may take 24-48 hours to propagate.

### Step 5: Verify SES Email Addresses (Sandbox Mode)

If your AWS account is in SES sandbox mode, you need to verify recipient email addresses:

1. Go to AWS Console → SES → Verified identities
2. Click "Create identity"
3. Choose "Email address"
4. Enter each recipient email from your `forward_mapping`
5. Check the recipient's inbox and click the verification link

### Step 6: Request Production Access (Optional)

To send emails to any address without verification:

1. Go to AWS Console → SES
2. Click "Get started" or "Request production access"
3. Fill out the form explaining your use case
4. AWS typically approves within 24 hours

## Testing

### Send a Test Email

Once nameservers have propagated and SES is verified:

```bash
# Send to a mapped address
echo "Test email body" | mail -s "Test Subject" info@yourdomain.com

# If catch-all is configured
echo "Test email body" | mail -s "Test Subject" anything@yourdomain.com
```

### Check Lambda Logs

```bash
aws logs tail /aws/lambda/ses-email-forwarder-forwarder --follow
```

### Check S3 Bucket

```bash
terraform output s3_bucket_name
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/emails/
```

## DNS Records Created

The following DNS records are automatically created:

1. **MX Record**: Points to AWS SES inbound mail servers
2. **TXT (SPF)**: Authorizes AWS SES to send mail for your domain
3. **TXT (Domain Verification)**: Verifies domain ownership with SES
4. **CNAME (DKIM)**: Three records for email authentication
5. **TXT (DMARC)**: Policy for handling failed authentication

## How It Works

1. Email arrives at your domain (e.g., `info@yourdomain.com`)
2. MX records route it to AWS SES
3. SES receipt rule stores the email in S3
4. SES receipt rule triggers Lambda function
5. Lambda reads email from S3
6. Lambda looks up recipient in `forward_mapping`
7. Lambda sends email via SES to the mapped address
8. S3 lifecycle policy deletes email after retention period

## Lambda Function

The Go Lambda function (`lambda/forwarder/main.go`) handles:

- Reading emails from S3
- Parsing SES event notifications
- Mapping recipients based on configuration
- Preserving email headers and content
- Forwarding via SES SendRawEmail API
- Adding X-Forwarded-To and X-Original-To headers

## Cost Estimate

Assuming 1,000 emails/month:

- **Route 53 Hosted Zone**: $0.50/month
- **SES Receiving**: $0.10 per 1,000 emails = $0.10
- **SES Sending**: $0.10 per 1,000 emails = $0.10
- **S3 Storage**: ~$0.01 (with 7-day retention)
- **Lambda**: Free tier covers most usage
- **CloudWatch Logs**: ~$0.01

**Total**: ~$0.72/month

## Troubleshooting

### Emails Not Being Received

1. Check nameserver propagation:

   ```bash
   dig NS yourdomain.com
   dig MX yourdomain.com
   ```

2. Verify SES domain:

   ```bash
   aws ses get-identity-verification-attributes --identities yourdomain.com
   ```

3. Check SES receipt rules:
   ```bash
   aws ses describe-active-receipt-rule-set
   ```

### Emails Not Being Forwarded

1. Check Lambda logs:

   ```bash
   aws logs tail /aws/lambda/ses-email-forwarder-forwarder --follow
   ```

2. Verify recipient email addresses (if in sandbox)

3. Check S3 bucket for stored emails

### Email Goes to Spam

1. Ensure DKIM records are properly configured
2. Wait for DNS propagation (up to 48 hours)
3. Check SPF and DMARC records
4. Consider requesting production SES access

## Updating Configuration

To update forwarding rules:

1. Edit `terraform.tfvars`
2. Run `terraform apply`
3. Lambda will automatically use new configuration

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: Ensure S3 bucket is empty or use `-auto-approve` flag.

## Security Considerations

- Emails are encrypted at rest in S3 (AES-256)
- S3 bucket has public access blocked
- Lambda has minimal IAM permissions (least privilege)
- Emails are automatically deleted after retention period
- DKIM signing prevents spoofing

## License

MIT

## Support

For issues or questions:

1. Check CloudWatch logs for Lambda errors
2. Verify SES sending statistics in AWS Console
3. Review Terraform state for configuration issues
