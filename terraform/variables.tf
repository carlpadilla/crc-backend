variable "resource_group_name" {
  type        = string
  description = "Name of backend resource group"
}

variable "location" {
  type        = string
  default     = "eastus"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo in owner/repo format"
}
