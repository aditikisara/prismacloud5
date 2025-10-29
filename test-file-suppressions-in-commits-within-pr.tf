resource "azurerm_container_registry" "acr-ab" {
  lifecycle {
    precondition {
      condition = (lower(data.azurerm_resource_group.rg.tags["environment"]) != "production") ? true : (length(var.georeplication_locations) > 0)
      error_message = "The production ACRs must have at least one georeplication_locations list entry"
    }
  }

  sku = "Premium"

  georeplications {
    location = var.location
    zone_redundancy_enabled = true
  }

  trust_policy_enabled = true
  name = var.name
  resource_group_name = data.azurerm_resource_group.rg.name
  location = var.location == "" ? data.azurerm_resource_group.rg.location : var.location
  admin_enabled = false
  public_network_access_enabled = true // test this - CKV_AZURE_139
  tags = local.tags
  anonymous_pull_enabled = false
  quarantine_policy_enabled = true
  data_endpoint_enabled = true

  dynamic "georeplications" {
    for_each = var.georeplication_locations

    content {
      location = georeplications.value
      tags = local.tags
    }
  }

  retention_policy_in_days = var.retention_policy_in_days

  network_rule_set = [
    {
      default_action = "Deny"
      ip_rule = [for ip in module.ab-egress.egresses :
        {
          action = "Allow"
          ip_range = ip
        }
      ]
      virtual_network = [for snet_id in tolist(toset(concat(module.get-azure-subnets.subnet_ids, try(var.allowed_resources.subnets, [])))) :
        {
          action = "Allow"
          subnet_id = snet_id
        }
      ]
    },
  ]
}

