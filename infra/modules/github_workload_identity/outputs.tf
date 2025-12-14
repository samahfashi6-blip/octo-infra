output "workload_identity_provider" {
  description = "The full workload identity provider resource name"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  description = "Service account email for GitHub Actions"
  value       = var.service_account_id
}

output "pool_name" {
  description = "Workload Identity Pool name"
  value       = google_iam_workload_identity_pool.github_pool.name
}
