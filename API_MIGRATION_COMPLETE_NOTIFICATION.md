# API Migration Complete - Ready for Testing

**Date:** December 16, 2024  
**From:** Infrastructure Team  
**To:** Curriculum Ingestion Team  
**Subject:** ✅ API Migration Complete - CIE_API_URL and Testing Instructions

---

## Migration Status: **COMPLETE** ✅

All infrastructure changes have been successfully applied and verified. The API-based architecture is now live and ready for your code deployment and testing.

---

## Critical Information for Your Deployment Scripts

### CIE API Service URL
```
CIE_API_URL=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
```

**Action Required:** Update your deployment scripts with this URL:

1. **In `deploy-function.sh`:**
```bash
--set-env-vars="CIE_API_URL=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app" \
```

2. **In `.github/workflows/deploy.yml`:**
```yaml
env:
  CIE_API_URL: "https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app"
```

3. **Remove all PUBSUB_TOPIC_ID references** from your deployment scripts.

---

## Infrastructure Changes Completed

### ✅ Resources Created
- **IAM Binding:** `sa-curriculum-ingestion` → `roles/run.invoker` on CIE API
  - Your service account can now invoke the CIE API service
- **Environment Variable:** `CIE_API_URL` added to curriculum-ingestion function

### ✅ Resources Removed
- **Pub/Sub Topic:** `curriculum-objectives-created` (deleted)
- **Pub/Sub Subscription:** `cie-objectives-subscription` (deleted)
- **Manual Subscription:** `cie-curriculum-updates` (deleted)
- **CIE Worker Service:** `curriculum-intelligence-engine-worker` (deleted)
- **Environment Variable:** `PUBSUB_TOPIC_ID` removed from function

### ✅ Verification Completed
```bash
# Function environment variables confirmed:
✓ CIE_API_URL present
✓ PUBSUB_TOPIC_ID removed

# IAM permissions verified:
✓ sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com
  has roles/run.invoker on CIE API

# Pub/Sub cleanup confirmed:
✓ All migration-related topics deleted
✓ All migration-related subscriptions deleted
```

---

## Next Steps for Your Team

### 1. Update Your Code (Immediate)
Follow the code changes outlined in [API_MIGRATION_PLAN.md](./API_MIGRATION_PLAN.md), Phase 2:

**In `pkg/objectives/processor.go`:**
```go
// Remove Pub/Sub client initialization
// Add:
cieAPIURL := os.Getenv("CIE_API_URL")
if cieAPIURL == "" {
    log.Fatal("CIE_API_URL environment variable not set")
}

// In processObjectives():
ctx, cancel := context.WithTimeout(ctx, 60*time.Second)
defer cancel()

// Create ID token client for service-to-service auth
client, err := idtoken.NewClient(ctx, cieAPIURL)
if err != nil {
    return fmt.Errorf("failed to create idtoken client: %w", err)
}

// Make POST request
payload := map[string]interface{}{
    "curriculum_id": curriculumID,
    "objectives": objectives,
    "metadata": metadata,
}
body, _ := json.Marshal(payload)

resp, err := client.Post(
    cieAPIURL+"/api/v1/objectives/process",
    "application/json",
    bytes.NewReader(body),
)
if err != nil {
    return fmt.Errorf("failed to call CIE API: %w", err)
}
defer resp.Body.Close()

if resp.StatusCode != http.StatusOK {
    return fmt.Errorf("CIE API returned status %d", resp.StatusCode)
}
```

### 2. Deploy Your Changes
```bash
# Run your existing deployment process
./deploy-function.sh
# or
git push origin main  # if using GitHub Actions
```

### 3. Test End-to-End Flow

**Upload a test PDF:**
```bash
gsutil cp test-curriculum.pdf gs://octo-education-ddc76-curriculum-pdfs/
```

**Monitor logs in real-time:**
```bash
# Curriculum ingestion function logs
gcloud functions logs read curriculum-ingestion \
  --region=us-central1 \
  --gen2 \
  --limit=50

# CIE API logs
gcloud run services logs read curriculum-intelligence-engine-api \
  --region=us-central1 \
  --limit=50
```

**Verify success:**
1. ✓ Ingestion function logs show: "Successfully called CIE API" or status 200
2. ✓ CIE API logs show: `POST /api/v1/objectives/process`
3. ✓ Firestore collection `curriculums/{id}/objectives` has new documents
4. ✓ Processing completes in <60 seconds

### 4. Troubleshooting Guide

**If you see "403 Forbidden":**
- Verify service account attached to function: `sa-curriculum-ingestion`
- Check IAM binding exists (we've already verified this)

**If you see "timeout":**
- CIE API has 60s timeout configured
- Check CIE API logs for processing issues

**If objectives don't appear in Firestore:**
- Check CIE API logs for Firestore write errors
- Verify Gemini API is responding (check for API quota issues)

---

## Cost Savings

- **CIE Worker Service:** ~$10/month saved (always-running service eliminated)
- **Pub/Sub Subscription:** ~$2/month saved (no subscription costs)
- **Total:** ~$12/month savings

---

## Rollback Plan (If Needed)

If you encounter critical issues during testing:

1. **Notify infrastructure team immediately**
2. **We can restore Pub/Sub infrastructure:**
   ```bash
   cd infra/env/main
   # Uncomment Pub/Sub resources in main.tf
   terraform apply
   ```
3. **You revert your code changes**
4. **We'll investigate and re-plan the migration**

---

## Support

Infrastructure team is monitoring logs and available for immediate support during your testing phase.

**Contact:** Reply to this email or ping on Slack

---

## Verification Checklist

Before you start testing, confirm:
- [ ] You have the CIE_API_URL value: `https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app`
- [ ] Your deployment scripts are updated with CIE_API_URL
- [ ] Your code changes are ready to deploy
- [ ] You have test PDFs prepared
- [ ] You know how to check function and API logs

Once you've completed testing, please reply with:
- ✓ Deployment successful
- ✓ Test PDFs processed successfully
- ✓ Objectives visible in Firestore
- ✓ No errors in logs

---

**Infrastructure Team**  
December 16, 2024
