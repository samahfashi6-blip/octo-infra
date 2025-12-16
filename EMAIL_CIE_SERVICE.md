# 📧 To: CIE Service Team

**Subject:** ✅ Infrastructure Updates Complete - API Access Configured

**Date:** December 16, 2025

---

## Status: COMPLETED

We have finished configuring the IAM permissions required for the new API-based architecture.

### ✅ What We've Done:
1. **Incoming Access:** Granted `roles/run.invoker` to:
   - `curriculum-ingestion` (Cloud Function)
   - `curriculum-service` (Cloud Run)
2. **Cleanup:** Removed the deprecated Worker Service and Pub/Sub infrastructure.

### 🚀 Recommended Action: Redeploy

If you have pushed new code to Artifact Registry (e.g., removing Pub/Sub listeners or updating API logic), please force a redeployment to ensure the latest image is running.

**Command:**
```bash
gcloud run services update curriculum-intelligence-engine-api --region=us-central1
```

### 🔍 Monitoring
You should start seeing incoming HTTP requests from the Ingestion function and Curriculum Service on your API endpoints.

Monitor your logs here:
```bash
gcloud run services logs read curriculum-intelligence-engine-api --region=us-central1
```

---
**Infrastructure Team**
