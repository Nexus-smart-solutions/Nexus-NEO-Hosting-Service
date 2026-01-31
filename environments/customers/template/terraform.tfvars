# terraform.tfvars

customer_domain  = "cpanel.example.com"
environment      = "production"
region           = "us-east-2"
instance_type    = "t3.medium"
data_volume_size = 100
admin_email      = "admin@example.com"

tags = {
  Customer      = "example.com"
  ClientID      = "test_001"
  Tier          = "standard"
  ManagedBy     = "GitHub-Actions"
  ProvisionedAt = "2024-01-31T00:00:00Z"
}
