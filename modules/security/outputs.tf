# ===================================
# SECURITY MODULE - OUTPUTS
# ===================================

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.cpanel.id
}

output "panel_security_group_id" {
  description = "ID of the security group (alias for compatibility)"
  value       = aws_security_group.cpanel.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.cpanel.name
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.cpanel.arn
}

output "vpc_id" {
  description = "VPC ID where security group is created"
  value       = var.vpc_id
}
