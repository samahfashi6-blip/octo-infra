output "function_name" {
  description = "Name of the Cloud Function"
  value       = google_cloudfunctions2_function.this.name
}

output "function_url" {
  description = "URL of the Cloud Function (if HTTP trigger)"
  value       = try(google_cloudfunctions2_function.this.service_config[0].uri, "")
}

output "id" {
  description = "ID of the Cloud Function"
  value       = google_cloudfunctions2_function.this.id
}
