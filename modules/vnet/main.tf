
resource "azurerm_virtual_network" "mentorklub" {
  name                = "${var.main_resource_group_name}-${var.vnet_name_suffix}"
  location            = var.location
  resource_group_name = var.main_resource_group_name
  address_space       = var.vnet_address_space
  tags = var.tags

  depends_on = [ var.main_resource_group_name ]
}

# Add resource lock on vnet
resource "azurerm_management_lock" "mentorklub_vnet_lock" {
  name       = "DeleteLockMentorKlubVNET"
  scope      = azurerm_virtual_network.mentorklub.id
  lock_level = "CanNotDelete"
  notes      = "This lock is to prevent user deletion of the MentorKlub VNET"

  timeouts {
    delete = "30m" # Extend delete timeout from the default (which is lower)
    create = "30m" # Extend create timeout from the default (which is lower)
  }
}

resource "azurerm_subnet" "primary_subnet" {
  name                 = "${var.subnet_1_name}"
  resource_group_name  = var.main_resource_group_name
  virtual_network_name = azurerm_virtual_network.mentorklub.name
  address_prefixes     = ["${var.subnet_address_prefix}"]
}


resource "azurerm_network_security_group" "mentorklub_nsg" {
  name                = "${var.main_resource_group_name}-${var.vnet_name_suffix}-${var.nsg_name_suffix}"
  location            = var.location
  resource_group_name = var.main_resource_group_name

  dynamic "security_rule" {

    for_each = jsondecode(file("../../files/security_rules.json"))
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }

  tags = var.tags

  depends_on = [ azurerm_subnet.primary_subnet ]
}

# Add resource lock on nsg
resource "azurerm_management_lock" "mentorklub_vnet_nsg_lock" {
  name       = "DeleteLockMentorKlubVNETNSG"
  scope      = azurerm_network_security_group.mentorklub_nsg.id
  lock_level = "CanNotDelete"
  notes      = "This lock is to prevent user deletion of the MentorKlub VNET NSG"

  timeouts {
    delete = "30m" # Extend delete timeout from the default (which is lower)
    create = "30m" # Extend create timeout from the default (which is lower)
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.primary_subnet.id
  network_security_group_id = azurerm_network_security_group.mentorklub_nsg.id
}
