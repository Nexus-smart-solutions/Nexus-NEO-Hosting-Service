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
# VARIABLES
# ===================================

variable "customer_id" {
  description = "Customer identifier"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ===================================
# CLOUDWATCH ALARMS
# ===================================

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.customer_id}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "CPU above 75%"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${var.customer_id}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Disk usage above 80%"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
    path       = "/"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.customer_id}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Memory above 90%"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = var.tags
}

# ===================================
# SNS TOPIC (Optional - create if not provided)
# ===================================

resource "aws_sns_topic" "alerts" {
  count = var.sns_topic_arn == "" ? 1 : 0
  
  name = "neo-${var.customer_id}-alerts"

  tags = merge(var.tags, {
    Name       = "neo-${var.customer_id}-alerts"
    Customer   = var.customer_id
    ManagedBy  = "Terraform"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.sns_topic_arn == "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = "dev@nexus-dxb.com"  # غير ده للإيميل بتاعك
}

# ===================================
# OUTPUTS
# ===================================

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value = var.sns_topic_arn != "" ? var.sns_topic_arn : aws_sns_topic.alerts[0].arn
}

output "alarm_names" {
  description = "Names of created alarms"
  value = [
    aws_cloudwatch_metric_alarm.cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.disk_high.alarm_name,
    aws_cloudwatch_metric_alarm.memory_high.alarm_name
  ]
}
