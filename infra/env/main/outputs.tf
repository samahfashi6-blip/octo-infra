# ==============================================================================
# Outputs
# ==============================================================================

output "ai_mentor_service_url" {
  description = "URL of the AI Mentor service"
  value       = module.ai_mentor_service.url
}

output "ai_mentor_service_account_email" {
  description = "Email of the AI Mentor service account"
  value       = module.sa_ai_mentor.email
}

output "cie_api_service_url" {
  description = "URL of the CIE API service"
  value       = module.cie_api_service.url
}

output "cie_worker_service_url" {
  description = "URL of the CIE Worker service"
  value       = module.cie_worker_service.url
}

output "cie_api_service_account_email" {
  description = "Email of the CIE API service account"
  value       = module.sa_cie_api.email
}

output "cie_worker_service_account_email" {
  description = "Email of the CIE Worker service account"
  value       = module.sa_cie_worker.email
}

output "math_mcp_service_url" {
  description = "URL of the Mathematics MCP service"
  value       = module.mathematic_service.url
}

output "math_mcp_service_account_email" {
  description = "Email of the Mathematics service account"
  value       = module.sa_mathematic_service.email
}

output "physics_python_sidecar_url" {
  description = "URL of the Physics Python Sidecar service"
  value       = module.physics_python_sidecar.url
}

output "physics_gateway_url" {
  description = "URL of the Physics Gateway service"
  value       = module.physics_gateway.url
}

output "physics_service_account_email" {
  description = "Email of the Physics service account"
  value       = module.sa_physics_service.email
}

output "squad_service_url" {
  description = "URL of the Squad service"
  value       = module.squad_service.url
}

output "squad_service_account_email" {
  description = "Email of the Squad service account"
  value       = module.sa_squad_service.email
}

output "chemistry_python_sidecar_url" {
  description = "URL of the Chemistry Python Sidecar service"
  value       = module.chemistry_python_sidecar.url
}

output "chemistry_gateway_url" {
  description = "URL of the Chemistry Gateway service"
  value       = module.chemistry_gateway.url
}

output "chemistry_service_account_email" {
  description = "Email of the Chemistry service account"
  value       = module.sa_chemistry_service.email
}

output "core_admin_api_url" {
  description = "URL of the Core Admin API service"
  value       = module.core_admin_api.url
}

output "core_admin_api_service_account_email" {
  description = "Email of the Core Admin API service account"
  value       = module.sa_core_admin_api.email
}

output "curriculum_service_url" {
  description = "URL of the Curriculum Service"
  value       = module.curriculum_service.url
}

output "curriculum_service_account_email" {
  description = "Email of the Curriculum Service account"
  value       = module.sa_curriculum_service.email
}

output "core_admin_webapp_url" {
  description = "URL of the Core Admin Web App"
  value       = module.core_admin_webapp.url
}

output "core_admin_webapp_service_account_email" {
  description = "Email of the Core Admin Web App service account"
  value       = module.sa_core_admin_webapp.email
}

# Curriculum Ingestion Outputs
output "curriculum_ingestion_function_name" {
  description = "Name of the Curriculum Ingestion Cloud Function"
  value       = module.curriculum_ingestion_function.function_name
}

output "curriculum_ingestion_service_account_email" {
  description = "Email of the Curriculum Ingestion service account"
  value       = module.sa_curriculum_ingestion.email
}

output "curriculum_pdf_uploads_bucket" {
  description = "Name of the bucket for PDF uploads"
  value       = module.curriculum_pdf_uploads_bucket.name
}

output "curriculum_processing_results_bucket" {
  description = "Name of the bucket for processing results"
  value       = module.curriculum_processing_results_bucket.name
}

output "curriculum_function_source_bucket" {
  description = "Name of the bucket for Cloud Function source code"
  value       = module.curriculum_function_source_bucket.name
}
