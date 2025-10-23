# Deployment Checklist for polarisaistudio.com

Use this checklist to ensure a smooth deployment of the email forwarding infrastructure.

## Pre-Deployment Checks

### AWS Account Setup

- [ ] Verify you have AWS Console access
- [ ] Confirm Route 53 hosted zone exists for `polarisaistudio.com`
  ```bash
  aws route53 list-hosted-zones --query "HostedZones[?Name=='polarisaistudio.com.']"
  ```
- [ ] Check current AWS region supports SES receiving (us-east-1, us-west-2, or eu-west-1)

### IAM User Setup (Follow SETUP.md)

- [ ] Create IAM user: `github-actions`
- [ ] Attach `AdministratorAccess` policy
- [ ] Generate access keys
- [ ] Save credentials in password manager
- [ ] ❌ Do NOT commit credentials to Git

### GitHub Repository Setup

- [ ] Repository created and code pushed
- [ ] Add GitHub Secret: `AWS_ACCESS_KEY_ID`
- [ ] Add GitHub Secret: `AWS_SECRET_ACCESS_KEY`
- [ ] Add GitHub Secret: `AWS_REGION` (e.g., `us-east-1`)
- [ ] Add GitHub Secret: `TF_VARS` (your terraform.tfvars content)
- [ ] Verify secrets are properly masked (check in Settings → Secrets)

### Configuration Files

- [ ] Create `terraform.tfvars` locally (do NOT commit)
- [ ] Set `domain_name = "polarisaistudio.com"`
- [ ] Set `aws_region` to SES-supported region
- [ ] Configure `forward_mapping` with your email addresses
  ```hcl
  forward_mapping = {
    "info"    = "polarisaistudio@gmail.com"
    "contact" = "polarisaistudio@gmail.com"
    "support" = "polarisaistudio@gmail.com"
    "admin"   = "polarisaistudio@gmail.com"
  }
  ```
- [ ] Update `catch_all_forward` if desired (or leave empty)
- [ ] Copy content to GitHub Secret `TF_VARS`

## Deployment Steps

### Local Build Test (Optional but Recommended)

- [ ] Build Lambda function locally
  ```bash
  cd lambda/forwarder
  make clean
  make build
  ls -lh lambda.zip  # Should be ~10MB
  ```
- [ ] Run Terraform validation
  ```bash
  terraform init
  terraform fmt -check
  terraform validate
  ```
- [ ] Run Terraform plan (dry run)
  ```bash
  terraform plan
  ```

### GitHub Actions Deployment

- [ ] Create feature branch
  ```bash
  git checkout -b setup-email-forwarding
  git push origin setup-email-forwarding
  ```
- [ ] Create Pull Request to `main`
- [ ] Verify GitHub Actions workflow runs:
  - [ ] `validate` job passes
  - [ ] `build-lambda` job passes
  - [ ] `plan` job passes
- [ ] Review Terraform plan in PR
- [ ] Verify resources to be created:
  - [ ] 6 DNS records (MX, SPF, SES verification, 3x DKIM, DMARC)
  - [ ] SES domain identity
  - [ ] S3 bucket
  - [ ] Lambda function
  - [ ] IAM role and policies
  - [ ] SES receipt rule set
- [ ] Merge PR to `main`
- [ ] Go to **Actions** tab
- [ ] Find workflow run for `main` branch
- [ ] Click **Review deployments**
- [ ] Select **production** environment
- [ ] Click **Approve and deploy**
- [ ] Monitor `apply` job logs
- [ ] Wait for successful completion

## Post-Deployment Verification

### Check AWS Resources

- [ ] Verify Route 53 records were added
  ```bash
  aws route53 list-resource-record-sets \
    --hosted-zone-id $(aws route53 list-hosted-zones \
    --query "HostedZones[?Name=='polarisaistudio.com.'].Id" \
    --output text)
  ```
- [ ] Check for MX record pointing to SES
- [ ] Check for SPF TXT record
- [ ] Check for 3 DKIM CNAME records
- [ ] Check for DMARC TXT record
- [ ] Verify SES domain identity status
  ```bash
  aws ses get-identity-verification-attributes \
    --identities polarisaistudio.com
  ```
- [ ] Should show `VerificationStatus: "Success"`
- [ ] Check S3 bucket was created
  ```bash
  aws s3 ls | grep ses-email-forwarder
  ```
- [ ] Verify Lambda function deployed
  ```bash
  aws lambda get-function --function-name ses-email-forwarder-forwarder
  ```

### SES Configuration

- [ ] Log into AWS Console → SES
- [ ] Verify domain identity shows "Verified"
- [ ] Check DKIM status shows "Successful"
- [ ] If in **SES Sandbox mode**:
  - [ ] Verify each recipient email address
  - [ ] Check inbox for verification emails
  - [ ] Click verification links
