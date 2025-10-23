# Recent Changes - Email Forwarding Fix

## Problem: Email Forwarding Stopped Working

After adding Reply-To header preservation, emails were no longer being forwarded.

### Error Message
```
MessageRejected: Email address is not verified.
The following identities failed the check in region US-WEST-2:
<sender@example.com>
```

### Root Cause

**AWS SES Sandbox Mode Limitation:**
- SES sandbox mode validates ALL email addresses in headers (From, To, Reply-To, CC, BCC)
- We added `Reply-To: original-sender@example.com` to preserve the original sender
- SES tried to verify the Reply-To address and rejected the email
- This is a sandbox mode limitation, not a code bug

## Solution Implemented

### 1. Added Conditional Reply-To Header

**New Environment Variable: `PRESERVE_REPLY_TO`**
- `false` (default) - Works in SES sandbox mode, no Reply-To header
- `true` - Requires SES production mode, adds Reply-To header

### 2. Lambda Function Changes

**File: `lambda/forwarder/main.go`**

Added configuration:
```go
type Config struct {
    // ... existing fields
    PreserveReplyTo bool // Whether to preserve Reply-To
}
```

Added environment variable parsing:
```go
preserveReplyTo := os.Getenv("PRESERVE_REPLY_TO")
appConfig.PreserveReplyTo = preserveReplyTo == "true"
```

Updated header logic:
```go
// Only add Reply-To if enabled (requires SES production mode)
if !hasReplyTo && appConfig.PreserveReplyTo {
    newHeaders = append(newHeaders, fmt.Sprintf("Reply-To: %s", originalFrom))
    log.Printf("Added Reply-To: %s", originalFrom)
} else if !appConfig.PreserveReplyTo {
    log.Printf("Skipping Reply-To (SES sandbox mode) - original sender: %s", originalFrom)
}
```

### 3. Terraform Configuration

**Added Variable: `preserve_reply_to`**

**File: `variables.tf`**
```hcl
variable "preserve_reply_to" {
  description = "Preserve Reply-To header with original sender (requires SES production mode, not sandbox). Set to true after getting SES production access."
  type        = bool
  default     = false  # Safe for sandbox mode
}
```

**File: `main.tf`**
```hcl
module "email_forwarding" {
  # ... other variables
  preserve_reply_to = var.preserve_reply_to
}
```

**File: `modules/email-forwarding/main.tf`**
```hcl
environment_variables = {
  # ... other variables
  PRESERVE_REPLY_TO = var.preserve_reply_to ? "true" : "false"
}
```

## How It Works Now

### Sandbox Mode (Current - Default)

**Configuration:**
```hcl
preserve_reply_to = false  # default
```

**Email Headers:**
```
From: noreply@polarisaistudio.com
To: polarisaistudio@gmail.com
Subject: Original subject
X-Original-From: sender@example.com        ← Original sender here
X-Original-To: info@polarisaistudio.com
X-Forwarded-By: AWS-SES-Forwarder

[NO Reply-To header - avoids SES sandbox validation error]
```

**User Experience:**
- ✅ Emails are forwarded successfully
- ✅ Original sender preserved in X-Original-From header
- ❌ Reply goes to noreply@polarisaistudio.com (not useful)
- ⚠️ Must manually check X-Original-From to see who sent it

### Production Mode (After SES Approval)

**Configuration:**
```hcl
preserve_reply_to = true
```

**Email Headers:**
```
From: noreply@polarisaistudio.com
Reply-To: sender@example.com               ← Reply goes here!
To: polarisaistudio@gmail.com
Subject: Original subject
X-Original-From: sender@example.com
X-Original-To: info@polarisaistudio.com
X-Forwarded-By: AWS-SES-Forwarder
```

**User Experience:**
- ✅ Emails are forwarded successfully
- ✅ Original sender preserved in Reply-To header
- ✅ Click "Reply" → goes to original sender automatically
- ✅ Natural email workflow (appears to come from original sender)

## Deployment Instructions

### Deploy the Fix (Now)

```bash
# Rebuild Lambda with sandbox mode support
cd lambda/forwarder
make build

# Deploy with Terraform
cd ../..
./deploy.sh
```

Or use the quick deploy:

```bash
terraform apply
```

### Enable Reply-To (After Production Access)

**Step 1: Request SES Production Access**
```
AWS Console → SES → Account dashboard → Request production access
```

**Step 2: Once Approved, Update Configuration**

Create `terraform.tfvars`:
```hcl
preserve_reply_to = true
```

Or edit `variables.tf` default:
```hcl
variable "preserve_reply_to" {
  default = true  # Change from false
}
```

**Step 3: Deploy**
```bash
./deploy.sh
```

## Testing

### Test in Sandbox Mode (Current)

1. **Send test email** to `info@polarisaistudio.com`
2. **Check CloudWatch logs:**
   ```bash
   aws logs tail /aws/lambda/ses-email-forwarder-forwarder \
     --region us-west-2 \
     --follow
   ```
3. **Look for:**
   ```
   Configuration loaded - PreserveReplyTo: false
   Skipping Reply-To (SES sandbox mode) - original sender: sender@example.com
   Successfully forwarded email to polarisaistudio@gmail.com
   ```
4. **Verify email received** at `polarisaistudio@gmail.com`
5. **Check headers** - X-Original-From should have original sender

### Test in Production Mode (After Approval)

1. **Deploy with `preserve_reply_to = true`**
2. **Send test email** to `info@polarisaistudio.com`
3. **Check CloudWatch logs:**
   ```
   Configuration loaded - PreserveReplyTo: true
   Added Reply-To: sender@example.com
   Successfully forwarded email to polarisaistudio@gmail.com
   ```
4. **Open forwarded email** in Gmail
5. **Click "Reply"**
6. **Verify** reply goes to original sender (not noreply@polarisaistudio.com)

## Files Changed

### Lambda Function
- `lambda/forwarder/main.go` - Added PRESERVE_REPLY_TO support

### Terraform Configuration
- `variables.tf` - Added preserve_reply_to variable
- `main.tf` - Pass preserve_reply_to to module
- `modules/email-forwarding/variables.tf` - Added module variable
- `modules/email-forwarding/main.tf` - Pass to Lambda environment

### Documentation
- `SANDBOX-MODE.md` - New: Explains sandbox vs production mode
- `RECENT-CHANGES.md` - This file: Summary of changes
- `SES-VERIFICATION.md` - Updated with production access info
- `EMAIL-FORWARDING-BEHAVIOR.md` - Updated with sandbox mode notes

## Current Status

**Email Forwarding:** ✅ Working (sandbox mode compatible)
**Reply-To Preservation:** ❌ Disabled (requires SES production access)
**Original Sender Tracking:** ✅ Working (X-Original-From header)
**Next Step:** Request SES production access to enable Reply-To

## Summary

The issue was that we added Reply-To header preservation, but SES sandbox mode validates all email addresses in headers. Since the original sender's email isn't verified in our account, SES rejected the email.

**Fix:** Made Reply-To header conditional based on `preserve_reply_to` variable:
- Default: `false` - Works in sandbox mode without Reply-To
- Production: `true` - Adds Reply-To header after getting SES production access

**Deploy now** to fix email forwarding in sandbox mode.
**Enable Reply-To later** after getting SES production access (free, takes 24 hours).
