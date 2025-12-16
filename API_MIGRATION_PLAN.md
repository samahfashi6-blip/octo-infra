# Pub/Sub to API Migration Plan

**Date:** December 16, 2025  
**Architecture:** Cloud Solution Architect  
**Status:** APPROVED FOR IMPLEMENTATION

---

## 🎯 Executive Summary

**Objective:** Migrate from Pub/Sub event-driven architecture to direct API-based communication between Curriculum Ingestion, Curriculum Service, and CIE Service.

**Rationale:**

- Pub/Sub adds unnecessary complexity for synchronous request-response workflows
- Multiple IAM and authentication issues causing operational delays
- API-based architecture is simpler, more maintainable, and appropriate for our use case
- Cost remains negligible (~$1-2/month difference)

**Timeline:** 1-2 days for full migration

---

## 📐 Current Architecture (Pub/Sub - TO BE DEPRECATED)

```
[Cloud Function: curriculum-ingestion]
    ↓ (Publishes message)
[Pub/Sub Topic: curriculum-objectives-created]
    ↓ (Delivers to subscription)
[Pub/Sub Subscription: cie-objectives-subscription]
    ↓ (Worker pulls messages)
[Cloud Run: curriculum-intelligence-engine-worker]
    ↓ (Processes and stores)
[Firestore]
```

**Problems:**

- ❌ Complex IAM (project, topic, subscription levels)
- ❌ Authentication issues with metadata server
- ❌ Worker service must stay running (min_instances=1)
- ❌ Difficult to debug message flow
- ❌ Hardcoded subscription names causing conflicts

---

## 🏗️ Target Architecture (API-Based)

```
[Cloud Function: curriculum-ingestion]
    ↓ HTTP POST with service account auth
[Cloud Run: curriculum-intelligence-engine-api]
    ↓ Processes objectives
[Firestore]
    ↑
[Cloud Run: curriculum-service] ← HTTP API calls
```

**Benefits:**

- ✅ Simple service-to-service authentication
- ✅ Direct error feedback
- ✅ Easy to debug and monitor
- ✅ Standard REST patterns
- ✅ Reduced operational complexity

---

## 🔄 Migration Steps by Service

### Phase 1: CIE Service (Add API Endpoint)

**Service:** `curriculum-intelligence-engine-api`

#### Step 1.1: Add API Endpoint

**New Endpoint:**

```
POST /api/v1/objectives/process
Content-Type: application/json
Authorization: Bearer <service-account-token>

Body:
{
  "documentId": "uuid",
  "objectives": [
    {
      "id": "uuid",
      "learningObjective": "string",
      "subjectArea": "string",
      "gradeLevel": "string",
      "bloomLevel": "string"
    }
  ],
  "metadata": {
    "sourceFile": "filename.pdf",
    "processedAt": "2025-12-16T00:00:00Z"
  }
}

Response (200 OK):
{
  "success": true,
  "processed": 5,
  "documentId": "uuid",
  "message": "Objectives processed successfully"
}

Response (400/500 Error):
{
  "success": false,
  "error": "error message",
  "documentId": "uuid"
}
```

#### Step 1.2: Implement Handler

**File:** `internal/handlers/objectives_handler.go` (create new)

```go
package handlers

import (
    "encoding/json"
    "net/http"
    "github.com/your-org/cie/internal/services"
)

type ProcessObjectivesRequest struct {
    DocumentID string                 `json:"documentId"`
    Objectives []ObjectiveData        `json:"objectives"`
    Metadata   map[string]interface{} `json:"metadata"`
}

type ObjectiveData struct {
    ID               string `json:"id"`
    LearningObjective string `json:"learningObjective"`
    SubjectArea      string `json:"subjectArea"`
    GradeLevel       string `json:"gradeLevel"`
    BloomLevel       string `json:"bloomLevel"`
}

func (h *Handler) ProcessObjectives(w http.ResponseWriter, r *http.Request) {
    var req ProcessObjectivesRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }

    // Process objectives using existing service logic
    err := h.objectiveService.ProcessObjectives(r.Context(), req.DocumentID, req.Objectives)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(map[string]interface{}{
        "success":    true,
        "processed":  len(req.Objectives),
        "documentId": req.DocumentID,
    })
}
```

