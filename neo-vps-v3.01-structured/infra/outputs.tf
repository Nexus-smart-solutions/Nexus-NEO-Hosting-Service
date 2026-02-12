# ===================================
# SECURITY MODULE OUTPUTS
# ===================================

output "cpanel_security_group_id" {
  description = "ID of the cPanel/WHM security group"
  value       = aws_security_group.cpanel.id
}

output "cpanel_security_group_arn" {
  description = "ARN of the cPanel/WHM security group"
  value       = aws_security_group.cpanel.arn
}

output "cpanel_security_group_name" {
  description = "Name of the cPanel/WHM security group"
  value       = aws_security_group.cpanel.name
}

# ===================================
# ACCESS INFORMATION
# ===================================

output "ssh_enabled" {
  description = "Whether SSH access is enabled"
  value       = length(var.allowed_ssh_cidrs) > 0
}

output "admin_access_enabled" {
  description = "Whether admin panel access (WHM/cPanel) is enabled from the internet"
  value       = length(var.allowed_admin_cidrs) > 0
}

output "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  value       = var.allowed_ssh_cidrs
}

output "allowed_admin_cidrs" {
  description = "List of CIDR blocks allowed for admin access"
  value       = var.allowed_admin_cidrs
}
