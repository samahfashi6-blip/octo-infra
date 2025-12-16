# 📧 Action Required: Redeploy Curriculum Ingestion Function

**To:** Curriculum Ingestion Team
**From:** Infrastructure Team
**Subject:** 🚀 API Migration Ready - Please Redeploy

---

## Status: Infrastructure Ready ✅

The infrastructure changes for the API migration are complete.

- **IAM:** Your service account `sa-curriculum-ingestion` now has permission to invoke the CIE API.
- **Config:** The `CIE_API_URL` environment variable has been set.
- **Cleanup:** Pub/Sub topics and subscriptions have been removed.

## ⚠️ Action Required: Redeploy

Please redeploy your Cloud Function to ensure it picks up the latest configuration and code changes.

### Deployment Command

```bash
gcloud functions deploy curriculum-ingestion \
  --region=us-central1 \
  --gen2 \
  --source=. \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=octo-education-ddc76-curriculum-pdfs"
```

### Verification Steps

1. Upload a test PDF to `gs://octo-education-ddc76-curriculum-pdfs/`
2. Check logs to confirm successful API call:
   ```bash
   gcloud functions logs read curriculum-ingestion --region=us-central1 --limit=20
   ```
3. Look for "Successfully called CIE API" (or similar success message from your code).

---

**Infrastructure Team**
