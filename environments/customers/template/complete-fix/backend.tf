# ===================================
# BACKEND CONFIGURATION
# ===================================
# This will be generated dynamically by GitHub Actions
# DO NOT MODIFY - This is a template

terraform {
  backend "s3" {
    # These values will be replaced by GitHub Actions:
    # bucket         = "YOUR-STATE-BUCKET-NAME"
    # key            = "customers/CUSTOMER-DOMAIN/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "YOUR-LOCK-TABLE-NAME"
    # encrypt        = true
  }
}
