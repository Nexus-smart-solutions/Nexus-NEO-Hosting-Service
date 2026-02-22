# ===================================
# MARKETPLACE ADD-ONS
# ===================================

locals {
  # Parse add-ons configuration from YAML
  # Note: You'll need to convert YAML to HCL or use data "external"
  
  available_addons = {
    "storage-ebs-100" = {
      module_path = "marketplace/modules/storage/ebs-expansion"
      config = {
        size_gb = 100
        volume_type = "gp3"
        iops = 3000
      }
    }
    "storage-s3-500" = {
      module_path = "marketplace/modules/storage/s3-bucket"
      config = {
        size_gb = 500
        versioning = true
      }
    }
    # Add more add-ons as needed
  }
  
  enabled_addons = var.enable_marketplace ? [
    for addon_id in var.selected_addons : local.available_addons[addon_id]
    if contains(keys(local.available_addons), addon_id)
  ] : []
}

# Dynamic creation of add-on modules
# This requires creating separate module files for each add-on type
