# Email Forwarding Examples

## How Forwarded Emails Appear

### Sandbox Mode (Current - Default)

When `preserve_reply_to = false` (default), the original sender information is **prepended to the email body** for easy visibility.

---

## Plain Text Email Example

### Original Email Sent
```
From: customer@example.com
To: support@polarisaistudio.com
Subject: Question about your product

Hi there,

I'm interested in learning more about your services.
Can you send me some information?

Thanks,
John
```

### Forwarded Email Received

```
From: noreply@polarisaistudio.com
To: polarisaistudio@gmail.com
Subject: Question about your product

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 FORWARDED EMAIL
From: customer@example.com
To: support@polarisaistudio.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hi there,

I'm interested in learning more about your services.
Can you send me some information?

Thanks,
John
```

**What you see:**
- Clear banner at the top showing who sent the email
- Original sender email is right there (easy to copy/paste for reply)
- Which address they sent to (support@, info@, etc.)

---

## HTML Email Example

### Original Email Sent

An HTML email with formatting, colors, and images.

### Forwarded Email Received

**Visual appearance in Gmail/Outlook:**

```
┌─────────────────────────────────────────────────┐
│ 📧 Forwarded Email                              │
│ From: customer@example.com                      │  ← Clickable link!
│ To: support@polarisaistudio.com                 │
└─────────────────────────────────────────────────┘

[Rest of the original HTML email with all formatting preserved]
```

**The sender banner:**
- Gray background with green left border
- "📧 Forwarded Email" header in green
- **From:** is a clickable `mailto:` link (click to compose reply)
- **To:** shows which address received it
- Styled to look professional and non-intrusive

**HTML source:**
```html
<div style="background-color: #f0f0f0; border-left: 4px solid #4CAF50; padding: 12px 16px; margin-bottom: 20px; font-family: Arial, sans-serif; font-size: 14px; color: #333;">
  <div style="font-weight: bold; margin-bottom: 8px; color: #4CAF50;">📧 Forwarded Email</div>
  <div><strong>From:</strong> <a href="mailto:customer@example.com" style="color: #1a73e8; text-decoration: none;">customer@example.com</a></div>
  <div><strong>To:</strong> support@polarisaistudio.com</div>
</div>

<!-- Original email content follows -->
```

---

## Production Mode (After SES Approval)

When `preserve_reply_to = true`, the email works like a native forwarding:

### Email Received

```
From: noreply@polarisaistudio.com
Reply-To: customer@example.com              ← Your email client uses this!
To: polarisaistudio@gmail.com
Subject: Question about your product

Hi there,

I'm interested in learning more about your services.
Can you send me some information?

Thanks,
John
```

**What you see:**
- Email appears to come from `customer@example.com` (most clients show Reply-To as sender)
- **No banner needed** - just the original email
- Click "Reply" → automatically goes to `customer@example.com`
- Natural email experience

---

## Comparison

| Mode | Sender Visibility | Reply Action | Email Appearance |
|------|------------------|--------------|------------------|
| **Sandbox (current)** | Banner at top of email | Copy email from banner | Original email + info banner |
| **Production** | Reply-To header | Click Reply → original sender | Original email only |

---

## How to Reply in Sandbox Mode

### Method 1: Click the Email Link (HTML emails only)

**In HTML emails:**
1. Click the blue email link in the banner
2. Your email client opens with a new message to that address
3. Compose your reply

### Method 2: Copy/Paste Email Address

**In plain text or any email:**
1. Copy the email from the "From:" line in the banner
2. Click "Compose" in your email client
3. Paste the email address
4. Write your reply

### Method 3: Reply All + Edit (Quick)

**For a quick reply:**
1. Click "Reply All"
2. Delete `noreply@polarisaistudio.com` from recipients
3. Add the original sender's email from the banner
4. Send your reply

---

## Email Client Screenshots

### Gmail

**Plain text email:**
```
┌─────────────────────────────────────────────────┐
│ From: noreply@polarisaistudio.com               │
│ To: me                                          │
│ Subject: Question about your product            │
├─────────────────────────────────────────────────┤
│                                                 │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ 📧 FORWARDED EMAIL                              │
│ From: customer@example.com                      │
│ To: support@polarisaistudio.com                 │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                 │
│ Hi there,                                       │
│                                                 │
│ I'm interested in learning more...             │
└─────────────────────────────────────────────────┘
```

**HTML email:**
```
┌─────────────────────────────────────────────────┐
│ From: noreply@polarisaistudio.com               │
│ To: me                                          │
│ Subject: Question about your product            │
├─────────────────────────────────────────────────┤
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 📧 Forwarded Email                          │ │
│ │ From: customer@example.com                  │ │  ← Clickable!
│ │ To: support@polarisaistudio.com             │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ [Original HTML email content]                  │
└─────────────────────────────────────────────────┘
```

---

## Multi-Part Email Handling

### What are multi-part emails?

Most emails are sent as "multipart/alternative" with both:
- Plain text version
- HTML version

Your email client chooses which one to display.

### How the Lambda handles it

**The Lambda detects the Content-Type header:**

```go
if strings.Contains(lowerHeader, "text/html") {
    // Add styled HTML banner
} else {
    // Add plain text banner
}
```

**Result:**
- HTML-capable clients (Gmail, Outlook) see the styled banner
- Plain text clients see the text banner
- Both versions get the original sender info

---

## Mobile Email Clients

### iPhone Mail App

**HTML emails:**
- Banner appears at top with green accent
- Email address is tappable → opens compose window
- Looks professional and clean

**Plain text emails:**
- Banner shows clearly with separator lines
- Easy to copy email address
- Readable on small screens

### Gmail Mobile App

**HTML emails:**
- Styled banner renders perfectly
- Tap email → new compose window
- Matches desktop experience

### Outlook Mobile

**HTML emails:**
- Banner displays with proper styling
- Clickable mailto: links work
- Consistent with desktop

---

## Edge Cases Handled

### 1. Email without body tag (malformed HTML)

**Fallback:** Banner is prepended to the beginning of the content.

### 2. Plain text email detected as HTML

**Not an issue:** Content-Type header is authoritative, not content inspection.

### 3. Emails with inline images

**Handled:** Banner is inserted after `<body>` tag, before any content, so images load normally.

### 4. Rich HTML with CSS

**Handled:** Banner uses inline styles, won't conflict with email's CSS.

---

## Production Mode Comparison

### When you enable `preserve_reply_to = true`:

**Before (sandbox mode):**
```
From: noreply@polarisaistudio.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 FORWARDED EMAIL
From: customer@example.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Original email body]
```

**After (production mode):**
```
From: noreply@polarisaistudio.com
Reply-To: customer@example.com

[Original email body]
```

**Benefits of production mode:**
- Cleaner email appearance (no banner)
- One-click reply workflow
- More professional presentation

**Benefits of sandbox mode (current):**
- Sender info is always visible
- No need to check headers
- Works immediately without SES approval
- Email address is clickable in HTML emails

---

## Summary

**Sandbox mode (current):** Original sender info is **prepended to the email body** in a clear, professional banner:

- ✅ **Immediately visible** - no hunting through headers
- ✅ **Clickable links** in HTML emails - one click to reply
- ✅ **Works now** - no SES production access needed
- ✅ **Handles all email formats** - plain text and HTML
- ✅ **Mobile friendly** - looks good on all devices

**Production mode (optional later):** Uses Reply-To header for native forwarding behavior.

The banner approach gives you the best of both worlds - easy visibility and quick replies, even in SES sandbox mode!
