# Email Forwarding Behavior

## How Forwarded Emails Appear

When you receive a forwarded email, the headers are modified to preserve the original sender information while using a verified From address.

### Email Headers Explained

**Original Email:**
```
From: John Doe <john@example.com>
To: support@polarisaistudio.com
Subject: Need help with your product
```

**Forwarded Email (What you receive):**
```
From: noreply@polarisaistudio.com
Reply-To: john@example.com
To: polarisaistudio@gmail.com
Subject: Need help with your product
X-Original-From: john@example.com
X-Original-To: support@polarisaistudio.com
X-Forwarded-By: AWS-SES-Forwarder
X-Forwarded-For: support@polarisaistudio.com
```

## Why This Works

### From Address
**Value**: `noreply@polarisaistudio.com`

**Why**: AWS SES requires the From address to be from a verified domain. We use `noreply@polarisaistudio.com` because:
- ✅ `polarisaistudio.com` domain is verified in SES
- ✅ Ensures email deliverability (SPF/DKIM pass)
- ✅ Prevents the email from being marked as spam

### Reply-To Header
**Value**: Original sender's email (e.g., `john@example.com`)

**Why**: This is the **magic** that makes forwarding transparent!
- ✅ When you click "Reply" in Gmail/Outlook, it replies to the **original sender**
- ✅ You don't see `noreply@polarisaistudio.com` in the reply
- ✅ The conversation flows naturally as if sent directly to you

### Custom Headers
**X-Original-From**: Shows who originally sent the email
**X-Original-To**: Shows which of your addresses received it (e.g., support@, info@)
**X-Forwarded-By**: Identifies this was forwarded by AWS-SES-Forwarder
**X-Forwarded-For**: Which address the email was sent to

These headers are useful for:
- Filtering/organizing emails by which address received them
- Debugging email delivery
- Tracking which public email address people are using

## Email Client Behavior

### Gmail
- **Displays**: Reply-To address as the sender
- **When you reply**: Goes to original sender automatically
- **Visible headers**: Shows `From: noreply@polarisaistudio.com` in "Show original"

### Outlook
- **Displays**: Reply-To address in sender field
- **When you reply**: Goes to original sender automatically
- **Visible headers**: Accessible via "View message details"

### Apple Mail
- **Displays**: Reply-To address prominently
- **When you reply**: Goes to original sender
- **Custom headers**: Visible in "View → Message → All Headers"

## Real-World Example

### Scenario
Someone emails `contact@polarisaistudio.com` from `customer@business.com`

### What Happens

1. **Email arrives at AWS SES**
   - Received by: `contact@polarisaistudio.com`
   - From: `customer@business.com`

2. **SES stores in S3**
   - Stored at: `s3://ses-email-forwarder-xxx/emails/message-id`

3. **Lambda processes email**
   - Downloads from S3
   - Modifies headers:
     - Sets From: `noreply@polarisaistudio.com`
     - Sets Reply-To: `customer@business.com`
     - Sets To: `polarisaistudio@gmail.com`
     - Adds X-Original-From: `customer@business.com`
     - Adds X-Original-To: `contact@polarisaistudio.com`

4. **SES sends forwarded email**
   - Delivered to: `polarisaistudio@gmail.com`

5. **You receive in Gmail**
   - Appears from: `customer@business.com` (via Reply-To)
   - You click Reply
   - Reply goes to: `customer@business.com` ✅

### Your Experience
```
Inbox: 1 new message
From: customer@business.com          ← This is what you see!
Subject: Question about your service

[Click Reply]

To: customer@business.com             ← Reply goes to original sender!
Subject: Re: Question about your service
```

## Filtering Forwarded Emails

You can create filters based on the custom headers:

### Gmail Filter Examples

**Filter by which address received the email:**
```
X-Original-To: support@polarisaistudio.com
→ Apply label: "Support Emails"
```

**Filter by forwarding source:**
```
X-Forwarded-By: AWS-SES-Forwarder
→ Apply label: "Forwarded"
```

