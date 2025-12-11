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
