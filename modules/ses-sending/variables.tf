variable "domain_name" {
  description = "Root domain name (e.g., polarisaistudio.com)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for sending emails (e.g., 'mail' for mail.polarisaistudio.com)"
  type        = string
  default     = "mail"
}