**Filter specific alias:**
```
X-Original-To: info@polarisaistudio.com
→ Apply label: "General Inquiries"
```

## Technical Details

### Header Modification Logic

The Lambda function (`lambda/forwarder/main.go`) performs these operations:

1. **Parse email headers and body**
   - Split at `\r\n\r\n` (blank line separating headers from body)

2. **Modify/Replace headers:**
   - Remove: `Return-Path` (SES will set this)
   - Replace: `From` → `noreply@polarisaistudio.com`
   - Replace: `To` → Forwarding recipient
   - Add: `Reply-To` → Original sender (if not present)
   - Add: `X-Original-From` → Original sender
   - Add: `X-Original-To` → Original recipient
   - Add: `X-Forwarded-By` → Forwarder identifier
   - Add: `X-Forwarded-For` → Original recipient address

3. **Preserve everything else:**
   - Subject
   - Date
   - Message-ID
   - MIME headers
   - Email body (HTML and plain text)
   - Attachments

4. **Reconstruct and send:**
   - Combine modified headers + original body
   - Send via SES as raw email

## SPF, DKIM, and DMARC

### SPF (Sender Policy Framework)
✅ **Passes** - Email is sent from AWS SES, which is authorized for `polarisaistudio.com`

### DKIM (DomainKeys Identified Mail)
✅ **Passes** - AWS SES signs emails with `polarisaistudio.com` DKIM key

### DMARC (Domain-based Message Authentication)
✅ **Passes** - SPF and DKIM both pass for the From domain

**Result**: Forwarded emails have excellent deliverability and won't be marked as spam!

## Limitations and Considerations

### Original Sender Authentication
⚠️ The original sender's SPF/DKIM is **not preserved** because we're re-sending the email through our domain.

**Impact**: Original authentication headers (Authentication-Results) are removed/replaced.

**Why this is OK**: The Reply-To header ensures replies go to the right person, and our domain's authentication ensures deliverability.

### Attachments
✅ **Fully preserved** - All attachments are forwarded exactly as received.

### HTML Emails
✅ **Fully preserved** - HTML formatting, inline images, and styles are maintained.

### Email Size
⚠️ SES has a **40 MB** limit for raw email messages.

**Emails larger than 40 MB will fail to forward.**

**Mitigation**: The S3 action in SES can handle emails up to **40 MB**, so this limit rarely affects typical email forwarding.

## Troubleshooting

### Problem: Reply-To not showing original sender

**Check**: Look at "Show Original" in Gmail or "View Source" in other clients
- Search for `Reply-To:` header
- Verify it contains the original sender

**Possible cause**: Email client not respecting Reply-To header
- Try a different email client
- Check client settings for Reply-To behavior

### Problem: Original sender appears in From field

**Expected behavior**: Some email clients show both:
- From: `noreply@polarisaistudio.com`
- On behalf of: `customer@business.com` (from Reply-To)

**This is normal** and doesn't affect functionality.

### Problem: Forwarded emails going to spam

**Check deliverability**:
```bash
# Verify DNS records
dig MX polarisaistudio.com
dig TXT polarisaistudio.com
dig TXT _dmarc.polarisaistudio.com
```

**Ensure**:
- ✅ SPF record includes SES
- ✅ DKIM tokens are configured
- ✅ DMARC policy is set

## Summary

**What you'll see:**
- Emails appear to come from the original sender (via Reply-To)
- Replying goes directly to the original sender
- Custom headers show routing information

**What works:**
- ✅ Reply to original sender
- ✅ Full email content and attachments
- ✅ Proper authentication (SPF/DKIM/DMARC)
- ✅ No spam issues

**Best practices:**
- Use Reply-To aware email client (Gmail, Outlook, Apple Mail)
- Set up filters using X-Original-To header
- Monitor CloudWatch Logs for any forwarding issues
- Keep SES in production mode to avoid recipient verification

The forwarding is transparent and works exactly as if the email was sent directly to your inbox!
