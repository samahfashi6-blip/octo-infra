# 📧 CIE API Permission Issue After Redeployment

**To:** Infrastructure/Terraform Team  
**From:** Curriculum Ingestion Team  
**Subject:** 🚨 CIE API Returns 403 Forbidden - IAM Permission Issue  
**Date:** December 16, 2025

---

## Summary

We have successfully redeployed the `curriculum-ingestion` Cloud Function as requested in your migration notice. However, the function is encountering a **403 Forbidden** error when attempting to call the CIE API, indicating that the IAM permissions may not be correctly configured.

---

## ✅ Actions Completed

1. **Redeployed Cloud Function** with the following configuration:

   - Service Account: `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`
   - Environment Variable: `CIE_API_URL=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app`
   - Deployment Time: `2025-12-16T10:52:02Z`

2. **Verified Deployment:**

   ```bash
   ✅ Function found: curriculum-ingestion
   ✅ Service Account: sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com
   ✅ CIE_API_URL: https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
   ```

3. **Tested with Real PDF Upload**

---

## ❌ Issue Encountered

When the function attempts to call the CIE API, it receives a **403 Forbidden** response:

### Log Evidence

```
2025/12/16 10:53:04 [f14d8fee-aa48-4cc4-9a85-248f247a8205]
Warning: Failed to call CIE API: CIE API returned status 403

2025/12/16 10:45:27 [46553431-bfd1-4d68-b8e5-f8a0c27c4702]
Warning: Failed to call CIE API: CIE API returned status 403
```

### What This Indicates

A 403 Forbidden error typically means:

- The service account lacks the required IAM role (`roles/run.invoker`) on the CIE API
- The IAM binding was not correctly applied during the Terraform deployment
- The IAM policy changes have not propagated yet (though 2+ days have passed since your notification)

---

## 🔍 Verification Request

Could you please verify the following:

### 1. IAM Binding on CIE API

Please confirm that this binding exists:

```bash
gcloud run services get-iam-policy curriculum-intelligence-engine-api \
  --region=us-central1 \
  --format=json | jq '.bindings[] | select(.role=="roles/run.invoker")'
```

**Expected member:** `serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`

### 2. Service Account Used by Function

Please verify the function is using the correct service account:

```bash
gcloud functions describe curriculum-ingestion \
  --region=us-central1 \
  --format="value(serviceConfig.serviceAccountEmail)"
```

**Expected output:** `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`

### 3. CIE API Ingress Settings

Please confirm the CIE API allows invocations from internal service accounts:

```bash
gcloud run services describe curriculum-intelligence-engine-api \
  --region=us-central1 \
  --format="value(spec.template.metadata.annotations['run.googleapis.com/ingress'])"
```

---

## 🔧 Suggested Fix

If the IAM binding is missing, please apply:

```hcl
resource "google_cloud_run_service_iam_member" "curriculum_ingestion_cie_invoker" {
  service  = "curriculum-intelligence-engine-api"
  location = "us-central1"
  role     = "roles/run.invoker"
  member   = "serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com"
}
```

Or via gcloud:

```bash
gcloud run services add-iam-policy-binding curriculum-intelligence-engine-api \
  --region=us-central1 \
  --member="serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

---

## 📊 Additional Context

### Secondary Issue (Lower Priority)

The Curriculum Service is also returning errors (500/503), but this appears to be a separate service availability issue:

```
2025/12/16 10:53:04 Failed to send objective 1/3: API returned status 500
2025/12/16 10:53:05 Failed to send objective 2/3: API returned status 503
```

This may be a transient issue or the service might be cold-starting. We can address this separately once the CIE API permission issue is resolved.

---

## ⏱️ Impact

Currently, the pipeline is partially functional:

- ✅ PDF processing works
- ✅ Objective extraction works
- ✅ Firestore storage works
- ❌ **CIE API notification fails** (403 Forbidden)
- ❌ Curriculum Service integration fails (500/503 errors)

This means extracted curriculum objectives are stored in Firestore staging but are not being processed by the CIE service for embedding generation.

---

## 🙏 Next Steps

1. Please verify and fix the IAM binding for the CIE API
2. Confirm when the changes have been applied
3. We will re-test with a PDF upload and confirm successful integration

Thank you for your assistance!

---

**Curriculum Ingestion Team**

### Attachments

- Full deployment output: Available on request
- Complete logs: `gcloud functions logs read curriculum-ingestion --region=us-central1 --limit=50`
