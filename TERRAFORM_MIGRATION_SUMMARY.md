# Curriculum Service - Terraform Migration Summary

**Migration Date:** December 11, 2025  
**From:** octo-education-96e36 (manual deployment)  
**To:** octo-education-ddc76 (Terraform-managed)

## Overview

This document summarizes all changes made to migrate the Curriculum Service from the old GCP project to the new Terraform-managed infrastructure.

---

## ✅ Changes Summary

### 1. Project ID Updates

**Old Project:** `octo-education-96e36`  
**New Project:** `octo-education-ddc76`

**Files Updated:**

- `.env.example` - Updated default project ID
- `internal/config/config.go` - No hardcoded project IDs (uses env vars)
- `cloudbuild.yaml` - Updated Artifact Registry path
- `scripts/deploy.sh` - Updated to use new project ID
- `deployments/configmap.yaml` - Updated ConfigMap with new project ID
- `cmd/check-firestore/main.go` - Updated fallback project ID
- `cmd/list-curricula/main.go` - Updated default project ID
- `cmd/check-moroccan/main.go` - Updated default project ID
- `cmd/publish-events/main.go` - Updated help text with new project ID
- `check_jobs.py` - Updated Python script project ID
- `functions/pdf-extractor/.env.example` - Updated project ID

### 2. Docker Registry Migration (gcr.io → Artifact Registry)

**Old Registry:** `gcr.io/octo-education-96e36/*`  
**New Registry:** `us-central1-docker.pkg.dev/octo-education-ddc76/services/*`

**Files Updated:**

- `cloudbuild.yaml` - Updated all image references to Artifact Registry
- `scripts/deploy.sh` - Updated to push to Artifact Registry
- `deployments/deployment.yaml` - Updated Kubernetes image reference
- `functions/pdf-extractor/cloudbuild.yaml` - Updated PDF extractor service

**Image Paths:**

- Main service: `us-central1-docker.pkg.dev/octo-education-ddc76/services/curriculum-service:latest`
- PDF extractor: `us-central1-docker.pkg.dev/octo-education-ddc76/services/pdf-extraction-service:latest`

### 3. Credential File Removal

**Removed References to:**

- `GOOGLE_APPLICATION_CREDENTIALS`
- `service-account-key.json`
- JSON key file authentication

**New Authentication Pattern:**

- **Local Development:** `gcloud auth application-default login`
- **Cloud Run:** Terraform-managed service account (automatic)

**Files Updated:**

- `.env.example` - Removed credential path, added authentication note
- `check_jobs.py` - Removed credential file reference
- `functions/pdf-extractor/.env.example` - Removed credential path
- `deployments/configmap.yaml` - Removed service account secret reference
- `deployments/deployment.yaml` - Removed volume mount for service account key

**Files to Clean Up Later (documentation only):**

- `functions/pdf-extractor/cmd/test-local/README.md`
- `functions/pdf-extractor/QUICK_START_LOCAL_TESTING.md`
- `functions/pdf-extractor/scripts/process-local-pdfs.sh`
- `functions/pdf-extractor/setup-simple.sh`
- `functions/pdf-extractor/test-local.sh`
- `functions/pdf-extractor/MANUAL_GCP_SETUP.md`

### 4. Service Account Migration

**Old Service Account (REMOVED):** `curriculum-service@octo-education-96e36.iam.gserviceaccount.com`  
**New Service Account:** Managed by Terraform as `sa-curriculum-service@octo-education-ddc76.iam.gserviceaccount.com`

**Files Cleaned:**

- `cloudbuild.yaml` - Removed \_SERVICE_ACCOUNT substitution variable
- `functions/pdf-extractor/internal/cie/client.go` - Removed hardcoded service account constant
- All hardcoded service account references removed

**Note:** Terraform will assign the appropriate service account to Cloud Run instances.

### 5. Hardcoded URL Removal

