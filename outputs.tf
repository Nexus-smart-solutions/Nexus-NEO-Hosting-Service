output "customer_summary" {
  value = {
    customer_id   = var.customer_id
    domain        = var.customer_domain
    control_panel = var.control_panel
    instance_type = var.instance_type
  }
}
