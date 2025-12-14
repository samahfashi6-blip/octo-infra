resource "google_cloudfunctions2_function" "this" {
  name     = var.name
  project  = var.project_id
  location = var.region

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = var.source_bucket
        object = var.source_object
      }
    }
  }

  service_config {
    service_account_email = var.service_account_email
    
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances
    
    available_memory   = var.memory
    timeout_seconds    = var.timeout_seconds
    
    environment_variables = var.env_vars
  }

  dynamic "event_trigger" {
    for_each = var.trigger_config != null ? [var.trigger_config] : []
    content {
      trigger_region        = var.region
      event_type            = event_trigger.value.event_type
      retry_policy          = event_trigger.value.retry_policy
      service_account_email = var.service_account_email

      event_filters {
        attribute = "bucket"
        value     = event_trigger.value.bucket
      }
    }
  }
}
