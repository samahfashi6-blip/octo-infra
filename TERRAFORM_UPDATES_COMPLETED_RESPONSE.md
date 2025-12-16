# ✅ Terraform Updates Completed - CIE API Migration

**Date:** December 16, 2025  
**From:** Infrastructure Team  
**To:** CIE Development Team  
**Subject:** RE: Terraform Infrastructure Updates Request - COMPLETED

---

## Status: All Requested Changes Applied ✅

All Terraform changes from your infrastructure update request have been successfully applied to production.

---

## 1. IAM Updates ✅

### Curriculum Ingestion Function → CIE API

```hcl
resource "google_cloud_run_v2_service_iam_member" "ingestion_invoke_cie_api" {
  project  = "octo-education-ddc76"
  location = "us-central1"
  name     = "curriculum-intelligence-engine-api"
  role     = "roles/run.invoker"
  member   = "serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com"
}
```

**Status:** Applied in previous commit ✓

### Curriculum Service → CIE API

```hcl
resource "google_cloud_run_v2_service_iam_member" "curriculum_invoke_cie_api" {
  project  = "octo-education-ddc76"
  location = "us-central1"
  name     = "curriculum-intelligence-engine-api"
  role     = "roles/run.invoker"
  member   = "serviceAccount:sa-curriculum-service@octo-education-ddc76.iam.gserviceaccount.com"
}
```

**Status:** Applied in commit `4c796c2` ✓

---

## 2. Service Configuration Updates ✅

### A. Curriculum Ingestion Function

**Updated environment variables:**

- ✅ **ADDED:** `CIE_API_URL = "https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app"`
- ✅ **REMOVED:** `PUBSUB_TOPIC_ID`

**Verification:**

```bash
$ gcloud functions describe curriculum-ingestion --region=us-central1 --gen2 \
  --format="value(serviceConfig.environmentVariables)" | grep CIE_API_URL
CIE_API_URL=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
```

### B. Curriculum Service

**Updated environment variables:**

- ✅ **UPDATED:** `PUBSUB_ENABLED = "false"` (was `"true"`)
- ✅ **CONFIRMED:** `CIE_API_URL = "https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app"` (already present)

**Verification:**

```bash
$ gcloud run services describe curriculum-service --region=us-central1 \
  --format="yaml(spec.template.spec.containers[0].env)" | grep -A 1 "PUBSUB_ENABLED"
- name: PUBSUB_ENABLED
  value: 'false'
```

---

## 3. Resource Decommissioning ✅

### A. CIE Worker Service

**Status:** Commented out and documented in Terraform code ✓

- Service has been deleted from GCP
- Terraform code remains commented for reference
- Saves ~$10/month

### B. Pub/Sub Resources

**Deleted resources:**

- ✅ Topic: `curriculum-objectives-created`
- ✅ Subscription: `cie-objectives-subscription`
- ✅ Manual subscription: `cie-curriculum-updates`
- ✅ All associated IAM bindings

**Verification:**

```bash
$ gcloud pubsub topics describe curriculum-objectives-created
ERROR: NOT_FOUND: Resource not found
```

**Cost savings:** ~$2/month

---

## Production Verification Summary

### IAM Permissions Verified

```bash
$ gcloud run services get-iam-policy curriculum-intelligence-engine-api \
  --region=us-central1 --format=json | jq '.bindings[] | select(.role == "roles/run.invoker")'
```

**Result:**

- ✅ `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`
- ✅ `sa-curriculum-service@octo-education-ddc76.iam.gserviceaccount.com`

### Environment Variables Verified

- ✅ Curriculum Ingestion Function has `CIE_API_URL`, no `PUBSUB_TOPIC_ID`
- ✅ Curriculum Service has `CIE_API_URL`, `PUBSUB_ENABLED="false"`

### Resource Cleanup Verified

- ✅ No curriculum-related Pub/Sub topics found
- ✅ No curriculum-related Pub/Sub subscriptions found (except Eventarc-managed for GCS trigger)
- ✅ CIE worker service deleted

---

## Git Commits

All changes have been committed to version control:

1. **Initial API Migration** (commit `cca7d3a`)

   - Deprecated Pub/Sub infrastructure
   - Added IAM binding for curriculum-ingestion
   - Updated curriculum-ingestion function environment variables

2. **Curriculum Service Updates** (commit `4c796c2`)
   - Added IAM binding for curriculum-service
   - Set `PUBSUB_ENABLED=false` in curriculum-service

---

## Infrastructure is Ready ✅

Your infrastructure is now fully configured for the API-based architecture:

### For Curriculum Ingestion Function:

- ✓ Has `CIE_API_URL` environment variable
- ✓ Has `roles/run.invoker` permission on CIE API
- ✓ Can make authenticated calls to CIE API

### For Curriculum Service:

- ✓ Has `CIE_API_URL` environment variable
- ✓ Has `roles/run.invoker` permission on CIE API
- ✓ Pub/Sub disabled (`PUBSUB_ENABLED=false`)
- ✓ Can make authenticated calls to CIE API

---

## Next Steps

### 1. Your Team (CIE + Curriculum Services)

Both services are now ready to use the API-based architecture:

**Curriculum Ingestion Function:**

- Code is ready (already deployed with API integration)
- Infrastructure is configured
- Ready for production use

**Curriculum Service:**

- Update your code to respect `PUBSUB_ENABLED=false`
- Use `CIE_API_URL` for API calls instead of Pub/Sub
- Deploy updated code

### 2. End-to-End Testing

We recommend testing both flows:

**Flow 1: PDF Upload → Ingestion Function → CIE API**

```bash
gsutil cp test-curriculum.pdf gs://octo-education-ddc76-curriculum-pdfs/
```

**Flow 2: Curriculum Service → CIE API**

```bash
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://curriculum-service-3dh2p4j4qq-uc.a.run.app/api/v1/objectives
```

### 3. Monitoring

Monitor logs for both services:

```bash
# Ingestion function logs
gcloud functions logs read curriculum-ingestion --region=us-central1 --gen2

# Curriculum service logs
gcloud run services logs read curriculum-service --region=us-central1

# CIE API logs
gcloud run services logs read curriculum-intelligence-engine-api --region=us-central1
```

---

## Cost Savings

- **CIE Worker Service:** ~$10/month (eliminated)
- **Pub/Sub:** ~$2/month (eliminated)
- **Total:** ~$12/month savings

---

## Support

Infrastructure team is available for any questions or support during your code deployment and testing.

**Contact:** Reply to this thread or ping on Slack

---

**Infrastructure Team**  
December 16, 2025
