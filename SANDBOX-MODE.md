# SES Sandbox Mode vs Production Mode

## Current Status: Sandbox Mode

Your AWS SES is currently in **sandbox mode**, which has these limitations:

### Sandbox Mode Limitations

❌ Can only send emails TO verified addresses
❌ Cannot use Reply-To header with unverified addresses
❌ Limited to 200 emails per day
❌ Limited to 1 email per second
✅ Can send FROM verified domains (polarisaistudio.com is verified)

## How This Affects Email Forwarding

### Current Behavior (Sandbox Mode)

**PRESERVE_REPLY_TO = false** (default)

When someone emails you at `info@polarisaistudio.com`:

```
Original Email:
From: customer@example.com
To: info@polarisaistudio.com
Subject: Question about your product
Body: Hi, I have a question...

Forwarded Email (what you receive):
From: noreply@polarisaistudio.com
To: polarisaistudio@gmail.com
Subject: Question about your product

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 FORWARDED EMAIL
From: customer@example.com                    ← Clickable email link!
To: info@polarisaistudio.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hi, I have a question...

Headers:
X-Original-From: customer@example.com
X-Original-To: info@polarisaistudio.com
X-Forwarded-By: AWS-SES-Forwarder
```

**Key Feature:** The original sender information is **prepended to the email body** for immediate visibility!

- ✅ Original sender email is **right at the top** of the message
- ✅ In HTML emails, the email is a **clickable mailto: link** (one click to reply)
- ✅ In plain text emails, easy to copy and paste the address
- ✅ Shows which address received the email (info@, support@, etc.)
- ✅ Professional-looking banner that doesn't interfere with email content

**Important:** There is NO Reply-To header with the original sender in sandbox mode (would cause SES rejection).

### Why Reply-To is Disabled in Sandbox Mode

SES sandbox mode validates **all email addresses** in the email headers, including:

- From address
- To address
- Reply-To address ← This is the problem!
- CC addresses
- BCC addresses

Since we set `Reply-To: customer@example.com` (the original sender), SES tries to verify that `customer@example.com` is verified in your account. Since it's not, the email is rejected.

**Error you would see:**

```
MessageRejected: Email address is not verified.
The following identities failed the check: <customer@example.com>
```

### Production Mode Behavior

**PRESERVE_REPLY_TO = true** (after SES production access)

When someone emails you at `info@polarisaistudio.com`:

```
Original Email:
From: customer@example.com
To: info@polarisaistudio.com
Subject: Question about your product

Forwarded Email (what you receive):
From: noreply@polarisaistudio.com
Reply-To: customer@example.com              ← Original sender preserved!
To: polarisaistudio@gmail.com
Subject: Question about your product
X-Original-From: customer@example.com
X-Original-To: info@polarisaistudio.com
X-Forwarded-By: AWS-SES-Forwarder
```

**When you click Reply in Gmail/Outlook:**

- Reply automatically goes to `customer@example.com`
- The conversation flows naturally
- You don't see `noreply@polarisaistudio.com` in the reply

## Getting Production Access

### Benefits

✅ Send emails to ANY address (no verification needed)
✅ Reply-To header works (preserve original sender)
✅ 50,000 emails per day initially
✅ Better deliverability
✅ Professional email forwarding

### How to Request Production Access

**Method 1: AWS Console (Recommended)**

1. **Go to AWS Console** → SES → Account dashboard (us-west-2 region)
2. **Click "Request production access"**
3. **Fill out the form:**
   - **Mail type**: Transactional
   - **Website URL**: https://polarisaistudio.com
   - **Use case description**:
     ```
     Email forwarding service for custom domain. We receive emails
     at various addresses (info@, support@, contact@, admin@) and
     forward them to a personal email account. All emails are
     legitimate correspondence sent to our domain.
     ```
   - **Additional information**:
     ```
     - Using AWS SES receipt rules with Lambda for forwarding
     - Low volume: approximately 50-100 emails per month
     - Implementing proper bounce and complaint handling via SES
     - All forwarded emails are wanted correspondence
     ```
   - **Bounce/complaint handling**: AWS SES automatic handling
   - **Expected sending volume**: Less than 1,000 emails/month

4. **Submit request**
5. **Wait for approval** (usually within 24 hours)

**Method 2: AWS CLI**

```bash
aws sesv2 put-account-details \
  --region us-west-2 \
  --production-access-enabled \
  --mail-type TRANSACTIONAL \
  --website-url https://polarisaistudio.com \
  --use-case-description "Email forwarding service for custom domain. Low volume legitimate correspondence." \
  --additional-contact-email-addresses polarisaistudio@gmail.com
```

### Check Current Status

```bash
aws sesv2 get-account --region us-west-2
```

Look for:

```json
{
  "ProductionAccessEnabled": false // Still in sandbox
}
```

or

```json
{
  "ProductionAccessEnabled": true // Production access granted!
}
```

