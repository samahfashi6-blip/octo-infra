# Terraform Changes Summary - API Migration

**Date:** December 16, 2025  
**Status:** ✅ Ready to Apply  
**Validation:** PASSED

---

## 📋 Changes Overview

Terraform will make the following changes:

### ✅ Resources to ADD (1)

1. **IAM Binding** - Allow curriculum-ingestion to invoke CIE API
   - Resource: `google_cloud_run_v2_service_iam_member.ingestion_invoke_cie_api`
   - Role: `roles/run.invoker`
   - Service: `curriculum-intelligence-engine-api`
   - Member: `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`

### 🔄 Resources to CHANGE (2)

1. **Cloud Function** - `curriculum-ingestion`

   - **ADD:** `CIE_API_URL` = CIE API service URL
   - **ADD:** `FIRESTORE_PROJECT_ID`, `GCP_PROJECT_ID`, `PROCESSING_RESULTS_BUCKET`
   - **REMOVE:** `PUBSUB_TOPIC_ID`
   - **UPDATE:** `CURRICULUM_API_URL` (URL changed to new region)
   - **UPDATE:** `DOCUMENT_AI_PROCESSOR_ID` (full path format)
   - **UPDATE:** Memory 2Gi → 512Mi (corrected)
   - **UPDATE:** Retry policy enabled

2. **Curriculum Service** - Environment variables already configured correctly

### 🗑️ Resources to DESTROY (5)

1. **Pub/Sub Topic** - `curriculum-objectives-created`
2. **Pub/Sub Subscription** - `cie-objectives-subscription`
3. **IAM Binding** - Topic publisher role for curriculum-ingestion
4. **IAM Binding** - Subscription subscriber role for cie-worker
5. **Cloud Run Service** - `curriculum-intelligence-engine-worker` (deprecated)

### 📤 Outputs to REMOVE (1)

- `cie_worker_service_url` (worker service deprecated)

---

## 🎯 What This Accomplishes

### For Curriculum Ingestion Service:

- ✅ Can now call CIE API directly via HTTP
- ✅ No longer publishes to Pub/Sub
- ✅ Gets immediate feedback on processing success/failure
- ✅ Simpler error handling

### For CIE Service:

- ✅ API endpoint receives objectives directly
- ✅ Worker service no longer needed (scales to zero waste)
- ✅ Simpler authentication (Cloud Run service-to-service)

### Infrastructure Benefits:

- ✅ Removes Pub/Sub complexity (no topics, subscriptions, IAM)
- ✅ Cost savings: ~$12/month (worker always-on eliminated)
- ✅ Easier to debug and monitor
- ✅ Standard REST patterns

---

## 📝 Terraform Plan Output

```
Plan: 1 to add, 2 to change, 5 to destroy.

Changes to Outputs:
  - cie_worker_service_url = "..." -> null
```

---

## 🚀 How to Apply

### Option 1: Apply All Changes at Once (Recommended)

```bash
cd /Users/amjed/octo-infra/infra/env/main

# Review the plan one more time
terraform plan

# Apply all changes
terraform apply

# Confirm with 'yes' when prompted
```

### Option 2: Apply Changes Incrementally (Conservative)

```bash
cd /Users/amjed/octo-infra/infra/env/main

# Step 1: Add IAM binding for ingestion → CIE API
terraform apply -target=google_cloud_run_v2_service_iam_member.ingestion_invoke_cie_api

# Step 2: Update curriculum ingestion function (adds CIE_API_URL, removes PUBSUB_TOPIC_ID)
terraform apply -target=module.curriculum_ingestion_function

# Step 3: Test the new flow (upload a PDF, verify it works)
# ... wait for confirmation from curriculum ingestion team ...

# Step 4: Clean up Pub/Sub resources (after verifying API works)
terraform destroy -target=google_pubsub_subscription_iam_member.cie_worker_subscriber
terraform destroy -target=module.cie_objectives_subscription
terraform destroy -target=google_pubsub_topic_iam_member.curriculum_ingestion_publisher
terraform destroy -target=module.curriculum_objectives_topic

# Step 5: Remove worker service (after verifying Pub/Sub cleanup)
terraform destroy -target=module.cie_worker_service

# Step 6: Apply remaining changes
terraform apply
```

---

## ✅ Pre-Apply Checklist

- [x] Terraform validation passed
- [x] Curriculum ingestion team has deployed their code changes
- [x] CIE API endpoint `/api/v1/objectives/process` is ready
- [ ] Backup current Terraform state
- [ ] Review plan output one final time
- [ ] Notify teams of deployment window