**Changed:** Hardcoded Cloud Run URLs → Environment Variables

**New Environment Variable:**

- `CIE_API_URL` - CIE API base URL (replaces all hardcoded URLs)

**Files Updated:**

- `.env.example` - Added `CIE_API_URL` variable
- `internal/config/config.go` - Changed `CIEAPIBaseURL` to `CIEAPIURL`, removed default hardcoded URL
- `cmd/server/main.go` - Updated to use `cfg.CIEAPIURL`
- `cmd/resend-to-cie/main.go` - Changed to use `os.Getenv("CIE_API_URL")`
- `functions/pdf-extractor/.env.example` - Added `CIE_API_URL` variable
- `functions/pdf-extractor/internal/cie/client.go` - Removed hardcoded URL constants

**Old Hardcoded URLs Removed:**

- `https://curriculum-intelligence-engine-api-d7v6h2n4rq-uc.a.run.app`
- `https://curriculum-intelligence-engine-api-595130763475.us-central1.run.app`

### 6. Deployment Script Updates

**Philosophy Change:** CI/CD builds and pushes images ONLY. Terraform handles deployment.

#### `cloudbuild.yaml`

**Removed:**

- Step 4: Deploy to Cloud Run (entire gcloud run deploy step)
- All environment variable configurations
- Service account references
- Substitution variables (\_REGION, \_MEMORY, \_CPU, etc.)

**Kept:**

- Step 1: Build Docker image
- Step 2: Push tagged image
- Step 3: Push latest tag

**Added Comment:**

```yaml
# Deployment is handled by Terraform. CI/CD only builds and pushes images.
```

#### `scripts/deploy.sh`

**Removed:**

- `enable_apis()` function
- `get_region()` function
- `get_service_url()` function
- `test_deployment()` function
- `deploy_service()` function (replaced with `build_and_push()`)
- All Cloud Run deployment logic

**New Behavior:**

- Only builds Docker images
- Only pushes to Artifact Registry
- Prompts user to deploy via Terraform

**Added Notes:**

- Script now ends with: "Deploy via Terraform: terraform apply"
- "Terraform will handle Cloud Run deployment"

### 7. Environment Configuration Updates

#### `.env.example`

**Added:**

```bash
FIRESTORE_PROJECT_ID=octo-education-ddc76
CLOUD_STORAGE_BUCKET=octo-education-ddc76-curriculum-materials
PUBSUB_PROJECT_ID=octo-education-ddc76
CIE_API_URL=https://cie-api.example.com
CIE_API_ENABLED=true
```

**Removed:**

```bash
# GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/service-account-key.json
```

**Added Note:**

```bash
# Authentication: Local development uses 'gcloud auth application-default login'
# Cloud Run uses Terraform-managed service account (no credential files needed)
```

#### `internal/config/config.go`

**Changed:**

- `CIEAPIBaseURL` → `CIEAPIURL`
- `CIE_API_BASE_URL` → `CIE_API_URL`
- Removed hardcoded default URL for CIE API

### 8. Kubernetes Deployment Updates

#### `deployments/deployment.yaml`

**Changed:**

- Image: `gcr.io/YOUR_PROJECT_ID/curriculum-service:latest` → `us-central1-docker.pkg.dev/octo-education-ddc76/services/curriculum-service:latest`
- Removed `volumeMounts` for service account
- Removed `volumes` for service account secret

**Note:** Kubernetes deployments should use Workload Identity instead of credential files.

#### `deployments/configmap.yaml`

**Changed:**

- `firestore_project_id: "your-gcp-project-id"` → `"octo-education-ddc76"`
- `storage_bucket: "your-storage-bucket"` → `"octo-education-ddc76-curriculum-materials"`
- Removed `curriculum-service-account` Secret definition

### 9. PDF Extractor Service Updates

#### `functions/pdf-extractor/cloudbuild.yaml`

**Changed:**

