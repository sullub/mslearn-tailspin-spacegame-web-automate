provider "azurerm" {
version = "~> 1.44"
}
terraform {
  required_version = "> 0.12.0"
   backend "azurerm" {
  }
}

variable "resource_group_name" {
  default = "tailspin-space-game-rg"
  description = "The name of the resource group"
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "app_service_plan_name" {
  default = "tailspin-space-game-asp"
  description = "The name of the app service plan"
}

variable "app_service_name_prefix" {
  default = "tailspin-space-game-web"
  description = "The beginning part of your App Service host name"
}

resource "random_integer" "app_service_name_suffix" {
  min = 1000
  max = 9999
}

locals {
  full_rg_name = "ask-${terraform.workspace}-${var.resource_group_name}"
  full_app_service_name = "${terraform.workspace}-${var.app_service_plan_name}"
}


resource "azurerm_resource_group" "spacegame" {
  name     = local.full_rg_name
  location = var.location

  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_app_service_plan" "spacegame" {
  name                = local.full_app_service_name
  location            = var.location
  resource_group_name = azurerm_resource_group.spacegame.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "spacegame" {
  name                = "${local.full_app_service_name}-${random_integer.app_service_name_suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spacegame.name
  app_service_plan_id = azurerm_app_service_plan.spacegame.id

  site_config {
    linux_fx_version = "DOTNETCORE|3.1"
    app_command_line = "dotnet Tailspin.SpaceGame.Web.dll"
  }
}

output "appservice_name" {
  value       = "${azurerm_app_service.spacegame.name}"
  description = "The App Service name for the current environment"
}
output "website_hostname" {
  value       = "${azurerm_app_service.spacegame.default_site_hostname}"
  description = "The hostname of the website in the current environment"
}


