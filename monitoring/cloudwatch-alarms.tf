# ================================================================
# CLOUDWATCH ALARMS
# ================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "instance_id" {
  description = "EC2 instance ID to monitor"
  type        = string
  default     = ""
}

variable "customer_id" {
  description = "Customer identifier"
  type        = string
  default     = "default"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  type        = string
  default     = ""
}

# ================================================================
# CPU ALARM
# ================================================================

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.instance_id != "" ? 1 : 0
  alarm_name          = "${var.customer_id}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization above 80%"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = {
    Customer = var.customer_id
  }
}

# ================================================================
# MEMORY ALARM (requires CloudWatch agent)
# ================================================================

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = var.instance_id != "" ? 1 : 0
  alarm_name          = "${var.customer_id}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Memory utilization above 85%"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = {
    Customer = var.customer_id
  }
}

# ================================================================
# DISK ALARM
# ================================================================

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  count               = var.instance_id != "" ? 1 : 0
  alarm_name          = "${var.customer_id}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Disk usage above 80%"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
    path       = "/"
  }

  tags = {
    Customer = var.customer_id
  }
}

# ================================================================
# STATUS CHECK ALARM
# ================================================================

resource "aws_cloudwatch_metric_alarm" "instance_status" {
  count               = var.instance_id != "" ? 1 : 0
  alarm_name          = "${var.customer_id}-instance-status-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Instance status check failed"

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = {
    Customer = var.customer_id
  }
}
