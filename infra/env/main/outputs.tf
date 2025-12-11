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
