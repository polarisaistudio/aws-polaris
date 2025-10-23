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
