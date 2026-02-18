# ===================================
# MONITORING MODULE - OUTPUTS
# ===================================

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.sns_topic_arn != "" ? var.sns_topic_arn : (aws_sns_topic.alerts[0].arn != "" ? aws_sns_topic.alerts[0].arn : null)
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.create_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${local.dashboard_name}" : null
}

output "alarm_names" {
  description = "Names of created alarms"
  value = [
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.status_check_failed.alarm_name,
    aws_cloudwatch_metric_alarm.disk_high[0].alarm_name,
    aws_cloudwatch_metric_alarm.memory_high[0].alarm_name
  ]
}

output "alarm_count" {
  description = "Number of active alarms"
  value = length([
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.status_check_failed.alarm_name,
    aws_cloudwatch_metric_alarm.disk_high,
    aws_cloudwatch_metric_alarm.memory_high
  ])
}
