# SES Email Verification Guide

## The Problem

You're seeing this error when emails are forwarded:

```
MessageRejected: Email address is not verified.
The following identities failed the check in region US-WEST-2:
<kex.allen13@gmail.com>, polarisaistudio@gmail.com
```

## Why This Happens

AWS SES starts in **sandbox mode** for security. In sandbox mode:
- ✅ You can send emails FROM verified addresses
- ✅ You can send emails TO verified addresses only
- ❌ You cannot send to unverified email addresses
- ❌ You cannot send more than 200 emails/day
- ❌ You cannot send more than 1 email/second

## Current Status

Your SES setup:
- **Domain verified**: ✅ `polarisaistudio.com`
- **From address**: ✅ `noreply@polarisaistudio.com` (uses verified domain)
- **To addresses**: ❓ Need verification (sandbox mode)

## Solution: Verify Email Addresses

### Step 1: Check Your Email

When Terraform created the email identities, AWS sent verification emails to:
- `polarisaistudio@gmail.com`

**Check these inboxes** for emails from:
- **From**: `no-reply-aws@amazon.com`
- **Subject**: "Amazon SES Email Address Verification Request in region..."

### Step 2: Click Verification Links

Open each verification email and click the verification link. You'll see a confirmation page:

```
Congratulations!
You have successfully verified an email address with Amazon SES.
```

### Step 3: Verify Status

Check if emails are verified:

```bash
# Check all verified email identities
aws sesv2 list-email-identities --region us-west-2

# Check specific email verification status
aws sesv2 get-email-identity \
  --email-identity polarisaistudio@gmail.com \
  --region us-west-2
```

Look for `"VerificationStatus": "SUCCESS"`

### Step 4: Test Email Forwarding

Once verified, send a test email to any of your configured addresses:
- `info@polarisaistudio.com`
- `contact@polarisaistudio.com`
- `support@polarisaistudio.com`
- `admin@polarisaistudio.com`

All should forward to `polarisaistudio@gmail.com`.

---

## Long-Term Solution: Move Out of Sandbox

### Option A: Request Production Access (Recommended)

**Benefits:**
- Send to ANY email address (no verification needed)
- Higher sending limits (50,000 emails/day initially)
- Better deliverability

**How to Request:**

1. **Go to AWS Console** → SES → Account dashboard
2. **Click "Request production access"**
3. **Fill out the form:**
   - **Use case**: Email forwarding service for custom domain
   - **Expected sending volume**: Low (< 100 emails/day)
   - **Bounce/complaint handling**: Automatic via SES configuration
   - **Email content**: Forwarding legitimate emails received at custom domain

4. **Submit request**
   - Usually approved within 24 hours
   - AWS may ask follow-up questions

5. **Wait for approval email**

### Option B: Stay in Sandbox (For Testing)

If you're just testing or only forwarding to a few known addresses:

1. **Manually verify each recipient** via AWS Console or CLI
2. **Accept the 200/day limit**
3. **Move to production later** when ready

---

## Manual Verification via AWS Console

If you didn't receive the verification emails:

### Steps:

1. **Go to AWS Console** → SES (us-west-2 region)
2. **Click "Verified identities"** in left sidebar
3. **Find your email** (e.g., `polarisaistudio@gmail.com`)
4. **Check status**:
   - ✅ Green checkmark = Verified
   - ⏳ Pending = Check email for verification link
   - ❌ Failed = Need to resend verification

5. **To resend verification**:
   - Select the email identity
   - Click "Send verification email again"

---

## Adding More Forward Addresses

If you want to forward to multiple email addresses, you need to verify each one.

### Update Terraform

Edit `variables.tf`:

```hcl
variable "forward_mapping" {
  default = {
    "info"    = "polarisaistudio@gmail.com"
    "contact" = "polarisaistudio@gmail.com"
    "support" = "team@example.com"          # New address
    "admin"   = "admin@example.com"         # New address
  }
}
```

### Apply Changes

```bash
terraform apply
```

Terraform will create new email identities. Check the email inboxes for verification links.

---

## Troubleshooting

### Verification Email Not Received

**Check spam folder** - AWS verification emails sometimes go to spam.

**Resend verification:**
```bash
aws sesv2 create-email-identity \
  --email-identity your-email@example.com \
  --region us-west-2
```

### Email Already Verified But Still Failing

**Check the region** - Email identities are region-specific. Ensure you're verifying in `us-west-2`.

```bash
# List all regions with SES identities
for region in us-east-1 us-west-2 eu-west-1; do
  echo "Region: $region"
  aws sesv2 list-email-identities --region $region
done
```

### "Email address is not verified" for Sender

The error mentions `<kex.allen13@gmail.com>` - this is likely the original sender.

**This is expected** - you don't need to verify the original sender. The error occurs because SES is trying to preserve the original From header, but that fails in sandbox mode.

**Solution**: The Lambda should already be setting `FROM_EMAIL` to `noreply@polarisaistudio.com`. Verify this in CloudWatch Logs:

```bash
aws logs tail /aws/lambda/ses-email-forwarder-forwarder \
  --region us-west-2 \
  --follow
```

---

## Quick Commands Reference

### Check Verification Status
```bash
aws sesv2 list-email-identities --region us-west-2
```

### Get Detailed Status
```bash
aws sesv2 get-email-identity \
  --email-identity polarisaistudio@gmail.com \
  --region us-west-2
```

### Check SES Account Status (Sandbox vs Production)
```bash
aws sesv2 get-account --region us-west-2
```

Look for:
```json
{
  "ProductionAccessEnabled": false  // Still in sandbox
}
```

### Request Production Access (CLI)
```bash
aws sesv2 put-account-details \
  --region us-west-2 \
  --mail-type TRANSACTIONAL \
  --website-url https://polarisaistudio.com \
  --use-case-description "Email forwarding service for custom domain"
```

---

## Expected Timeline

### Immediate Actions (5 minutes)
1. Check email inbox for verification emails
2. Click verification links
3. Confirm verification status
4. Test email forwarding

### Short Term (24-48 hours)
1. Request production access if needed
2. Wait for AWS approval
3. Test with any email address

### Production Ready
- ✅ No verification needed for recipients
- ✅ 50,000+ emails per day
- ✅ Professional email forwarding service

---

## Summary

**Right now:**
1. Check `polarisaistudio@gmail.com` inbox
2. Click the AWS SES verification link
3. Confirm verification succeeded
4. Test email forwarding again

**For production use:**
1. Request production access via AWS Console
2. Wait for approval (usually < 24 hours)
3. Send to any email address without verification

**Questions?**
- Check AWS SES Console → Account dashboard for current status
- Review CloudWatch Logs for Lambda execution details
- Verify all DNS records are properly configured in Route 53
