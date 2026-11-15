output "selected_services" { description = "Selected supported services." value = local.selected_services }
output "alerts_enabled" { description = "Whether alarm resources are enabled." value = local.alerts_enabled }
output "inventory_resource_counts" { description = "Inventory entries per service." value = { for service in local.supported_services : service => length(try(local.raw_inventory[service], {})) } }
