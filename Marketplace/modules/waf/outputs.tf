# ===================================
# WAF MODULE - OUTPUTS
# ===================================

output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_name" {
  description = "WAF Web ACL name"
  value       = aws_wafv2_web_acl.main.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = var.enable_logging ? aws_cloudwatch_log_group.waf[0].name : null
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.waf[0].dashboard_name : null
}
