resource "google_pubsub_subscription" "this" {
  name    = var.name
  project = var.project_id
  topic   = var.topic

  dynamic "push_config" {
    for_each = var.push_endpoint != null ? [1] : []
    content {
      push_endpoint = var.push_endpoint

      dynamic "oidc_token" {
        for_each = var.push_service_account_email != null ? [1] : []
        content {
          service_account_email = var.push_service_account_email
        }
      }
    }
  }

  ack_deadline_seconds = var.ack_deadline_seconds

  dynamic "retry_policy" {
    for_each = var.min_retry_backoff != null ? [1] : []
    content {
      minimum_backoff = var.min_retry_backoff
      maximum_backoff = var.max_retry_backoff
    }
  }
}
