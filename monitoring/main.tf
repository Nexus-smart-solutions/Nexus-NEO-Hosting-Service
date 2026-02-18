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

# ===================================
# DATA SOURCES
# ===================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ===================================
# LOCAL VALUES
# ===================================

locals {
  resource_prefix = "neo-${var.customer_id}"
  dashboard_name  = "neo-vps-${replace(var.customer_domain, ".", "-")}"
  common_tags = merge(var.tags, {
    Customer   = var.customer_id
    Domain     = var.customer_domain
    Environment = var.environment
    ManagedBy  = "Terraform"
    Project    = "Neo-VPS"
  })
}

# ===================================
# CLOUDWATCH ALARMS - EC2 METRICS
# ===================================

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.resource_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "CPU utilization exceeds ${var.cpu_high_threshold}%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  insufficient_data_actions = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = local.common_tags
}

# Status Check Failed Alarm
resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "${local.resource_prefix}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Instance status check failed"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = local.common_tags
}

# ===================================
# CLOUDWATCH ALARMS - CUSTOM METRICS (CloudWatch Agent)
# ===================================

# Disk Usage Alarm
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
  ok_actions          = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
    path       = "/"
    device     = "nvme0n1p1"
    fstype     = "xfs"
  }

  tags = local.common_tags
}

# Memory Usage Alarm
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
  alarm_description   = "Memory usage above ${var.memory_threshold}%"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = local.common_tags
}

# ===================================
# SNS TOPIC (Optional - create if not provided)
# ===================================

locals {
  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : (aws_sns_topic.alerts[0].arn != "" ? [aws_sns_topic.alerts[0].arn] : [])
}

resource "aws_sns_topic" "alerts" {
  count = var.sns_topic_arn == "" ? 1 : 0
  
  name = "${local.resource_prefix}-alerts"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = (var.sns_topic_arn == "" && var.alert_email != "") ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "slack" {
  count = (var.sns_topic_arn == "" && var.slack_webhook != "") ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "https"
  endpoint  = var.slack_webhook
}

# ===================================
# CLOUDWATCH DASHBOARD
# ===================================

resource "aws_cloudwatch_dashboard" "main" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU Usage" }],
            [".", "CPUUtilization", { stat = "Maximum", label = "CPU Max", period = 3600, visible = false }]
          ]
          view    = "timeSeries"
          region  = data.aws_region.current.name
          title   = "CPU Utilization - ${var.customer_domain}"
          period  = 300
          yAxis = {
            left = {
              min = 0
              max = 100
              label = "Percent"
            }
          }
          setPeriodToTimeRange = true
          liveData             = false
          stat                 = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["CWAgent", "disk_used_percent", "InstanceId", var.instance_id, "path", "/", { stat = "Average", label = "Disk Usage" }],
            ["CWAgent", "mem_used_percent", "InstanceId", var.instance_id, { stat = "Average", label = "Memory Usage" }]
          ]
          view   = "timeSeries"
          region = data.aws_region.current.name
          title  = "Disk & Memory Usage - ${var.customer_domain}"
          period = 300
          yAxis = {
            left = {
              min = 0
              max = 100
              label = "Percent"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.instance_id, { stat = "Average", label = "Network In" }],
            [".", "NetworkOut", ".", ".", { stat = "Average", label = "Network Out" }]
          ]
          view   = "timeSeries"
          region = data.aws_region.current.name
          title  = "Network Traffic - ${var.customer_domain}"
          period = 300
          yAxis = {
            left = {
              min = 0
              label = "Bytes"
            }
          }
          stacked = false
        }
      },
      {
        type = "text"
        properties = {
          markdown = "## Instance Information\n- **Instance ID:** ${var.instance_id}\n- **Domain:** ${var.customer_domain}\n- **Customer:** ${var.customer_id}\n- **Environment:** ${var.environment}"
        }
      }
    ]
  })

  depends_on = [aws_cloudwatch_metric_alarm.cpu_high]
}

# ===================================
# PYTHON SCRIPT FOR DASHBOARD (Optional - إذا عاوز تشغل بايثون)
# ===================================

resource "null_resource" "create_dashboard_python" {
  count = var.create_dashboard_with_python ? 1 : 0

  provisioner "local-exec" {
    command = "python3 ${path.module}/create-dashboard.py ${var.customer_domain} ${var.instance_id} ${var.customer_id}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [aws_cloudwatch_metric_alarm.cpu_high]
}

# ===================================
# OUTPUTS
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
