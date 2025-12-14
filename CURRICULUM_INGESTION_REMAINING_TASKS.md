# Curriculum Ingestion - Remaining Tasks

## ✅ Completed

- Infrastructure deployed via Terraform
- Service account created with all permissions
- Storage buckets created
- APIs enabled
- GitHub Actions workflow file created locally

## 📋 Your Next Actions

### 1. Create Document AI Processor (15 minutes)

**Go to:** https://console.cloud.google.com/ai/document-ai/processors?project=octo-education-ddc76

**Steps:**

1. Click "Create Processor"
2. Select "Document OCR" processor
3. Choose region: `us` (or `us-central1`)
4. Give it a name: "Curriculum PDF OCR"
5. Click "Create"
6. **Copy the Processor ID** (format: `projects/PROJECT_NUMBER/locations/LOCATION/processors/PROCESSOR_ID`)

**Update Terraform:**

```bash
cd /Users/amjed/octo-infra/infra/env/main
```

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
document_ai_processor_id = "YOUR_ACTUAL_PROCESSOR_ID_HERE"
```

Run:

```bash
terraform apply
```

---

### 2. Set Up Workload Identity Federation (20 minutes)

**Create Workload Identity Pool:**

```bash
gcloud iam workload-identity-pools create "github-actions-pool" \
  --project="octo-education-ddc76" \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

**Create Workload Identity Provider:**

```bash
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="octo-education-ddc76" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

**Grant Service Account Impersonation:**

```bash
gcloud iam service-accounts add-iam-policy-binding \
  "sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com" \
  --project="octo-education-ddc76" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/samahfashi6-blip/curriculum_ingestion"
```

**Get Project Number:**

```bash
gcloud projects describe octo-education-ddc76 --format="value(projectNumber)"
```

**Note the Workload Identity Provider name:**

```
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

---

### 3. Add Workflow to Their Repository

**A. Add workflow file to their repo:**

Navigate to: `https://github.com/samahfashi6-blip/curriculum_ingestion`

Create file: `.github/workflows/deploy.yml`

Copy content from: `/Users/amjed/curriculum-ingestion-deploy.yml`

**B. Configure GitHub Secrets:**

Go to: `https://github.com/samahfashi6-blip/curriculum_ingestion/settings/secrets/actions`

Add these secrets:

1. **GCP_WORKLOAD_IDENTITY_PROVIDER:**

   ```
   projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
   ```

2. **GCP_SERVICE_ACCOUNT:**

   ```
   sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com
   ```

3. **DOCUMENT_AI_PROCESSOR_ID:**
   ```
   [The processor ID you created in step 1]
   ```

---

### 4. Grant GCP Project Access to Their Team

```bash
# Add their email as viewer
gcloud projects add-iam-policy-binding octo-education-ddc76 \
  --member="user:THEIR_EMAIL@example.com" \
  --role="roles/viewer"

gcloud projects add-iam-policy-binding octo-education-ddc76 \
  --member="user:THEIR_EMAIL@example.com" \
  --role="roles/logging.viewer"

gcloud projects add-iam-policy-binding octo-education-ddc76 \
  --member="user:THEIR_EMAIL@example.com" \
  --role="roles/monitoring.viewer"
```

---

### 5. Send Final "Ready to Deploy" Message

Once all above is complete, send them:

```
✅ Infrastructure deployed
✅ Document AI Processor created: [PROCESSOR_ID]
✅ GitHub Actions workflow configured
✅ All secrets added
✅ GCP project access granted

🚀 You're ready to deploy!

Push your code to the main branch and it will automatically deploy.
Monitor deployment at: https://github.com/samahfashi6-blip/curriculum_ingestion/actions

After deployment, test by uploading a PDF to:
gs://octo-education-ddc76-curriculum-pdfs/

View logs at:
https://console.cloud.google.com/functions/details/us-central1/curriculum-ingestion?project=octo-education-ddc76
```

---

## 📝 Summary

**Order of operations:**

1. Create Document AI processor (15 min)
2. Set up Workload Identity (20 min)
3. Add workflow to their repo (5 min)
4. Configure GitHub secrets (5 min)
5. Grant them GCP access (2 min)
6. Send "Ready to Deploy" notification
7. They push code → automatic deployment!

**Total time:** ~50 minutes of your work, then they can deploy immediately.