#### Step 1.3: Register Route

**File:** `cmd/api/main.go`

```go
// Add to your router setup
router.HandleFunc("/api/v1/objectives/process", handler.ProcessObjectives).Methods("POST")
```

#### Step 1.4: Deploy CIE API

```bash
# From CIE repository
git add .
git commit -m "feat: add REST API endpoint for objectives processing"
git push origin main

# GitHub Actions will automatically deploy
```

#### Step 1.5: Update Terraform - Add IAM for Ingestion Function

**File:** `infra/env/main/main.tf`

Add this after the `module "cie_api_service"` block (around line 270):

```terraform
# Allow curriculum-ingestion function to invoke CIE API
resource "google_cloud_run_v2_service_iam_member" "ingestion_invoke_cie_api" {
  project  = local.project_id
  location = local.region
  name     = module.cie_api_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${module.sa_curriculum_ingestion.email}"
}
```

---

### Phase 2: Curriculum Ingestion Service (Update to Call API)

**Service:** `curriculum-ingestion` Cloud Function

#### Step 2.1: Update Code to Call CIE API

**File:** `internal/curriculum/processor.go` (or equivalent)

**Remove Pub/Sub Publishing Code:**

```go
// DELETE THIS:
err := publishToPubSub(ctx, objectives)
```

**Add API Calling Code:**

```go
import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "google.golang.org/api/idtoken"
)

// Add this function:
func callCIEAPI(ctx context.Context, documentID string, objectives []Objective) error {
    cieAPIURL := os.Getenv("CIE_API_URL")
    if cieAPIURL == "" {
        return fmt.Errorf("CIE_API_URL not set")
    }

    endpoint := fmt.Sprintf("%s/api/v1/objectives/process", cieAPIURL)

    // Create authenticated HTTP client
    client, err := idtoken.NewClient(ctx, cieAPIURL)
    if err != nil {
        return fmt.Errorf("failed to create authenticated client: %w", err)
    }

    payload := map[string]interface{}{
        "documentId": documentID,
        "objectives": objectives,
        "metadata": map[string]interface{}{
            "processedAt": time.Now().Format(time.RFC3339),
        },
    }

    body, err := json.Marshal(payload)
    if err != nil {
        return fmt.Errorf("failed to marshal payload: %w", err)
    }

    resp, err := client.Post(endpoint, "application/json", bytes.NewBuffer(body))
    if err != nil {
        return fmt.Errorf("failed to call CIE API: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("CIE API returned status %d", resp.StatusCode)
    }

    log.Printf("✅ Successfully sent %d objectives to CIE API", len(objectives))
    return nil
}
```

**Update Main Processing Function:**

```go
func ProcessPDFUpload(ctx context.Context, e GCSEvent) error {
    // ... existing PDF processing code ...

    // Extract objectives
    objectives := extractObjectives(extractedText)

    // OLD: Publish to Pub/Sub
    // err = publishToPubSub(ctx, objectives)

    // NEW: Call CIE API directly
    err = callCIEAPI(ctx, documentID, objectives)
    if err != nil {
        return fmt.Errorf("failed to process objectives via CIE API: %w", err)
    }

    return nil
}
```

#### Step 2.2: Update Terraform - Add CIE_API_URL Environment Variable

**File:** `infra/env/main/main.tf`

Update the `curriculum_ingestion_function` module (around line 630):

```terraform
module "curriculum_ingestion_function" {
  source     = "../../modules/cloud_function"
  project_id = local.project_id
  region     = local.region

  name        = "curriculum-ingestion"
  runtime     = "go125"
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
    PROJECT_ID                   = "octo-education-ddc76"
    GCP_PROJECT_ID               = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID         = "octo-education-ddc76"
    CURRICULUM_API_URL           = module.curriculum_service.url
    CIE_API_URL                  = module.cie_api_service.url  # ADD THIS LINE
    DOCUMENT_AI_PROCESSOR_ID     = var.document_ai_processor_id
    DOCUMENT_AI_LOCATION         = "us"
    PROCESSING_RESULTS_BUCKET    = module.curriculum_processing_results_bucket.name
    # REMOVE: PUBSUB_TOPIC_ID    = module.curriculum_objectives_topic.id
    GEMINI_MODEL_ID              = "gemini-2.5-pro"
    GEMINI_LOCATION              = "us-central1"
  }
}
```

