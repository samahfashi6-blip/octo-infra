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
# 3. SERVICE ACCOUNTS
########################################

# AI Mentor Service Account
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

# CIE API Service Account
module "sa_cie_api" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-cie-api"
  display_name = "CIE API Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/aiplatform.user",
    "roles/secretmanager.secretAccessor"
  ]
}

# CIE Worker Service Account
module "sa_cie_worker" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-cie-worker"
  display_name = "CIE Worker Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/pubsub.subscriber"
  ]
}

# Mathematics Service Account
module "sa_mathematic_service" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-mathematic-service"
  display_name = "Mathematics Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor"
  ]
}

# Physics Service Account
module "sa_physics_service" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-physics-service"
  display_name = "Physics Service Account"
  project_roles = [
    "roles/aiplatform.user",
    "roles/secretmanager.secretAccessor",
    "roles/datastore.user"
  ]
}

# Squad Service Account
module "sa_squad_service" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-squad-service"
  display_name = "Squad Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}

# Chemistry Service Account
module "sa_chemistry_service" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-chemistry-service"
  display_name = "Chemistry Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/aiplatform.user",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor",
    "roles/cloudtrace.admin"
  ]
}

# Core Admin API Service Account
module "sa_core_admin_api" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-core-admin-api"
  display_name = "Core Admin API Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/firebase.admin",
    "roles/bigquery.dataViewer",
    "roles/redis.admin",
    "roles/pubsub.publisher",
    "roles/storage.objectViewer"
  ]
}

# Curriculum Service Account
module "sa_curriculum_service" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-curriculum-service"
  display_name = "Curriculum Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/storage.objectAdmin",
    "roles/pubsub.publisher"
  ]
}

########################################
# 4. CLOUD RUN SERVICES
########################################

# AI Mentor Service
module "ai_mentor_service" {
  source     = "../../modules/cloud_run_service"
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

    CIE_API_URL         = module.cie_api_service.url
    CURRICULUM_API_URL  = module.curriculum_service.url
    AUDITOR_SERVICE_URL = var.auditor_service_url

    MATH_MCP_URL    = module.mathematic_service.url
    PHYSICS_MCP_URL = module.physics_gateway.url
    CHEM_MCP_URL    = module.chemistry_gateway.url

    FIRESTORE_COLLECTION = "mentor/sessions"
    MCP_ENABLED          = "true"
    GEMINI_ENABLED       = "true"
  }
}

# CIE API Service
module "cie_api_service" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "curriculum-intelligence-engine-api"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/curriculum-intelligence-engine-api:latest"
  service_account_email = module.sa_cie_api.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 1
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    REDIS_ENABLED        = "false"
  }
}

# CIE Worker Service
module "cie_worker_service" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "curriculum-intelligence-engine-worker"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/curriculum-intelligence-engine-worker:latest"
  service_account_email = module.sa_cie_worker.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 5
  ingress       = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  env_vars = {
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    REDIS_ENABLED        = "false"
  }
}

# Mathematics Service (MCP Server)
module "mathematic_service" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "mathematic-service"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/mathematic-service:latest"
  service_account_email = module.sa_mathematic_service.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 5
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
  }
}

# Physics Python Sidecar (gRPC Server)
module "physics_python_sidecar" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "physics-python-sidecar"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/physics-python-sidecar:latest"
  service_account_email = module.sa_physics_service.email

  cpu           = "2"
  memory        = "1Gi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  env_vars = {
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    VERTEX_AI_PROJECT_ID = "octo-education-ddc76"
    VERTEX_AI_LOCATION   = "us-central1"
    VERTEX_AI_MODEL      = "gemini-2.0-flash-exp"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    USE_MOCK_LLM         = "false"
    REDIS_ENABLED        = "false"
    GRPC_PORT            = "50051"
  }
}

# Physics Gateway (HTTP API)
module "physics_gateway" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "physics-gateway"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/physics-gateway:latest"
  service_account_email = module.sa_physics_service.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    ENVIRONMENT          = "production"
    PYTHON_SIDECAR_ADDR  = "${module.physics_python_sidecar.url}:50051"
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    REDIS_ENABLED        = "false"
  }
}

# Squad Service
module "squad_service" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "squad-service"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/squad-service:latest"
  service_account_email = module.sa_squad_service.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    ENVIRONMENT          = "production"
  }
}

# Chemistry Python Sidecar (gRPC Server)
module "chemistry_python_sidecar" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "chemistry-python-sidecar"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/chemistry-python-sidecar:latest"
  service_account_email = module.sa_chemistry_service.email

  cpu           = "2"
  memory        = "1Gi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  env_vars = {
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    VERTEX_AI_PROJECT_ID = "octo-education-ddc76"
    VERTEX_AI_LOCATION   = "us-central1"
    VERTEX_AI_MODEL      = "gemini-2.0-flash-exp"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    USE_MOCK_LLM         = "false"
    REDIS_ENABLED        = "false"
    GRPC_PORT            = "50051"
  }
}

# Chemistry Gateway (HTTP API)
module "chemistry_gateway" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "chemistry-gateway"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/chemistry-gateway:latest"
  service_account_email = module.sa_chemistry_service.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    ENVIRONMENT          = "production"
    PYTHON_SIDECAR_ADDR  = "${module.chemistry_python_sidecar.url}:50051"
    GOOGLE_CLOUD_PROJECT = "octo-education-ddc76"
    REDIS_ENABLED        = "false"
  }
}

# Core Admin API
module "core_admin_api" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "core-admin-api"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-api:latest"
  service_account_email = module.sa_core_admin_api.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    GCP_PROJECT_ID = "octo-education-ddc76"
    ENVIRONMENT    = "production"
  }
}

# Curriculum Service
module "curriculum_service" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "curriculum-service"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/curriculum-service:latest"
  service_account_email = module.sa_curriculum_service.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 10
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    FIRESTORE_PROJECT_ID            = "octo-education-ddc76"
    CLOUD_STORAGE_BUCKET            = "octo-education-ddc76-curriculum-materials"
    PUBSUB_PROJECT_ID               = "octo-education-ddc76"
    PUBSUB_TOPIC_CURRICULUM_UPDATED = "curriculum.objective.updated"
    CIE_API_URL                     = module.cie_api_service.url
    CIE_API_ENABLED                 = "true"
    PUBSUB_ENABLED                  = "true"
    AUTH_ENABLED                    = "true"
    ENVIRONMENT                     = "production"
  }
}
