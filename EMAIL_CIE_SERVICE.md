# 📧 Action Required: Redeploy CIE Service

**To:** CIE Development Team
**From:** Infrastructure Team
**Subject:** 🚀 API Migration Ready - Service Update

---

## Status: Infrastructure Ready ✅

The infrastructure is fully configured for the synchronous API architecture.
- **IAM:** Ingestion and Curriculum services are authorized to call your API.
- **Cleanup:** The worker service and Pub/Sub subscriptions have been decommissioned.

## ⚠️ Action Required: Ensure Latest Code

Please ensure the running CIE API service is using the latest image that handles the synchronous processing logic.

### Deployment Command
```bash
# Force Cloud Run to pull the latest image from Artifact Registry
gcloud run services update curriculum-intelligence-engine-api --region=us-central1
```

### Verification Steps
1. Monitor logs for incoming requests from Ingestion and Curriculum services:
   ```bash
   gcloud run services logs read curriculum-intelligence-engine-api --region=us-central1 --limit=50
   ```
2. Verify `POST /api/v1/objectives/process` requests are being handled successfully (200 OK).

---
**Infrastructure Team**
