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

variable "document_ai_processor_id" {
  description = "Document AI Processor ID for OCR processing"
  type        = string
  default     = "PLACEHOLDER_PROCESSOR_ID" # Update after creating processor in GCP Console
}

# Note: Math, Physics, and Chemistry MCP URLs are now managed by Terraform module outputs
