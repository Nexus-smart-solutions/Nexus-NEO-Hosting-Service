# ===================================
# CPANEL SERVER MODULE OUTPUTS
# ===================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cpanel.id
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = aws_instance.cpanel.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (public)"
  value       = aws_eip.cpanel.public_ip
}

output "data_volume_id" {
  description = "Data EBS volume ID"
  value       = aws_ebs_volume.data.id
}

output "backup_bucket_name" {
  description = "S3 backup bucket name"
  value       = aws_s3_bucket.backups.id
}

output "backup_bucket_arn" {
  description = "S3 backup bucket ARN"
  value       = aws_s3_bucket.backups.arn
}

output "whm_url" {
  description = "WHM access URL"
  value       = "https://${aws_eip.cpanel.public_ip}:2087"
}

output "cpanel_url" {
  description = "cPanel access URL"
  value       = "https://${aws_eip.cpanel.public_ip}:2083"
}

output "webmail_url" {
  description = "Webmail access URL"
  value       = "https://${aws_eip.cpanel.public_ip}:2096"
}

output "nameservers" {
  description = "Nameserver addresses"
  value = [
    "ns1.${var.customer_domain}",
    "ns2.${var.customer_domain}"
  ]
}

output "ssh_command" {
  description = "SSM Session Manager command"
  value       = "aws ssm start-session --target ${aws_instance.cpanel.id}"
}
