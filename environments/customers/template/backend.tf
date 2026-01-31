# ===================================
# BACKEND CONFIGURATION
# ===================================
# Backend is configured via workflow using -backend-config flags
# This file intentionally left minimal to avoid conflicts

terraform {
  backend "s3" {}
}
