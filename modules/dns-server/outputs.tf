output "instance_id" {
  description = "Secondary DNS instance ID"
  value       = aws_instance.secondary_dns.id
}

output "public_ip" {
  description = "Secondary DNS public IP"
  value       = aws_eip.secondary_dns.public_ip
}

output "private_ip" {
  description = "Secondary DNS private IP"
  value       = aws_instance.secondary_dns.private_ip
}
