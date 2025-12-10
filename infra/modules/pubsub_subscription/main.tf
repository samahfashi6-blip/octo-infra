resource "google_pubsub_subscription" "this" {
  name    = var.name
  project = var.project_id
  topic   = var.topic

  push_config {
    push_endpoint = var.push_endpoint

    oidc_token {
      service_account_email = var.push_service_account_email
    }
  }

  ack_deadline_seconds = 10
}
