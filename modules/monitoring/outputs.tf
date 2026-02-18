# ===================================
# MONITORING MODULE - OUTPUTS
# ===================================

output "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.sns_topic_arn != "" ? var.sns_topic_arn : (try(aws_sns_topic.alerts[0].arn, ""))
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.create_dashboard ? try(aws_cloudwatch_dashboard.main[0].dashboard_name, null) : null
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = var.create_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${try(aws_cloudwatch_dashboard.main[0].dashboard_name, "")}" : null
}

output "alarm_names" {
  description = "Names of created alarms"
  value = compact([
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    var.enable_disk_alarm ? try(aws_cloudwatch_metric_alarm.disk_high[0].alarm_name, "") : "",
    var.enable_memory_alarm ? try(aws_cloudwatch_metric_alarm.memory_high[0].alarm_name, "") : ""
  ])
}

output "alarm_count" {
  description = "Number of active alarms"
  value = length(compact([
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    var.enable_disk_alarm ? try(aws_cloudwatch_metric_alarm.disk_high[0].alarm_name, "") : "",
    var.enable_memory_alarm ? try(aws_cloudwatch_metric_alarm.memory_high[0].alarm_name, "")
  ]))
}