#### Step 2.3: Deploy Ingestion Function

```bash
# From curriculum-ingestion repository
git add .
git commit -m "feat: migrate from Pub/Sub to direct CIE API calls"
git push origin main

# GitHub Actions will build and deploy via Cloud Build
```

---

### Phase 3: Curriculum Service (Update API Integration)

**Service:** `curriculum-service`

#### Step 3.1: Update Code (If Curriculum Service Uses Pub/Sub)

**Current State Check:**
The Terraform shows `PUBSUB_ENABLED=true` and `PUBSUB_TOPIC_CURRICULUM_UPDATED`.

**If curriculum-service publishes to Pub/Sub:**

1. Replace Pub/Sub publishing with direct API calls to CIE API (similar to ingestion service)
2. Use the `CIE_API_URL` environment variable (already configured)

**File:** Update wherever Pub/Sub publishing happens

```go
// OLD:
err := publishToPubSub(ctx, "curriculum.objective.updated", data)

// NEW:
err := callCIEAPI(ctx, data)
```

#### Step 3.2: Update Terraform - Disable Pub/Sub

**File:** `infra/env/main/main.tf`

Update `curriculum_service` module (around line 485):

```terraform
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
    # REMOVE: PUBSUB_PROJECT_ID      = "octo-education-ddc76"
    # REMOVE: PUBSUB_TOPIC_CURRICULUM_UPDATED = "curriculum.objective.updated"
    CIE_API_URL                     = module.cie_api_service.url
    CIE_API_ENABLED                 = "true"
    PUBSUB_ENABLED                  = "false"  # CHANGE FROM true TO false
    AUTH_ENABLED                    = "true"
    ENVIRONMENT                     = "production"
  }
}
```

#### Step 3.3: Add IAM for Curriculum Service to Invoke CIE API

**File:** `infra/env/main/main.tf`

Add after the curriculum_service module:

```terraform
# Allow curriculum-service to invoke CIE API
resource "google_cloud_run_v2_service_iam_member" "curriculum_invoke_cie_api" {
  project  = local.project_id
  location = local.region
  name     = module.cie_api_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${module.sa_curriculum_service.email}"
}
```

---

### Phase 4: Deprecate CIE Worker Service

**Service:** `curriculum-intelligence-engine-worker`

#### Step 4.1: Update Terraform - Remove Worker Service

**File:** `infra/env/main/main.tf`

**Comment out or remove** the worker service (around line 275):

```terraform
# DEPRECATED: Worker service no longer needed with API-based architecture
# Pub/Sub polling is replaced by direct API calls
/*
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
  min_instances = 1
  max_instances = 5
  ingress       = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  env_vars = {
    GOOGLE_CLOUD_PROJECT   = "octo-education-ddc76"
    FIRESTORE_PROJECT_ID   = "octo-education-ddc76"
    REDIS_ENABLED          = "false"
    PUBSUB_SUBSCRIPTION_ID = module.cie_objectives_subscription.id
  }
}
*/
```

**Note:** Keep the service account `sa_cie_worker` in case it's needed for other purposes. We'll verify before removing.

---

### Phase 5: Remove Pub/Sub Infrastructure

**File:** `infra/env/main/main.tf`

#### Step 5.1: Comment Out Pub/Sub Resources

Replace the Pub/Sub section (around line 585):

