########################################
# LOCALS
########################################

locals {
  project_id = var.project_id
  region     = var.region
}

########################################
# 0. ENABLE CORE APIS (AI Mentor Only)
########################################

resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "firestore.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])

  project            = local.project_id
  service            = each.key
  disable_on_destroy = false
}

########################################
# 3. SERVICE ACCOUNTS (AI Mentor Only)
########################################

module "sa_ai_mentor" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-ai-mentor-service"
  display_name = "AI Mentor Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/secretmanager.secretAccessor",
    "roles/run.invoker",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}

########################################
# 4. CLOUD RUN SERVICES (AI Mentor Only)
########################################

# AI Mentor Service
module "ai_mentor_service" {
  source   = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "ai-mentor-service"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/ai-mentor-service:latest"
  service_account_email = module.sa_ai_mentor.email

  cpu           = "2"
  memory        = "1Gi"
  concurrency   = 80
  min_instances = 1
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    GCP_PROJECT_ID       = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    GEMINI_PROJECT_ID    = "octo-education-ddc76"

    CIE_API_URL        = var.cie_api_url
    CURRICULUM_API_URL = var.curriculum_api_url
    AUDITOR_SERVICE_URL = var.auditor_service_url

    MATH_MCP_URL    = var.math_mcp_url
    PHYSICS_MCP_URL = var.physics_mcp_url
    CHEM_MCP_URL    = var.chem_mcp_url

    FIRESTORE_COLLECTION = "mentor/sessions"
    MCP_ENABLED          = "true"
    GEMINI_ENABLED       = "true"
  }
}