---

## 🧪 Post-Apply Testing

### Test 1: Upload PDF and Verify Flow

```bash
# Upload a test PDF
gsutil cp test.pdf gs://octo-education-ddc76-curriculum-pdfs/

# Check ingestion function logs
gcloud functions logs read curriculum-ingestion \
  --region=us-central1 \
  --limit=50 \
  --project=octo-education-ddc76

# Should see: "Successfully sent X objectives to CIE API"

# Check CIE API logs
gcloud run services logs read curriculum-intelligence-engine-api \
  --region=us-central1 \
  --limit=50 \
  --project=octo-education-ddc76

# Should see: POST /api/v1/objectives/process 200 OK

# Verify objectives in Firestore
# (Check via Firebase console or API)
```

### Test 2: Verify Pub/Sub Cleanup

```bash
# Should return empty or error (resources deleted)
gcloud pubsub topics describe curriculum-objectives-created \
  --project=octo-education-ddc76

gcloud pubsub subscriptions describe cie-objectives-subscription \
  --project=octo-education-ddc76

# Worker service should be gone
gcloud run services describe curriculum-intelligence-engine-worker \
  --region=us-central1 \
  --project=octo-education-ddc76
```

### Test 3: Verify IAM Permissions

```bash
# Check ingestion can invoke CIE API
gcloud run services get-iam-policy curriculum-intelligence-engine-api \
  --region=us-central1 \
  --project=octo-education-ddc76 \
  --flatten="bindings[].members" \
  --filter="bindings.members:sa-curriculum-ingestion"

# Should show roles/run.invoker binding
```

---

## 🔄 Rollback Plan

If issues arise after applying:

### Immediate Rollback (Restore Pub/Sub)

```bash
cd /Users/amjed/octo-infra/infra/env/main

# Revert the Terraform changes
git revert HEAD

# Re-apply to restore Pub/Sub infrastructure
terraform apply

# Revert curriculum-ingestion code deployment
# (Coordinate with curriculum ingestion team)
```

### Partial Rollback (Keep Both Active)

If you want to keep both systems running:

1. Don't destroy Pub/Sub resources yet
2. Update ingestion code to publish to BOTH Pub/Sub AND call API
3. Monitor both paths
4. Remove Pub/Sub after 1 week of stable API operation

---

## 📊 Expected Behavior After Migration

### Before (Pub/Sub):

```
PDF Upload → Ingestion Function → Pub/Sub Topic → Subscription → Worker → Firestore
```

### After (API):

```
PDF Upload → Ingestion Function → CIE API → Firestore
```

### Logs You Should See:

**Ingestion Function:**

```
Processing PDF: test.pdf
Extracted 5 objectives
Calling CIE API: https://curriculum-intelligence-engine-api-.../api/v1/objectives/process
✅ Successfully sent 5 objectives to CIE API
Response: 200 OK
```

**CIE API:**

```
POST /api/v1/objectives/process
Authenticated as: sa-curriculum-ingestion@...
Processing 5 objectives for document: abc-123
Saved objectives to Firestore
Response: 200 OK
```

---

## 🎉 Success Criteria

Migration is successful when:

- ✅ PDF uploads trigger ingestion function
- ✅ Ingestion function calls CIE API successfully (200 OK)
- ✅ Objectives appear in Firestore
- ✅ No errors in any service logs
- ✅ Pub/Sub resources are deleted
- ✅ Worker service is deleted
- ✅ End-to-end processing time < 60 seconds
- ✅ Cost shows reduction in Cloud billing

---

## 📞 Support

**Infrastructure Team:** Ready to apply changes  
**Curriculum Ingestion Team:** Code deployed and ready  
**CIE Team:** API endpoint ready

**Next Steps:**

1. Get final approval from tech lead
2. Schedule deployment window (suggest: today, low-traffic period)
3. Apply Terraform changes
4. Test end-to-end flow
5. Monitor for 24 hours
6. Mark migration complete ✅

---

## 🚨 Important Notes

1. **Backup Terraform State:** Before applying, ensure state is backed up
2. **Coordinate with Teams:** All teams should be aware of deployment timing
3. **Monitor Closely:** Watch logs for first 1-2 hours after deployment
4. **Keep Rollback Ready:** Have git revert command ready just in case

---

**Ready to Apply:** Yes ✅  
**Estimated Duration:** 5-10 minutes  
**Risk Level:** Low (rollback available)  
**Impact:** High (simplifies architecture significantly)
