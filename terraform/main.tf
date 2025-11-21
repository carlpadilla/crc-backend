# Resource Group
resource "azurerm_resource_group" "backend" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics (needed by ACA)
resource "azurerm_log_analytics_workspace" "backend" {
  name                = "${var.resource_group_name}-log"
  location            = azurerm_resource_group.backend.location
  resource_group_name = azurerm_resource_group.backend.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_registry" "backend" {
  name                = "acrcrcbackend"
  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location
  sku                 = "Basic"

  admin_enabled = false
}

# Container Apps Environment
resource "azurerm_container_app_environment" "backend" {
  name                = "${var.resource_group_name}-env"
  location            = azurerm_resource_group.backend.location
  resource_group_name = azurerm_resource_group.backend.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.backend.id
}

# Storage for Page Views Table
resource "azurerm_storage_account" "backend" {
  name                     = "stcrcbackend"
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_table" "pageviews" {
  name                 = "PageViews"
  storage_account_name = azurerm_storage_account.backend.name
}

# ⭐ GitHub OIDC Identity
resource "azurerm_federated_identity_credential" "github" {
  name                = "github-oidc"
  resource_group_name = azurerm_resource_group.backend.name
  parent_id           = azurerm_user_assigned_identity.github.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repo}:ref:refs/heads/main"
}

# Identity for GitHub Actions
resource "azurerm_user_assigned_identity" "github" {
  name                = "${var.resource_group_name}-github-identity"
  resource_group_name = azurerm_resource_group.backend.name
  location            = azurerm_resource_group.backend.location
}

# Allow GitHub Actions to write container revisions & manage ACA
resource "azurerm_role_assignment" "github_aca" {
  scope                = azurerm_container_app_environment.backend.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_role_assignment" "github_storage" {
  scope                = azurerm_storage_account.backend.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

# Placeholder Container App
resource "azurerm_container_app" "backend" {
  name                         = "crc-backend-api"
  resource_group_name          = azurerm_resource_group.backend.name
  container_app_environment_id = azurerm_container_app_environment.backend.id

  revision_mode = "Single"

  template {
    container {
      name   = "backend"
      image  = "mcr.microsoft.com/azure-functions/python:4-python3.10" # temporary
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
