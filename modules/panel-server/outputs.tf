# ===================================
# MULTI-PANEL SERVER MODULE - OUTPUTS
# Neo VPS Provisioning System v3.0
# ===================================

# ===================================
# LOCALS (Refactored Logic)
# ===================================

locals {
  server_ip = var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : aws_instance.panel_server.public_ip

  panel_ports = {
    cyberpanel  = 8090
    cpanel      = 2087
    directadmin = 2222
  }

  panel_port = lookup(local.panel_ports, var.control_panel, null)

  panel_url = local.panel_port != null ? "https://${local.server_ip}:${local.panel_port}" : null

  ssh_base_command = "ssh root@${local.server_ip}"
}

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
  description = "Availability zone"
  value       = aws_instance.panel_server.availability_zone
}

# ===================================
# NETWORK INFORMATION
# ===================================

output "public_ip" {
  value = local.server_ip
}

output "private_ip" {
  value = aws_instance.panel_server.private_ip
}

output "elastic_ip" {
  value = var.allocate_elastic_ip ? aws_eip.panel_server[0].public_ip : null
}

# ===================================
# CONTROL PANEL
# ===================================

output "control_panel" {
  value = var.control_panel
}

output "control_panel_url" {
  value = local.panel_url != null ? local.panel_url : "No control panel installed"
}

output "panel_hostname" {
  value = local.panel_hostname
}

# ===================================
# ACCESS
# ===================================

output "ssh_command" {
  value = var.create_key_pair || var.existing_key_pair != "" ?
    "${local.ssh_base_command}" :
    "Use SSM Session Manager"
}

output "ssm_connect_command" {
  value = "aws ssm start-session --target ${aws_instance.panel_server.id}"
}

# ===================================
# STORAGE
# ===================================

output "root_volume_id" {
  value = aws_instance.panel_server.root_block_device[0].volume_id
}

output "data_volume_id" {
  value = aws_ebs_volume.data.id
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backups.id
}

output "backup_bucket_arn" {
  value = aws_s3_bucket.backups.arn
}

# ===================================
# IAM
# ===================================

output "iam_role_arn" {
  value = aws_iam_role.panel_server.arn
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.panel_server.arn
}

# ===================================
# MONITORING
# ===================================

output "cloudwatch_dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}"
}

output "ec2_console_url" {
  value = "https://console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.name}#Instances:instanceId=${aws_instance.panel_server.id}"
}

# ===================================
# SERVER SUMMARY
# ===================================

output "server_summary" {
  value = {
    domain         = var.customer_domain
    customer_id    = var.customer_id
    control_panel  = var.control_panel
    instance_type  = aws_instance.panel_server.instance_type
    public_ip      = local.server_ip
    panel_url      = local.panel_url
    ssh_command    = local.ssh_base_command
    instance_id    = aws_instance.panel_server.id
    backup_bucket  = aws_s3_bucket.backups.id
    instance_state = aws_instance.panel_server.instance_state
  }
}

# ===================================
# NEXT STEPS
# ===================================

output "next_steps" {
  value = <<-EOT
===================================
🚀 Deployment Complete
===================================

Server IP: ${local.server_ip}
Control Panel: ${var.control_panel}

Access Panel:
${local.panel_url != null ? local.panel_url : "No panel installed"}

SSH:
${local.ssh_base_command}

Logs:
tail -f /var/log/neo-vps-setup.log

Next:
1. Point DNS to ${local.server_ip}
2. Configure SSL
3. Harden firewall rules
4. Setup monitoring alerts

===================================
Neo VPS v3.0
===================================
EOT
}