- [ ] Request production access (if needed)
  - [ ] Go to SES → Account dashboard
  - [ ] Click "Request production access"
  - [ ] Fill out the form
  - [ ] Wait for approval (usually 24 hours)

### DNS Propagation

- [ ] Wait ~15 minutes for DNS propagation
- [ ] Verify MX record is live
  ```bash
  dig MX polarisaistudio.com
  ```
  Should show: `10 inbound-smtp.us-east-1.amazonaws.com`
- [ ] Verify SPF record
  ```bash
  dig TXT polarisaistudio.com
  ```
  Should include: `v=spf1 include:amazonses.com ~all`
- [ ] Check DKIM records
  ```bash
  dig TXT _domainkey.polarisaistudio.com
  ```

### Test Email Forwarding

- [ ] Send test email to `info@polarisaistudio.com`
- [ ] Check recipient inbox (the address in your `forward_mapping`)
- [ ] Verify email was forwarded
- [ ] Check email headers to confirm forwarding
- [ ] Test other addresses:
  - [ ] `contact@polarisaistudio.com`
  - [ ] `support@polarisaistudio.com`
  - [ ] `admin@polarisaistudio.com`
- [ ] Test catch-all (if configured)

### Monitor Lambda Logs

- [ ] Check CloudWatch Logs
  ```bash
  aws logs tail /aws/lambda/ses-email-forwarder-forwarder --follow
  ```
- [ ] Look for successful forwarding messages
- [ ] Check for any errors
- [ ] Verify email processing times

## Troubleshooting

If emails are not being forwarded:

### Check SES Receipt Rules

- [ ] AWS Console → SES → Email receiving → Rule sets
- [ ] Verify rule set is active
- [ ] Check rules are enabled
- [ ] Verify Lambda action is configured

### Check Lambda Function

- [ ] View CloudWatch Logs for errors
- [ ] Check Lambda configuration:
  - [ ] Environment variables set correctly
  - [ ] IAM role has proper permissions
  - [ ] Function timeout is sufficient (30 seconds)

### Check S3 Bucket

- [ ] Verify emails are being stored
  ```bash
  aws s3 ls s3://ses-email-forwarder-{account-id}/emails/
  ```
- [ ] Check bucket policy allows SES to write

### Check Email Deliverability

- [ ] Verify recipient email is valid
- [ ] If in sandbox, ensure recipient is verified
- [ ] Check spam/junk folders
- [ ] Review SES sending statistics for bounces

### DNS Issues

- [ ] Ensure MX record priority is 10
- [ ] Verify no conflicting MX records
- [ ] Check SPF record is correctly formatted
- [ ] Ensure DKIM records match SES tokens

## Security Review

- [ ] Access keys are stored in GitHub Secrets (not in code)
- [ ] Secrets are masked in GitHub Actions logs
- [ ] MFA enabled on `github-actions` IAM user (recommended)
- [ ] CloudTrail logging is enabled
- [ ] S3 bucket has encryption enabled
- [ ] S3 bucket blocks public access
- [ ] Lambda has minimal IAM permissions
- [ ] Email retention policy configured (7 days default)

## Maintenance Schedule

- [ ] Set reminder for access key rotation (90 days)
- [ ] Monitor SES sending limits
- [ ] Review CloudWatch Logs monthly
- [ ] Check S3 bucket size monthly
- [ ] Review and update forward_mapping as needed

## Rollback Plan

If you need to destroy the infrastructure:

- [ ] Ensure you have backups of any important emails
- [ ] Run in GitHub Actions:
  - Manual workflow trigger with destroy flag
- [ ] Or run locally:
  ```bash
  terraform destroy
  ```
- [ ] Verify resources are deleted:
  - [ ] DNS records removed from Route 53
  - [ ] SES domain identity deleted
  - [ ] S3 bucket deleted (or emptied)
  - [ ] Lambda function deleted
  - [ ] IAM roles deleted

## Success Criteria

All of the following should be true:

✅ GitHub Actions workflow completes successfully
✅ All AWS resources created
✅ DNS records visible in Route 53
✅ SES domain verified
✅ Test emails forwarded successfully
✅ Lambda logs show no errors
✅ Recipient receives forwarded emails
✅ Email headers show proper DKIM/SPF

## Next Steps After Deployment

1. Document your email forwarding addresses
2. Share instructions with team members
3. Set up monitoring alerts (optional)
4. Consider setting up SES sending statistics dashboard
5. Plan for scaling if email volume increases

---

**Deployment Date**: ******\_\_\_******
**Deployed By**: ******\_\_\_******
**Environment**: Production
**Domain**: polarisaistudio.com
**Region**: ******\_\_\_******
