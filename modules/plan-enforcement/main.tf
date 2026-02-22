# ================================================================
# PLAN ENFORCEMENT MODULE
# ================================================================
# Validates resources against plan limits
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

locals {
  # Load plan configuration
  plan_config = yamldecode(file("${path.root}/plans/${var.plan_slug}.yaml"))
  plan        = local.plan_config.plan
  
  # Extract limits
  specs  = local.plan.specs
  limits = local.plan.limits
  
  # Validate instance type matches plan
  instance_type_valid = var.instance_type == local.plan.terraform_vars.instance_type
  
  # Validate storage doesn't exceed plan
  storage_valid = (
    var.root_volume_size <= local.plan.terraform_vars.root_volume_size &&
    var.data_volume_size <= local.plan.terraform_vars.data_volume_size
  )
  
  # Generate quota tags
  quota_tags = {
    Plan              = local.plan.name
    MaxDomains        = local.limits.domains
    MaxDatabases      = local.limits.databases
    MaxEmailAccounts  = local.limits.email_accounts
    BandwidthLimitTB  = local.specs.networking.bandwidth_tb
    StorageLimitGB    = local.specs.storage.total_gb
  }
}

# ================================================================
# VALIDATION CHECKS
# ================================================================

resource "null_resource" "validate_plan" {
  triggers = {
    plan_slug     = var.plan_slug
    instance_type = var.instance_type
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Validating plan: ${var.plan_slug}"
      echo "Instance type: ${var.instance_type}"
      echo "Expected: ${local.plan.terraform_vars.instance_type}"
      
      if [ "${var.instance_type}" != "${local.plan.terraform_vars.instance_type}" ]; then
        echo "ERROR: Instance type mismatch!"
        echo "Plan ${var.plan_slug} requires ${local.plan.terraform_vars.instance_type}"
        exit 1
      fi
      
      echo "✓ Plan validation passed"
    EOT
  }
}

# ================================================================
# CLOUDWATCH QUOTA METRICS
# ================================================================

resource "aws_cloudwatch_log_metric_filter" "domain_count" {
  count = var.enable_quota_monitoring ? 1 : 0
  
  name           = "${var.customer_id}-domain-count"
  log_group_name = var.log_group_name
  
  pattern = "[domain_added]"
  
  metric_transformation {
    name      = "DomainCount"
    namespace = "NEO/Quotas"
    value     = "1"
    
    dimensions = {
      Customer = var.customer_id
      Plan     = local.plan.slug
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "domain_limit" {
  count = var.enable_quota_monitoring && local.limits.domains > 0 ? 1 : 0
  
  alarm_name          = "${var.customer_id}-domain-limit-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DomainCount"
  namespace           = "NEO/Quotas"
  period              = 300
  statistic           = "Sum"
  threshold           = local.limits.domains
  alarm_description   = "Domain limit exceeded for ${var.customer_id}"
  
  dimensions = {
    Customer = var.customer_id
    Plan     = local.plan.slug
  }
  
  alarm_actions = var.quota_alarm_actions
}

# ================================================================
# OUTPUTS
# ================================================================

output "plan_name" {
  description = "Plan name"
  value       = local.plan.name
}

output "plan_specs" {
  description = "Plan specifications"
  value       = local.specs
}

output "plan_limits" {
  description = "Plan resource limits"
  value       = local.limits
}

output "quota_tags" {
  description = "Tags with quota information"
  value       = local.quota_tags
}

output "terraform_vars" {
  description = "Terraform variables for this plan"
  value       = local.plan.terraform_vars
}
