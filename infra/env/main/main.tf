# ==============================================================================
# Main Environment Configuration
# ==============================================================================
# This is where you instantiate your modules to create actual infrastructure.
# Each module call creates a set of resources in your GCP project.
#
# PASTE YOUR MODULE INSTANTIATIONS HERE
# ==============================================================================

# Example: Cloud Run Service
# module "api_service" {
#   source = "../../modules/cloud_run_service"
#
#   project_id              = var.project_id
#   region                  = var.region
#   service_name            = "api-service"
#   image                   = "gcr.io/${var.project_id}/api-service:latest"
#   cpu                     = "1"
#   memory                  = "512Mi"
#   concurrency             = 80
#   min_instances           = 1
#   max_instances           = 10
#   service_account_email   = module.api_service_account.email
#   allow_unauthenticated   = false
#
#   env_vars = {
#     ENVIRONMENT = "production"
#     PROJECT_ID  = var.project_id
#   }
# }

# Example: Service Account
# module "api_service_account" {
#   source = "../../modules/service_account"
#
#   project_id   = var.project_id
#   account_id   = "api-service"
#   display_name = "API Service Account"
#   description  = "Service account for API Cloud Run service"
#
#   roles = [
#     "roles/pubsub.publisher",
#     "roles/storage.objectViewer",
#   ]
# }

# Example: Pub/Sub Topic
# module "events_topic" {
#   source = "../../modules/pubsub_topic"
#
#   project_id                 = var.project_id
#   topic_name                 = "events-topic"
#   message_retention_duration = "604800s"
#
#   labels = {
#     environment = "production"
#   }
# }

# Example: Pub/Sub Push Subscription with OIDC
# module "events_subscription" {
#   source = "../../modules/pubsub_subscription"
#
#   project_id                   = var.project_id
#   subscription_name            = "events-subscription"
#   topic_name                   = module.events_topic.topic_name
#   ack_deadline_seconds         = 10
#   push_endpoint                = "${module.api_service.service_url}/webhook"
#   oidc_token_audience          = module.api_service.service_url
#   oidc_service_account_email   = module.api_service_account.email
# }

# Example: Cloud Storage Bucket
# module "data_bucket" {
#   source = "../../modules/bucket"
#
#   project_id                  = var.project_id
#   bucket_name                 = "${var.project_id}-data-bucket"
#   location                    = var.region
#   storage_class               = "STANDARD"
#   versioning_enabled          = true
#   uniform_bucket_level_access = true
#
#   lifecycle_rules = [
#     {
#       action = {
#         type          = "SetStorageClass"
#         storage_class = "NEARLINE"
#       }
#       condition = {
#         age = 30
#       }
#     },
#     {
#       action = {
#         type = "Delete"
#       }
#       condition = {
#         age = 90
#       }
#     }
#   ]
#
#   labels = {
#     environment = "production"
#   }
# }
