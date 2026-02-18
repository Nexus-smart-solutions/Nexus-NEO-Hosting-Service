# ===================================
# MONITORING MODULE - MAIN
# ===================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  resource_prefix = "neo-${var.customer_id}"
  alarm_actions   = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
}

# SNS Topic (if not provided)
resource "aws_sns_topic" "alerts" {
  count = var.sns_topic_arn == "" ? 1 : 0
  name  = "${local.resource_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.sns_topic_arn == "" && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CPU Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.resource_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "CPU above ${var.cpu_high_threshold}%"
  alarm_actions       = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
  }
}

# Disk Alarm
resource "aws_cloudwatch_metric_alarm" "disk_high" {
  count = var.enable_disk_alarm ? 1 : 0

  alarm_name          = "${local.resource_prefix}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_threshold
  alarm_description   = "Disk usage above ${var.disk_threshold}%"
  alarm_actions       = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
    path       = "/"
  }
}

# Memory Alarm
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count = var.enable_memory_alarm ? 1 : 0

  alarm_name          = "${local.resource_prefix}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "Memory above ${var.memory_threshold}%"
  alarm_actions       = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
  }
}

# Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "neo-vps-${replace(var.customer_domain, ".", "-")}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }]
          ]
          view   = "timeSeries"
          region = data.aws_region.current.name
          title  = "CPU Utilization - ${var.customer_domain}"
          period = 300
        }
      }
    ]
  })
}

# Outputs
output "sns_topic_arn" {
  value = var.sns_topic_arn != "" ? var.sns_topic_arn : (var.sns_topic_arn == "" && var.alert_email != "" ? aws_sns_topic.alerts[0].arn : null)
}

output "dashboard_url" {
  value = var.create_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=neo-vps-${replace(var.customer_domain, ".", "-")}" : null
}

output "alarm_names" {
  value = compact([
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    var.enable_disk_alarm ? aws_cloudwatch_metric_alarm.disk_high[0].alarm_name : "",
    var.enable_memory_alarm ? aws_cloudwatch_metric_alarm.memory_high[0].alarm_name : ""
  ])
}