```terraform
########################################
# 5. PUBSUB - DEPRECATED (Migrated to API-based architecture)
########################################

# DEPRECATED: Pub/Sub resources no longer needed
# Migration Date: December 16, 2025
# Migration Reason: API-based architecture is simpler and more appropriate
# for synchronous request-response workflows

/*
module "curriculum_objectives_topic" {
  source     = "../../modules/pubsub_topic"
  project_id = local.project_id
  name       = "curriculum-objectives-created"
  labels = {
    service     = "curriculum-ingestion"
    environment = "production"
  }
}

resource "google_pubsub_topic_iam_member" "curriculum_ingestion_publisher" {
  project = local.project_id
  topic   = module.curriculum_objectives_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${module.sa_curriculum_ingestion.email}"
}

module "cie_objectives_subscription" {
  source               = "../../modules/pubsub_subscription"
  project_id           = local.project_id
  name                 = "cie-objectives-subscription"
  topic                = module.curriculum_objectives_topic.name
  ack_deadline_seconds = 600
  min_retry_backoff    = "10s"
  max_retry_backoff    = "600s"
}

resource "google_pubsub_subscription_iam_member" "cie_worker_subscriber" {
  project      = local.project_id
  subscription = module.cie_objectives_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${module.sa_cie_worker.email}"
}
*/

# Note: To permanently delete Pub/Sub resources, run:
# terraform destroy -target=module.cie_objectives_subscription
# terraform destroy -target=module.curriculum_objectives_topic
# gcloud pubsub subscriptions delete cie-curriculum-updates (if exists)
```

---

## 📋 Implementation Checklist

### Phase 1: CIE API Service ✅

- [ ] Add POST `/api/v1/objectives/process` endpoint
- [ ] Implement handler with proper error handling
- [ ] Add authentication middleware
- [ ] Test endpoint locally
- [ ] Deploy to Cloud Run
- [ ] Add IAM binding in Terraform (`ingestion_invoke_cie_api`)
- [ ] Apply Terraform changes: `terraform apply -target=google_cloud_run_v2_service_iam_member.ingestion_invoke_cie_api`

### Phase 2: Curriculum Ingestion Function ✅

- [ ] Replace Pub/Sub code with API calling code
- [ ] Add `idtoken.NewClient` for authentication
- [ ] Update error handling
- [ ] Update Terraform to add `CIE_API_URL` env var
- [ ] Remove `PUBSUB_TOPIC_ID` from Terraform
- [ ] Deploy function via GitHub Actions
- [ ] Test with real PDF upload

### Phase 3: Curriculum Service ✅

- [ ] Review if Curriculum Service uses Pub/Sub
- [ ] If yes, replace with API calls
- [ ] Update Terraform: set `PUBSUB_ENABLED = "false"`
- [ ] Add IAM binding (`curriculum_invoke_cie_api`)
- [ ] Apply Terraform changes
- [ ] Deploy service via GitHub Actions

### Phase 4: Deprecate Worker ✅

- [ ] Comment out `cie_worker_service` module in Terraform
- [ ] Apply Terraform (worker will be deleted)
- [ ] Verify CIE API handles all processing
- [ ] Document worker deprecation

### Phase 5: Remove Pub/Sub ✅

- [ ] Comment out all Pub/Sub resources in Terraform
- [ ] Apply Terraform changes
- [ ] Manually delete `cie-curriculum-updates` subscription (if exists)
- [ ] Verify no services reference Pub/Sub
- [ ] Update documentation

---

## 🧪 Testing Plan

### Test 1: End-to-End Flow

1. Upload a test PDF to `octo-education-ddc76-curriculum-pdfs` bucket
2. Check Cloud Function logs for successful API call
3. Check CIE API logs for objective processing
4. Verify objectives stored in Firestore
5. Confirm no errors in any service

### Test 2: Error Handling

1. Upload malformed PDF
2. Verify graceful error handling
3. Check error logs are clear and actionable

### Test 3: Authentication

1. Verify service account authentication works
2. Test with revoked permissions (temporarily) to confirm auth is enforced
3. Restore permissions

### Test 4: Performance

1. Upload 5 PDFs simultaneously
2. Monitor processing times
3. Verify no timeouts or bottlenecks

---

## 🔧 Terraform Apply Commands

**Step-by-step application:**

