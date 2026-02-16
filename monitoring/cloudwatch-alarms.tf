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
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    InstanceId = var.instance_id
  }
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
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    InstanceId = var.instance_id
    path       = "/"
  }
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
  alarm_actions       = [var.sns_topic_arn]
  
  dimensions = {
    InstanceId = var.instance_id
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "neo-customer-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "dev@nexus-dxb.com"
}

module "monitoring" {
  source = "./modules/monitoring"
  
  customer_id   = var.customer_id
  instance_id   = module.panel_server.instance_id
  sns_topic_arn = aws_sns_topic.alerts.arn
}
