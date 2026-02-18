# ================================================================
# BACKEND OUTPUTS
# ================================================================

output "state_bucket_name" {
  description = "Primary state bucket name"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "Primary state bucket ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_region" {
  description = "Primary state bucket region"
  value       = var.primary_region
}

output "dr_bucket_name" {
  description = "DR backup bucket name"
  value       = aws_s3_bucket.terraform_state_dr.id
}

output "dr_bucket_arn" {
  description = "DR backup bucket ARN"
  value       = aws_s3_bucket.terraform_state_dr.arn
}

output "dr_bucket_region" {
  description = "DR backup bucket region"
  value       = var.dr_region
}

output "lock_table_name" {
  description = "DynamoDB lock table name"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "lock_table_arn" {
  description = "DynamoDB lock table ARN"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "backend_config" {
  description = "Backend configuration template"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "YOUR_KEY_HERE/terraform.tfstate"
        region         = "${var.primary_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.id}"
        encrypt        = true
      }
    }
  EOT
}