```bash
cd /Users/amjed/octo-infra/infra/env/main

# Step 1: Add IAM for ingestion to invoke CIE API
terraform apply -target=google_cloud_run_v2_service_iam_member.ingestion_invoke_cie_api

# Step 2: Update ingestion function environment variables
terraform apply -target=module.curriculum_ingestion_function

# Step 3: Add IAM for curriculum service to invoke CIE API
terraform apply -target=google_cloud_run_v2_service_iam_member.curriculum_invoke_cie_api

# Step 4: Update curriculum service configuration
terraform apply -target=module.curriculum_service

# Step 5: Remove worker service (after confirming API works)
terraform destroy -target=module.cie_worker_service

# Step 6: Remove Pub/Sub resources (after confirming everything works)
terraform destroy -target=google_pubsub_subscription_iam_member.cie_worker_subscriber
terraform destroy -target=module.cie_objectives_subscription
terraform destroy -target=google_pubsub_topic_iam_member.curriculum_ingestion_publisher
terraform destroy -target=module.curriculum_objectives_topic

# Step 7: Delete manually created subscription (if exists)
gcloud pubsub subscriptions delete cie-curriculum-updates \
  --project=octo-education-ddc76

# Final: Apply all remaining changes
terraform apply
```

---

## 📊 Rollback Plan

If migration encounters issues:

### Immediate Rollback (Keep Both Working)

**Don't delete Pub/Sub immediately!** Keep it running alongside API for safety.

1. Keep Pub/Sub infrastructure active
2. Update code to call both API AND Pub/Sub
3. Monitor both paths
4. Once API proven stable for 1 week, remove Pub/Sub

### Code Rollback

```bash
# Revert ingestion function
cd curriculum-ingestion
git revert <commit-hash>
git push origin main

# Revert Terraform
cd infra/env/main
git revert <commit-hash>
terraform apply
```

---

## 💰 Cost Impact

**Before (Pub/Sub):**

- Pub/Sub messages: ~$0.80/month (estimated 10K messages)
- CIE Worker: Always running (min_instances=1) = ~$15/month
- **Total: ~$16/month**

**After (API):**

- Cloud Run invocations: ~$0.40/month (10K invocations)
- CIE API: Scales to zero when idle = ~$3/month average
- **Total: ~$3.50/month**

**Savings: ~$12.50/month + reduced engineering overhead**

---

## 📝 Documentation Updates Needed

After migration:

1. Update architecture diagrams
2. Update API documentation with new CIE endpoints
3. Update runbooks for troubleshooting
4. Archive Pub/Sub documentation
5. Update onboarding docs for new developers

---

## ✅ Success Criteria

Migration is successful when:

- ✅ PDFs uploaded to GCS trigger ingestion function
- ✅ Ingestion function successfully calls CIE API
- ✅ CIE API processes objectives and stores in Firestore
- ✅ No Pub/Sub resources in Terraform state
- ✅ No errors in any service logs
- ✅ End-to-end processing time < 60 seconds per PDF
- ✅ All services scale to zero when idle

---

## 🚨 Risk Mitigation

| Risk                            | Impact | Mitigation                                                             |
| ------------------------------- | ------ | ---------------------------------------------------------------------- |
| API authentication fails        | High   | Test auth before full migration, keep Pub/Sub active during transition |
| CIE API endpoint not ready      | High   | Complete Phase 1 and test thoroughly before Phase 2                    |
| Terraform apply breaks services | Medium | Use targeted applies, test in dev environment first                    |
| Lost messages during migration  | Low    | No messages in queue currently, migration during low-traffic period    |

---

## 📞 Support Contacts

**Infrastructure Team:** octo-infra@example.com  
**CIE Team:** cie-dev@example.com  
**Curriculum Ingestion Team:** curriculum-dev@example.com

---

## 🎯 Next Steps

1. **Today (Dec 16):**

   - Review migration plan with all teams
   - Get approval from tech lead
   - Schedule migration window

2. **Tomorrow (Dec 17):**

   - Implement Phase 1 (CIE API endpoint)
   - Deploy and test endpoint
   - Apply Terraform IAM changes

3. **Day 3 (Dec 18):**

   - Implement Phase 2 (Ingestion function)
   - Test end-to-end flow
   - Monitor for 24 hours

4. **Day 4 (Dec 19):**

   - Implement Phase 3 (Curriculum service)
   - Deprecate worker service
   - Remove Pub/Sub infrastructure

5. **Week 2:**
   - Monitor all services
   - Confirm cost savings
   - Update documentation
   - Mark migration complete

---

**Document Version:** 1.0  
**Last Updated:** December 16, 2025  
**Approved By:** Cloud Solution Architect
