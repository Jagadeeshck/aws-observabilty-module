output "selected_services" {
  description = "Supported services selected by enabled and scope."
  value       = local.selected_services
}

output "inventory_resource_counts" {
  description = "Number of inventory entries supplied per supported service."
  value       = { for service in local.supported_services : service => length(try(local.inventory[service], {})) }
}