- All `gcr.io/$PROJECT_ID/pdf-extraction-service` → `us-central1-docker.pkg.dev/octo-education-ddc76/services/pdf-extraction-service`
- Removed entire "Deploy to Cloud Run" step
- Removed service account references

#### `functions/pdf-extractor/internal/cie/client.go`

**Removed:**

```go
const (
    CIEBaseURL          = "https://..."
    ServiceAccountEmail = "curriculum-service@octo-education-96e36.iam.gserviceaccount.com"
)
```

**Changed:**

```go
func NewClient(baseURL string) *Client {
    // Now accepts baseURL as parameter
}
```

---

## 🔒 Security Improvements

1. **No More Credential Files:** All authentication uses Application Default Credentials (ADC)
2. **Service Account Isolation:** Each service gets its own Terraform-managed service account
3. **No Hardcoded Secrets:** All sensitive data via environment variables or Secret Manager
4. **Principle of Least Privilege:** Terraform assigns minimal required permissions

---

## 📋 Validation Checklist

### ✅ Code Changes

- [x] No `octo-education-96e36` references in code
- [x] No `gcr.io` references in CI/CD configs
- [x] No `GOOGLE_APPLICATION_CREDENTIALS` in code
- [x] No `service-account-key.json` references
- [x] No hardcoded service account emails
- [x] No hardcoded Cloud Run URLs
- [x] All internal service URLs use environment variables

### ✅ Configuration Files

- [x] `.env.example` updated with new project ID
- [x] `.env.example` has `CIE_API_URL` variable
- [x] `config.go` uses `CIE_API_URL` instead of hardcoded URL
- [x] `cloudbuild.yaml` uses Artifact Registry
- [x] `deployments/*.yaml` use new project ID

### ✅ Deployment Scripts

- [x] `cloudbuild.yaml` removed `gcloud run deploy` step
- [x] `scripts/deploy.sh` only builds and pushes images
- [x] No `gcloud run deploy` commands in scripts
- [x] Scripts reference Terraform for deployment

### ✅ Documentation (remaining in repository)

- [ ] README.md mentions Terraform deployment (if exists)
- [x] This migration summary document created
- [ ] Update AI_MENTOR_INTEGRATION_GUIDE.md URLs (optional - legacy doc)
- [ ] Update CLOUD_RUN_DEPLOYMENT_GUIDE.md (optional - legacy doc)
- [ ] Update PUBSUB_MIGRATION_SUMMARY.md (optional - legacy doc)

### ✅ Infrastructure

- [ ] Terraform creates Artifact Registry repository `services`
- [ ] Terraform creates service account `sa-curriculum-service@octo-education-ddc76.iam.gserviceaccount.com`
- [ ] Terraform grants necessary IAM roles to service account
- [ ] Terraform deploys Cloud Run service with correct image
- [ ] Cloud Run environment variables set by Terraform (including `CIE_API_URL`)

---

## 🚀 Deployment Process (Post-Migration)

### 1. Local Development Setup

**⚠️ CRITICAL: Authenticate to the CORRECT Google account and project!**

```bash
# Run the automated setup script (RECOMMENDED)
./scripts/setup-local-dev.sh

# This script will:
# - Verify your authenticated Google account
# - Check/set the correct project (octo-education-ddc76)
# - Configure application default credentials
# - Create .env file with correct settings
# - Verify access to required services
```

**Manual Setup (if needed):**

```bash
# 1. Login to Google Cloud (use the correct account!)
gcloud auth login

# 2. VERIFY your account
gcloud auth list

# 3. Set the CORRECT project
gcloud config set project octo-education-ddc76

# 4. VERIFY the project (IMPORTANT!)
gcloud config get-value project
# Must show: octo-education-ddc76

# 5. Set application default credentials
gcloud auth application-default login

# 6. Copy and configure environment variables
cp .env.example .env
# Edit .env and set:
#   - FIRESTORE_PROJECT_ID=octo-education-ddc76
#   - PUBSUB_PROJECT_ID=octo-education-ddc76
#   - CLOUD_STORAGE_BUCKET=octo-education-ddc76-curriculum-materials
#   - CIE_API_URL=<actual-cie-service-url>

# 7. Run locally
go run cmd/server/main.go
```

