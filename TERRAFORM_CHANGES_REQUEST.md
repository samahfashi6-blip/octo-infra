# 🏗️ Terraform Infrastructure Updates Request

**Date:** December 16, 2025
**From:** CIE Development Team
**To:** Infrastructure / Terraform Team
**Subject:** CIE API Migration & Pub/Sub Deprecation

---

## 🚨 Executive Summary

The Curriculum Intelligence Engine (CIE) has successfully migrated from an asynchronous Pub/Sub architecture to a synchronous REST API architecture for objective processing. The code changes are complete.

**We now require immediate Terraform updates to align the infrastructure with the new application architecture.**

## 📋 Required Terraform Changes

Please apply the following changes to the `infra/env/main/main.tf` (or equivalent) configuration.

### 1. IAM Updates (Critical)

We need to allow the Ingestion Function and Curriculum Service to call the CIE API directly.

```hcl
# Allow curriculum-ingestion function to invoke CIE API
resource "google_cloud_run_v2_service_iam_member" "ingestion_invoke_cie_api" {
  project  = local.project_id
  location = local.region
  name     = module.cie_api_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${module.sa_curriculum_ingestion.email}"
}

# Allow curriculum-service to invoke CIE API
resource "google_cloud_run_v2_service_iam_member" "curriculum_invoke_cie_api" {
  project  = local.project_id
  location = local.region
  name     = module.cie_api_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${module.sa_curriculum_service.email}"
}
```

### 2. Service Configuration Updates

#### A. Curriculum Ingestion Function

Update the `curriculum_ingestion_function` module:

- **ADD** env var: `CIE_API_URL = module.cie_api_service.url`
- **REMOVE** env var: `PUBSUB_TOPIC_ID`

#### B. Curriculum Service

Update the `curriculum_service` module:

- **ADD** env var: `CIE_API_URL = module.cie_api_service.url`
- **UPDATE** env var: `PUBSUB_ENABLED = "false"` (was "true")

### 3. Resource Decommissioning (Deprecation)

The following resources are no longer used by the application code and should be removed to save costs:

#### A. CIE Worker Service

**Action:** Remove or comment out the `cie_worker_service` module.

- The worker code has been deprecated and disabled.
- All processing logic has been moved to the API service.

#### B. Pub/Sub Resources

**Action:** Remove the following Pub/Sub resources:

- Topic: `curriculum-objectives-created`
- Subscription: `cie-objectives-subscription`
- IAM bindings related to these topics/subscriptions

## 🔄 Verification Plan

After applying these Terraform changes, we will verify:

1.  **Ingestion:** Upload a PDF -> Ingestion Function -> CIE API (Success 200 OK)
2.  **Curriculum Service:** Update Objective -> Curriculum Service -> CIE API (Success 200 OK)
3.  **Cleanup:** Verify Worker service is deleted and Pub/Sub topics are gone.

---

**Reference:**

- [API Migration Plan](../docs/integrations/API_MIGRATION_PLAN.md)
- [Deployment Guide](../DEPLOYMENT_GUIDE.md)
