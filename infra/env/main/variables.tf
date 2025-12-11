variable "project_id" {
  default = "octo-education-ddc76"
}

variable "region" {
  default = "us-central1"
}

# Service URLs for inter-service communication
# Note: CIE API URL is now managed by Terraform module output

variable "curriculum_api_url" {
  description = "Curriculum API service URL"
  type        = string
  default     = "https://curriculum-service-placeholder.run.app"
}

variable "auditor_service_url" {
  description = "Auditor service URL"
  type        = string
  default     = "https://auditor-service-placeholder.run.app"
}

# Note: Math and Physics MCP URLs are now managed by Terraform module outputs

variable "chem_mcp_url" {
  description = "Chemistry MCP service URL"
  type        = string
  default     = "https://chem-expert-placeholder.run.app"
}