## Enabling Reply-To After Production Access

Once you receive production access approval:

### Step 1: Update Terraform Variable

Edit `variables.tf` (or create `terraform.tfvars`):

```hcl
# variables.tf - Change default
variable "preserve_reply_to" {
  description = "Preserve Reply-To header with original sender"
  type        = bool
  default     = true  # Change from false to true
}
```

Or create/edit `terraform.tfvars`:

```hcl
preserve_reply_to = true
```

### Step 2: Deploy the Change

```bash
./deploy.sh
```

Or:

```bash
terraform apply
```

### Step 3: Verify Configuration

Check CloudWatch logs after sending a test email:

```bash
aws logs tail /aws/lambda/ses-email-forwarder-forwarder \
  --region us-west-2 \
  --follow
```

Look for:

```
Configuration loaded - PreserveReplyTo: true
Added Reply-To: customer@example.com
```

### Step 4: Test Email Forwarding

1. Send test email to `info@polarisaistudio.com`
2. Check your inbox at `polarisaistudio@gmail.com`
3. Verify "Reply-To" header exists (View → Show Original in Gmail)
4. Click Reply and confirm it goes to the original sender

## Current Workarounds (While in Sandbox Mode)

Since you can't use Reply-To in sandbox mode, you can:

### 1. Check X-Original-From Header

The original sender is always preserved in the `X-Original-From` header:

**Gmail:**

- Open email
- Click the three dots (⋮)
- Click "Show original"
- Search for `X-Original-From:`

**Outlook:**

- Open email
- File → Properties
- Look for `X-Original-From:` in Internet headers

### 2. Manually Reply to Original Sender

1. Open forwarded email
2. Look at `X-Original-From` header
3. Manually copy the email address
4. Create new email to that address

### 3. Use Gmail Filters

Create a filter to extract the original sender:

**Filter rule:**

```
has:attachment OR from:noreply@polarisaistudio.com
```

**Action:**

- Add custom label based on X-Original-To
- Star or categorize based on which address received it

## Cost Comparison

| Mode           | Cost          | Limits            | Reply-To Works? |
| -------------- | ------------- | ----------------- | --------------- |
| **Sandbox**    | $0.50-1.00/mo | 200 emails/day    | ❌ No           |
| **Production** | $0.50-1.00/mo | 50,000 emails/day | ✅ Yes          |

**Production access is FREE and has better limits!**

## Timeline

### Immediate (5 minutes)

1. Deploy current code (sandbox mode compatible)
2. Email forwarding works without Reply-To
3. Original sender in X-Original-From header

### Within 24 Hours (Production Access)

1. Request production access via AWS Console
2. Wait for approval (usually < 24 hours)
3. Set `preserve_reply_to = true`
4. Deploy with `./deploy.sh`
5. Test Reply-To functionality

### Long Term (Production Mode)

- ✅ Professional email forwarding
- ✅ Natural reply workflow
- ✅ No verification needed for recipients
- ✅ Higher sending limits

## Troubleshooting

### Email forwarding not working at all

**Check CloudWatch logs:**

```bash
aws logs tail /aws/lambda/ses-email-forwarder-forwarder \
  --region us-west-2 \
  --since 1h
```

**Common errors in sandbox mode:**

```
Email address is not verified: <sender@example.com>
```

**Solution:** This is expected in sandbox mode with Reply-To enabled. Deploy the latest code with `preserve_reply_to = false`.

### Production access request denied

**Reasons:**

- Insufficient use case description
- Suspicious sending patterns
- New AWS account

**Solution:**

- Provide more detail about your use case
- Explain it's for personal email forwarding
- Mention low volume (< 100 emails/month)
- Resubmit with additional context

### Reply-To still not working after production access

**Check configuration:**

```bash
# View current Lambda environment variables
aws lambda get-function-configuration \
  --function-name ses-email-forwarder-forwarder \
  --region us-west-2 \
  --query 'Environment.Variables'
```

**Look for:**

```json
{
  "PRESERVE_REPLY_TO": "true"
}
```

**If it's "false":**

1. Update `preserve_reply_to = true` in Terraform
2. Run `terraform apply`
3. Test again

## Summary

**Right Now (Sandbox Mode):**

- ✅ Email forwarding works
- ✅ Original sender in X-Original-From header
- ❌ No Reply-To header (would cause errors)
- ❌ Must manually check headers to see original sender

**After Production Access:**

- ✅ Everything above
- ✅ Reply-To header with original sender
- ✅ Click Reply → goes to original sender automatically
- ✅ Natural email workflow
- ✅ No manual header checking needed

**Action Items:**

1. Deploy current code (works in sandbox mode)
2. Request SES production access (free, takes 24 hours)
3. Once approved: Set `preserve_reply_to = true` and redeploy
4. Enjoy professional email forwarding with Reply-To!