**⚠️ COMMON MISTAKES TO AVOID:**

- ❌ DO NOT authenticate to the old project (octo-education-96e36)
- ✅ Always verify: `gcloud config get-value project` before running
- ✅ If you see "octo-education-96e36", switch immediately!
- ✅ Make sure you're logged in with the correct Google account

### 2. Build and Push Images

```bash
# Option A: Use deploy script
./scripts/deploy.sh

# Option B: Use Cloud Build (recommended)
gcloud builds submit --config=cloudbuild.yaml
```

### 3. Deploy via Terraform

```bash
# Navigate to Terraform directory (assumed to be managed separately)
cd terraform/

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

### 4. Verify Deployment

```bash
# Get Cloud Run service URL (managed by Terraform)
gcloud run services describe curriculum-service \
  --region=us-central1 \
  --format="value(status.url)"

# Test health endpoint
curl https://<service-url>/health

# Check logs
gcloud run services logs read curriculum-service --region=us-central1
```

---

## 🔧 Required Terraform Configuration

The Terraform configuration must include:

### Service Account

```hcl
resource "google_service_account" "curriculum_service" {
  account_id   = "sa-curriculum-service"
  display_name = "Curriculum Service Account"
}

# Grant necessary roles
resource "google_project_iam_member" "curriculum_firestore" {
  project = "octo-education-ddc76"
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.curriculum_service.email}"
}

resource "google_project_iam_member" "curriculum_storage" {
  project = "octo-education-ddc76"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.curriculum_service.email}"
}

