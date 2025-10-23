output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "nameservers" {
  description = "Route 53 nameservers"
  value       = data.aws_route53_zone.main.name_servers
}
