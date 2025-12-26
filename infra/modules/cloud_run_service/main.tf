resource "google_cloud_run_v2_service" "this" {
  count    = var.ignore_image_changes ? 1 : 0
  name     = var.name
  project  = var.project_id
  location = var.region

  template {
    service_account = var.service_account_email

    containers {
      image = var.image

      resources {
        cpu_idle = true
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    max_instance_request_concurrency = var.concurrency
  }

  ingress = var.ingress

  lifecycle {
    ignore_changes = [
      # Allow CI/CD to manage the container image without Terraform reverting deployments
      template[0].containers[0].image,
    ]
  }
}

resource "google_cloud_run_v2_service" "this_image_managed" {
  count    = var.ignore_image_changes ? 0 : 1
  name     = var.name
  project  = var.project_id
  location = var.region

  template {
    service_account = var.service_account_email

    containers {
      image = var.image

      resources {
        cpu_idle = true
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    max_instance_request_concurrency = var.concurrency
  }

  ingress = var.ingress
}

locals {
  service_name = var.ignore_image_changes ? google_cloud_run_v2_service.this[0].name : google_cloud_run_v2_service.this_image_managed[0].name
  service_uri  = var.ignore_image_changes ? google_cloud_run_v2_service.this[0].uri : google_cloud_run_v2_service.this_image_managed[0].uri
}

# Allow public access if ingress allows all traffic
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.ingress == "INGRESS_TRAFFIC_ALL" ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = local.service_name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
