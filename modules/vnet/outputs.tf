output "vnet_id" {
  value = azurerm_virtual_network.mentorklub.id
}

output "subnet_id" {
  value = azurerm_subnet.primary_subnet.id

}
