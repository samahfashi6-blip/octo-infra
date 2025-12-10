resource "google_storage_bucket" "this" {
  name                        = var.name
  project                     = var.project_id
  location                    = var.location
  uniform_bucket_level_access = true

  versioning {
    enabled = var.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.delete_after_days > 0 ? [1] : []
    content {
      action { type = "Delete" }
      condition { age = var.delete_after_days }
    }
  }
}