resource "google_project_iam_member" "curriculum_pubsub" {
  project = "octo-education-ddc76"
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.curriculum_service.email}"
}
```

### Artifact Registry

```hcl
resource "google_artifact_registry_repository" "services" {
  location      = "us-central1"
  repository_id = "services"
  format        = "DOCKER"
}
```

### Cloud Run Service

```hcl
resource "google_cloud_run_service" "curriculum_service" {
  name     = "curriculum-service"
  location = "us-central1"

  template {
    spec {
      service_account_name = google_service_account.curriculum_service.email

      containers {
        image = "us-central1-docker.pkg.dev/octo-education-ddc76/services/curriculum-service:latest"

        env {
          name  = "FIRESTORE_PROJECT_ID"
          value = "octo-education-ddc76"
        }

        env {
          name  = "CLOUD_STORAGE_BUCKET"
          value = "octo-education-ddc76-curriculum-materials"
        }

        env {
          name  = "CIE_API_URL"
          value = "https://<cie-service-url>"  # Set to actual CIE service URL
        }

        env {
          name  = "CIE_API_ENABLED"
          value = "true"
        }

        env {
          name  = "PUBSUB_PROJECT_ID"
          value = "octo-education-ddc76"
        }

        # Additional env vars...
      }
    }
  }
}
```

---

## 📝 Files Modified

### Core Configuration (7 files)

1. `.env.example`
2. `internal/config/config.go`
3. `cloudbuild.yaml`
4. `scripts/deploy.sh`
5. `cmd/server/main.go`
6. `deployments/deployment.yaml`
7. `deployments/configmap.yaml`

### Command-Line Tools (5 files)

8. `cmd/check-firestore/main.go`
9. `cmd/list-curricula/main.go`
10. `cmd/check-moroccan/main.go`
11. `cmd/publish-events/main.go`
12. `cmd/resend-to-cie/main.go`

### PDF Extractor Service (3 files)

13. `functions/pdf-extractor/cloudbuild.yaml`
14. `functions/pdf-extractor/.env.example`
15. `functions/pdf-extractor/internal/cie/client.go`

### Python Scripts (1 file)

16. `check_jobs.py`

**Total: 16 files modified**

---

## ⚠️ Breaking Changes

1. **`CIE_API_URL` Required:** The CIE API URL must now be set via environment variable. No default is provided.
2. **No Service Account Keys:** Local development must use `gcloud auth application-default login`
3. **Deployment Process Changed:** CI/CD no longer deploys to Cloud Run. Use Terraform.
4. **Service Account Email Changed:** Old shared account removed. Terraform manages new account.

---

## 🧹 Post-Migration Cleanup

### Files to Delete (after verification)

- `service-account-key.json` - **DELETE IMMEDIATELY** (contains credentials)

### Optional Cleanup (documentation files - review before deleting)

- `AI_MENTOR_INTEGRATION_GUIDE.md` - Contains old URLs (may still be useful as reference)
- `CLOUD_RUN_DEPLOYMENT_GUIDE.md` - Obsolete (replaced by Terraform)
- `PUBSUB_MIGRATION_SUMMARY.md` - Historical reference (can archive)
- `functions/pdf-extractor/MANUAL_GCP_SETUP.md` - Contains old setup instructions
- `functions/pdf-extractor/QUICK_START_LOCAL_TESTING.md` - Contains credential file references
- Various setup scripts in `functions/pdf-extractor/` that reference credential files

---

## 🎯 Success Criteria

- [ ] All code references new project `octo-education-ddc76`
- [ ] All images pushed to Artifact Registry
- [ ] No credential files in use
- [ ] Service deployed via Terraform
- [ ] Health endpoint returns 200 OK
- [ ] CIE API integration working with environment variable
- [ ] Pub/Sub events publishing correctly
- [ ] Logs visible in Cloud Console
- [ ] No hardcoded service accounts or URLs in code

---

## 📞 Support

For issues related to:

- **Infrastructure:** Check Terraform configuration and apply
- **Image builds:** Check Cloud Build logs in GCP Console
- **Authentication:** Verify service account permissions in IAM
- **CIE Integration:** Verify `CIE_API_URL` is set correctly

---

**Migration Completed:** December 11, 2025  
**Next Step:** Deploy infrastructure with Terraform

---

## 🚀 Phase 2: Pub/Sub to API Migration (December 16, 2025)

**Goal:** Replace Google Cloud Pub/Sub with direct HTTP API calls to the CIE service.

### 1. Infrastructure Changes (Terraform Impact)

**Resources to Remove:**
- **Pub/Sub Topics:** `curriculum-updates` (and any other topics previously used by this service)
- **Pub/Sub Subscriptions:** `curriculum-service-sub` (and any other subscriptions)
- **IAM Roles:** The service account `sa-curriculum-service@octo-education-ddc76.iam.gserviceaccount.com` NO LONGER needs:
    - `roles/pubsub.publisher`
    - `roles/pubsub.subscriber`

### 2. Configuration Updates

**New Environment Variables:**
- `CIE_API_URL`: (Required) Base URL for the CIE service.

**Removed Environment Variables:**
- `PUBSUB_PROJECT_ID`
- `PUBSUB_TOPIC_ID`
- `PUBSUB_SUBSCRIPTION_ID`

### 3. Codebase Changes

- **Package Removed:** `pkg/pubsub` (completely deleted)
- **New Package:** `pkg/cie` (handles HTTP communication)
- **Service Logic:** `internal/services` now calls `cie.Client` instead of publishing messages.
- **CLI Tools:** All CLI tools (`cmd/*`) have been updated to remove Pub/Sub dependencies.

### 4. Deployment Updates

- **Kubernetes Manifests:** `deployments/deployment.yaml` updated to remove Pub/Sub env vars and add `CIE_API_URL`.

**Migration Status:** ✅ Complete (Code refactored, built, and tested)
