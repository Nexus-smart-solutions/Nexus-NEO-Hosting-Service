# ===================================
# SECURITY MODULE OUTPUTS
# ===================================

output "cpanel_security_group_id" {
  description = "ID of cPanel security group"
  value       = aws_security_group.cpanel.id
}

output "cpanel_security_group_name" {
  description = "Name of cPanel security group"
  value       = aws_security_group.cpanel.name
}
