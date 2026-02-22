# ===================================
# PLANS CONFIGURATION
# ===================================

locals {
  # Load plan configurations
  plan_config = {
    core = {
      instance_type     = "t3.small"
      root_volume_size  = 30
      data_volume_size  = 50
      enable_rds        = false
      backup_retention  = 7
      monitoring        = "basic"
    }
    scale = {
      instance_type     = "t3.medium"
      root_volume_size  = 50
      data_volume_size  = 200
      enable_rds        = true
      rds_instance_class = "db.t3.micro"
      rds_storage_gb    = 50
      backup_retention  = 30
      monitoring        = "detailed"
    }
    titan = {
      instance_type     = "t3.large"
      root_volume_size  = 100
      data_volume_size  = 500
      enable_rds        = true
      rds_instance_class = "db.t3.small"
      rds_storage_gb    = 200
      rds_multi_az      = true
      backup_retention  = 90
      monitoring        = "premium"
    }
  }
  
  selected = local.plan_config[var.selected_plan]
}
