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
    "monitoring.googleapis.com",
    "cloudfunctions.googleapis.com",
    "documentai.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com"
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

# Core Admin Web App Service Account
module "sa_core_admin_webapp" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-core-admin-webapp"
  display_name = "Core Admin Web App Service Account"
  project_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.writer"  # For CI/CD Docker image push
  ]
}

# Curriculum Ingestion Service Account
module "sa_curriculum_ingestion" {
  source       = "../../modules/service_account"
  project_id   = local.project_id
  account_id   = "sa-curriculum-ingestion"
  display_name = "Curriculum Ingestion Service Account"
  project_roles = [
    "roles/datastore.user",
    "roles/storage.objectAdmin",
    "roles/documentai.apiUser",
    "roles/logging.logWriter",
    "roles/run.invoker",              # To call curriculum service
    "roles/cloudfunctions.developer", # To deploy Cloud Functions via GitHub Actions
    "roles/iam.serviceAccountUser",   # To act as service account during deployment
    "roles/artifactregistry.reader"   # To read container images during build
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

  secrets = {
    JWT_SECRET = {
      secret  = "jwt-secret"
      version = "latest"
    }
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

# Core Admin Web App (Angular Frontend)
module "core_admin_webapp" {
  source     = "../../modules/cloud_run_service"
  project_id = local.project_id
  region     = local.region

  name                  = "core-admin-webapp"
  image                 = "us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest"
  service_account_email = module.sa_core_admin_webapp.email

  cpu           = "1"
  memory        = "512Mi"
  concurrency   = 80
  min_instances = 0
  max_instances = 5
  ingress       = "INGRESS_TRAFFIC_ALL"

  env_vars = {
    # Backend API URLs
    API_CORE_ADMIN_URL    = module.core_admin_api.url
    API_AI_MENTOR_URL     = module.ai_mentor_service.url
    API_CURRICULUM_URL    = module.curriculum_service.url
    API_CIE_URL           = module.cie_api_service.url
    API_MATH_URL          = module.mathematic_service.url
    API_PHYSICS_URL       = module.physics_gateway.url
    API_CHEMISTRY_URL     = module.chemistry_gateway.url
    API_SQUAD_URL         = module.squad_service.url

    # Firebase configuration
    FIREBASE_PROJECT_ID = "octo-education-ddc76"
    
    # Application settings
    ENVIRONMENT   = "production"
    APP_VERSION   = "1.0.0"
    ENABLE_ANALYTICS = "true"
  }
}

########################################
# 5. STORAGE BUCKETS
########################################

# Curriculum PDF Upload Bucket
module "curriculum_pdf_uploads_bucket" {
  source       = "../../modules/bucket"
  project_id   = local.project_id
  name         = "octo-education-ddc76-curriculum-pdfs"
  location     = local.region
  versioning   = false
  delete_after_days = 0
}

# Curriculum Processing Results Bucket
module "curriculum_processing_results_bucket" {
  source       = "../../modules/bucket"
  project_id   = local.project_id
  name         = "octo-education-ddc76-curriculum-processing-results"
  location     = local.region
  versioning   = true
  delete_after_days = 0
}

# Source code bucket for Cloud Function
module "curriculum_function_source_bucket" {
  source       = "../../modules/bucket"
  project_id   = local.project_id
  name         = "octo-education-ddc76-curriculum-function-source"
  location     = local.region
  versioning   = true
  delete_after_days = 0
}

########################################
# 6. CLOUD FUNCTIONS
########################################

# Curriculum Ingestion Function
module "curriculum_ingestion_function" {
  source     = "../../modules/cloud_function"
  project_id = local.project_id
  region     = local.region

  name        = "curriculum-ingestion"
  runtime     = "go121"
  entry_point = "ProcessPDFUpload"

  source_bucket = module.curriculum_function_source_bucket.name
  source_object = "curriculum-ingestion-source.zip"

  service_account_email = module.sa_curriculum_ingestion.email

  memory          = "512Mi"
  timeout_seconds = 540
  max_instances   = 10
  min_instances   = 0

  trigger_config = {
    event_type   = "google.cloud.storage.object.v1.finalized"
    bucket       = module.curriculum_pdf_uploads_bucket.name
    retry_policy = "RETRY_POLICY_RETRY"
  }

  env_vars = {
    GCP_PROJECT_ID       = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID = "octo-education-ddc76"
    CURRICULUM_API_URL   = module.curriculum_service.url
    DOCUMENT_AI_PROCESSOR_ID = var.document_ai_processor_id
    PROCESSING_RESULTS_BUCKET = module.curriculum_processing_results_bucket.name
  }
}
