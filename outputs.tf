# ===================================
# OUTPUTS
# ===================================

output "instance_id" {
  description = "ID of the panel server instance"
  value       = module.panel_server.instance_id
}

output "private_ip" {
  description = "Private IP of the panel server"
  value       = module.panel_server.private_ip
}

output "public_ip" {
  description = "Public IP (if Elastic IP allocated)"
  value       = var.allocate_eip ? module.panel_server.elastic_ip : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.network.public_subnet_ids
}

output "security_group_id" {
  description = "Security Group ID"
  value       = module.security.security_group_id

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = var.enable_route53 ? module.route53[0].zone_id : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = module.monitoring.sns_topic_arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "alarm_names" {
  description = "Names of created alarms"
  value       = module.monitoring.alarm_names
}
