variable "project_id" {
  default = "octo-education-ddc76"
}

variable "region" {
  default = "us-central1"
}

# Service URLs for inter-service communication
variable "cie_api_url" {
  description = "CIE API service URL"
  type        = string
  default     = "https://cie-api-service-placeholder.run.app"
}

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

variable "math_mcp_url" {
  description = "Math MCP service URL"
  type        = string
  default     = "https://math-expert-placeholder.run.app"
}

variable "physics_mcp_url" {
  description = "Physics MCP service URL"
  type        = string
  default     = "https://physics-expert-placeholder.run.app"
}

variable "chem_mcp_url" {
  description = "Chemistry MCP service URL"
  type        = string
  default     = "https://chem-expert-placeholder.run.app"
}
