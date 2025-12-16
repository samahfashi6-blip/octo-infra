# 📧 To: Curriculum Service Team

**Subject:** 🚀 Infrastructure Updated - ACTION REQUIRED: Force Redeploy for Phase 2

**Date:** December 16, 2025

---

## Status: INFRASTRUCTURE UPDATED

We have applied all requested Terraform changes for the Phase 2 (No Pub/Sub) migration.

### ✅ What We've Done:
1. **IAM:** Added `roles/run.invoker` for your service to call CIE API.
2. **IAM:** Removed `roles/pubsub.publisher` (no longer needed).
3. **Config:** Set `PUBSUB_ENABLED=false` and verified `CIE_API_URL`.
4. **Cleanup:** Removed old Pub/Sub resources.

### 🚨 CRITICAL ACTION REQUIRED: Force Image Update

Although your new code (Phase 2) is in Artifact Registry, **Cloud Run is likely still running the old cached image**.

You must force Cloud Run to pull the latest image:

**Option 1: Command Line (Fastest)**
```bash
gcloud run services update curriculum-service --region=us-central1
```

**Option 2: Trigger CI/CD**
- Re-run your deployment pipeline in GitHub Actions.

### 🔍 Why is this necessary?
Cloud Run caches the `:latest` tag. Without a force update or new revision, it won't know that the image content in the registry has changed to the new Phase 2 code.

### 🧪 Verification
Check your logs to ensure `PUBSUB_ENABLED` is false and API calls are working:
```bash
gcloud run services logs read curriculum-service --region=us-central1 --limit=20
```

---
**Infrastructure Team**
