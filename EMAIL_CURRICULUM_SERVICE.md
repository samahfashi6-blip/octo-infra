# 📧 Action Required: Redeploy Curriculum Service

**To:** Curriculum Service Team
**From:** Infrastructure Team
**Subject:** 🚀 API Migration Ready - Force Image Update Required

---

## Status: Infrastructure Ready ✅

The infrastructure changes for Phase 2 (API Migration) are complete.
- **IAM:** Your service account `sa-curriculum-service` has permission to invoke the CIE API.
- **Config:** `PUBSUB_ENABLED` is set to `false`. `CIE_API_URL` is configured.
- **Cleanup:** `roles/pubsub.publisher` has been removed.

## ⚠️ Action Required: Force Update

Your latest code (Phase 2) is in Artifact Registry, but Cloud Run is likely still running the cached Phase 1 image. You must force an update to pull the new code.

### Deployment Command
```bash
# Force Cloud Run to pull the latest image from Artifact Registry
gcloud run services update curriculum-service --region=us-central1
```

### Verification Steps
1. Check logs to confirm startup with `PUBSUB_ENABLED=false`:
   ```bash
   gcloud run services logs read curriculum-service --region=us-central1 --limit=20
   ```
2. Verify API calls to CIE are working (instead of Pub/Sub publishing).

---
**Infrastructure Team**
