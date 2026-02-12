# ===================================
# BACKEND OUTPUTS
# ===================================

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.arn
}

output "backend_configuration" {
  description = "Backend configuration to use in customer deployments"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    region         = var.region
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    encrypt        = true
  }
}

output "setup_complete" {
  description = "Confirmation message"
  value       = "✅ Backend infrastructure created successfully! Use the output values to configure customer deployments."
}
