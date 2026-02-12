# ===================================
# MULTI-PANEL SERVER MODULE - OUTPUTS
# Neo VPS Provisioning System v2.0
# ===================================

# ===================================
# INSTANCE INFORMATION
# ===================================

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.panel_server.id
}

output "instance_state" {
  description = "EC2 Instance state"
  value       = aws_instance.panel_server.instance_state
}

output "instance_type" {
  description = "EC2 Instance type"
  value       = aws_instance.panel_server.instance_type
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.panel_server.availability_zone
}

# ===================================
# NETWORK INFORMATION
# ===================================

output "public_ip" {
  description = "Public IP address"
  value       = var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.panel_server.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if allocated)"
  value       = var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : null
}

# ===================================
# CONTROL PANEL INFORMATION
# ===================================

output "control_panel" {
  description = "Installed control panel"
  value       = var.control_panel
}

output "control_panel_url" {
  description = "Control panel access URL"
  value = var.control_panel == "cyberpanel" ? "https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:8090" : (
    var.control_panel == "cpanel" ? "https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:2087" : (
      var.control_panel == "directadmin" ? "https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:2222" :
      "No control panel installed"
    )
  )
}

output "panel_hostname" {
  description = "Panel hostname"
  value       = local.panel_hostname
}

# ===================================
# ACCESS INFORMATION
# ===================================

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value = var.create_key_pair || var.existing_key_pair != "" ? "ssh -i ~/.ssh/${var.create_key_pair ? aws_key_pair.panel_server[0].key_name : var.existing_key_pair}.pem root@${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}" : "Use SSM Session Manager or configure SSH key"
}

output "ssm_connect_command" {
  description = "AWS SSM Session Manager connect command"
  value       = "aws ssm start-session --target ${aws_instance.panel_server.id}"
}

# ===================================
# STORAGE INFORMATION
# ===================================

output "root_volume_id" {
  description = "Root EBS volume ID"
  value       = aws_instance.panel_server.root_block_device[0].volume_id
}

output "data_volume_id" {
  description = "Data EBS volume ID"
  value       = aws_ebs_volume.data.id
}

output "backup_bucket_name" {
  description = "S3 backup bucket name"
  value       = aws_s3_bucket.backups.id
}

output "backup_bucket_arn" {
  description = "S3 backup bucket ARN"
  value       = aws_s3_bucket.backups.arn
}

# ===================================
# IAM INFORMATION
# ===================================

output "iam_role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.panel_server.arn
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = aws_iam_instance_profile.panel_server.arn
}

# ===================================
# MONITORING INFORMATION
# ===================================

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#metricsV2:graph=~();query=~'*7bAWS*2fEC2*2cInstanceId*7d*20${aws_instance.panel_server.id}"
}

output "ec2_console_url" {
  description = "EC2 console URL"
  value       = "https://console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.name}#Instances:instanceId=${aws_instance.panel_server.id}"
}

# ===================================
# COMPLETE SUMMARY
# ===================================

output "server_summary" {
  description = "Complete server information summary"
  value = {
    # Basic Info
    domain         = var.customer_domain
    customer_id    = var.customer_id
    control_panel  = var.control_panel
    instance_type  = aws_instance.panel_server.instance_type
    
    # Access
    public_ip      = var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip
    panel_url      = var.control_panel == "cyberpanel" ? "https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:8090" : (
      var.control_panel == "cpanel" ? "https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:2087" : (
        var.control_panel == "directadmin" ? "https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:2222" :
        "N/A"
      )
    )
    ssh_command    = var.create_key_pair || var.existing_key_pair != "" ? "ssh root@${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}" : "Use SSM"
    
    # Resources
    instance_id    = aws_instance.panel_server.id
    backup_bucket  = aws_s3_bucket.backups.id
    
    # Status
    instance_state = aws_instance.panel_server.instance_state
  }
}

# ===================================
# POST-DEPLOYMENT INSTRUCTIONS
# ===================================

output "next_steps" {
  description = "Next steps after deployment"
  value = var.control_panel == "cyberpanel" ? <<-EOT
    ===================================
    🎉 CyberPanel Installation Started
    ===================================
    
    Installation will take 15-20 minutes.
    
    1. Wait for installation to complete
    2. Access: https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:8090
    3. Username: admin
    4. Password: SSH to server and run: cat /root/.cyberpanel_password
    5. Configure DNS to point to: ${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}
    6. Install SSL certificates via Let's Encrypt
    
    Monitor installation: ssh root@${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}
    Then run: tail -f /var/log/neo-vps-setup.log
  EOT
  : var.control_panel == "cpanel" ? <<-EOT
    ===================================
    🎉 cPanel/WHM Installation Started
    ===================================
    
    Installation will take 60-90 minutes.
    
    1. Wait for installation to complete
    2. Access: https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:2087
    3. Username: root
    4. Password: SSH to server and run: cat /root/.whm_password
    5. Complete initial setup wizard
    6. Add your cPanel license
    7. Configure DNS to point to: ${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}
    
    ⚠️ cPanel requires a valid license!
    Get one at: https://cpanel.net/pricing/
    
    Monitor installation: ssh root@${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}
    Then run: tail -f /var/log/neo-vps-setup.log
  EOT
  : var.control_panel == "directadmin" ? <<-EOT
    ===================================
    🎉 DirectAdmin Preparation Complete
    ===================================
    
    Manual installation required.
    
    1. SSH to server: ssh root@${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}
    2. Get a license at: https://www.directadmin.com/trial.php
    3. Read installation guide: cat /root/DIRECTADMIN_INSTALL_GUIDE.txt
    4. Run installer: cd /root/directadmin && ./setup.sh
    5. Follow prompts with your license info
    
    After installation:
    Access: https://${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}:2222
  EOT
  : <<-EOT
    ===================================
    🎉 Clean Server Setup Complete
    ===================================
    
    Your server is ready for custom configuration.
    
    SSH Access: ssh root@${var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip}
    
    Installed:
    ✓ Essential tools
    ✓ Firewall configured
    ✓ Fail2Ban enabled
    ✓ Auto security updates
    ✓ System optimizations
    
    Next steps:
    1. Install your web server (Nginx/Apache)
    2. Install database (MySQL/PostgreSQL)
    3. Install runtime (PHP/Python/Node.js)
    4. Deploy your application
    
    Read welcome guide: cat /root/WELCOME.txt
  EOT
}
