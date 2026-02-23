# ===================================
# AWS WAF MODULE - MAIN
# ===================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  resource_prefix = "neo-${var.customer_id}"
  common_tags = merge(var.tags, {
    Customer   = var.customer_id
    Domain     = var.customer_domain
    Addon      = "waf"
    ManagedBy  = "Terraform"
  })
}
# ===================================
# WAF Web ACL
# ===================================

resource "aws_wafv2_web_acl" "main" {
  name        = "${local.resource_prefix}-waf"
  description = "WAF protection for ${var.customer_domain}"
  scope       = var.scope

  default_action {
    allow {}
  }
# =========================================
  # AWS Managed Rules - Common Rule Set
# =========================================
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-common"
      sampled_requests_enabled   = true
    }
  }
# =========================================
  # AWS Managed Rules - SQL Injection
# =========================================

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-sqli"
      sampled_requests_enabled   = true
    }
  }
# =========================================
  # AWS Managed Rules - Known Bad Inputs
# =========================================

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }
# =========================================
  # Rate Limiting
# =========================================
  rule {
    name     = "rate-limiting"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.resource_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }
# =========================================
  # Country Blocking
# =========================================
  dynamic "rule" {
    for_each = var.blocked_countries != [] ? [1] : []

    content {
      name     = "country-block"
      priority = 5

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.resource_prefix}-geo-block"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.resource_prefix}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}
# =========================================
# Association with ALB/CloudFront
# =========================================

resource "aws_wafv2_web_acl_association" "main" {
  count        = var.resource_arn != "" ? 1 : 0
  resource_arn = var.resource_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
# =========================================
# WAF Logging
# =========================================

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.enable_logging ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf[0].arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}

resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/waf/${local.resource_prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}
# =========================================
# WAF Dashboard
# =========================================

resource "aws_cloudwatch_dashboard" "waf" {
  count = var.create_dashboard ? 1 : 0

  dashboard_name = "${local.resource_prefix}-waf-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", { stat = "Sum", label = "Allowed" }],
            ["AWS/WAFV2", "BlockedRequests", { stat = "Sum", label = "Blocked" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "WAF Requests - ${var.customer_domain}"
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}
