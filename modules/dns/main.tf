# DNS Module - Route 53 Records for Email and GitHub Pages

# Use existing Route 53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ==============================================================================
# Email DNS Records
# ==============================================================================

# MX Record for SES
resource "aws_route53_record" "mx" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300
  records = ["10 inbound-smtp.${var.aws_region}.amazonaws.com"]
}

# TXT Record for SPF
resource "aws_route53_record" "spf" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# SES Domain Verification TXT Record
resource "aws_route53_record" "ses_verification" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = [var.ses_verification_token]
}

# DKIM Records (SES generates 3 CNAME records)
resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${var.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# DMARC Record
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=quarantine; rua=mailto:postmaster@${var.domain_name}"]
}

# ==============================================================================
# GitHub Pages DNS Records
# ==============================================================================

# A records for apex domain to GitHub Pages
resource "aws_route53_record" "github_pages_apex" {
  count   = var.github_pages_repo != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153"
  ]
}

# AAAA records for apex domain (IPv6 support)
resource "aws_route53_record" "github_pages_apex_ipv6" {
  count   = var.github_pages_repo != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"
  ttl     = 300
  records = [
    "2606:50c0:8000::153",
    "2606:50c0:8001::153",
    "2606:50c0:8002::153",
    "2606:50c0:8003::153"
  ]
}

# CNAME record for www subdomain
resource "aws_route53_record" "github_pages_www" {
  count   = var.github_pages_repo != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.github_pages_repo]
}

# ==============================================================================
# Vercel DNS Records (Wildcard Subdomain Support)
# ==============================================================================
# Delegates a subdomain (e.g., app.domain.com) to Vercel's nameservers
# This enables wildcard SSL certificates for *.app.domain.com
# Method: Full NS Delegation (recommended by Vercel for wildcard domains)

# NS record to delegate subdomain to Vercel nameservers
resource "aws_route53_record" "vercel_ns_delegation" {
  count   = var.vercel_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.vercel_subdomain}.${var.domain_name}"
  type    = "NS"
  ttl     = 300
  records = var.vercel_nameservers
}

# ==============================================================================
# Resend DNS Records
# ==============================================================================
# Configures DNS records for sending email via Resend using a subdomain
# (e.g., mail.polarisaistudio.com)

# MX Record for Resend (send.mail.domain.com)
resource "aws_route53_record" "resend_mx" {
  count   = var.resend_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "send.${var.resend_subdomain}.${var.domain_name}"
  type    = "MX"
  ttl     = 300
  records = ["10 feedback-smtp.us-east-1.amazonses.com"]
}

# SPF Record for Resend (send.mail.domain.com)
resource "aws_route53_record" "resend_spf" {
  count   = var.resend_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "send.${var.resend_subdomain}.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DKIM Record for Resend (resend._domainkey.mail.domain.com)
resource "aws_route53_record" "resend_dkim" {
  count   = var.resend_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "resend._domainkey.${var.resend_subdomain}.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = [var.resend_dkim_key]
}
