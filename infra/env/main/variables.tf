variable "project_id" {
  default = "octo-education-ddc76"
}

variable "region" {
  default = "us-central1"
}

# Service URLs for inter-service communication
# Note: CIE API URL is now managed by Terraform module output

variable "auditor_service_url" {
  description = "Auditor service URL"
  type        = string
  default     = "https://auditor-service-placeholder.run.app"
}

variable "core_admin_auth_admin_impersonators" {
  description = "IAM member strings allowed to impersonate sa-core-admin-auth-admin via roles/iam.serviceAccountTokenCreator (prefer group:... over user:...)."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for member in var.core_admin_auth_admin_impersonators : can(regex("^(group|user|serviceAccount):[^\\s]+$", member))
    ])
    error_message = "Each entry in core_admin_auth_admin_impersonators must be a valid IAM member string with a prefix: group:<email>, user:<email>, or serviceAccount:<email>. Example: [\"group:core-admin-webapp-admins@company.com\"]."
  }
}

variable "document_ai_processor_name" {
  description = "Full Document AI processor resource name (e.g., projects/PROJECT_ID/locations/LOCATION/processors/PROCESSOR_ID)"
  type        = string

  validation {
    condition     = can(regex("^projects/[^/]+/locations/[^/]+/processors/[^/]+$", var.document_ai_processor_name))
    error_message = "Must be full resource name in format: projects/PROJECT_ID/locations/LOCATION/processors/PROCESSOR_ID"
  }
}

# Note: Math, Physics, and Chemistry MCP URLs are now managed by Terraform module outputs
