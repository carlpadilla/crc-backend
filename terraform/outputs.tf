output "container_app_url" {
  value = azurerm_container_app.backend.latest_revision_fqdn
}

output "storage_account_name" {
  value = azurerm_storage_account.backend.name
}

output "table_name" {
  value = azurerm_storage_table.pageviews.name
}

output "github_identity_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

output "storage_connection_string" {
  value     = azurerm_storage_account.backend.primary_connection_string
  sensitive = true
}

