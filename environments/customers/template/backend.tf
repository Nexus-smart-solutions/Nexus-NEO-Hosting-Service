# =================================================================
# S3 BACKUP BUCKET LIFECYCLE
# =================================================================

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count  = var.enable_backups ? 1 : 0
  bucket = aws_s3_bucket.backups.id
  
  rule {
    id     = "delete-old-backups"
    status = "Enabled"
    
    # Add this filter block to apply to all objects in the bucket
    filter {}

    expiration {
      days = var.backup_retention_days
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
