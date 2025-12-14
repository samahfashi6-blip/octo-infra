# Curriculum Ingestion - GitHub Actions Setup Guide

**Date:** December 14, 2025  
**Service:** Curriculum Ingestion (Cloud Function)  
**Project:** octo-education-ddc76

---

## 🎯 What You Need

To enable secure, keyless authentication from GitHub Actions to GCP using **Workload Identity Federation**.

---

## 📋 Setup Instructions

### Step 1: Update Terraform Configuration

In [infra/env/main/main.tf](../../infra/env/main/main.tf), update the GitHub repository name:

```terraform
# Line ~615
module "github_wif_curriculum_ingestion" {
  source = "../../modules/github_workload_identity"

  project_id          = local.project_id
  service_account_id  = module.sa_curriculum_ingestion.id
  github_repository   = "YOUR_ORG/YOUR_REPO"  # ⚠️ UPDATE THIS
}
```

Replace `"YOUR_ORG/YOUR_REPO"` with your actual repository (e.g., `"samahfashi6-blip/curriculum-ingestion"`).

### Step 2: Apply Terraform

```bash
cd /Users/amjed/octo-infra/infra/env/main

# Initialize if needed
terraform init

# Apply the changes
terraform apply
```

### Step 3: Get the GitHub Secrets Values

After applying, get the values for your GitHub secrets:

```bash
# Get Workload Identity Provider
terraform output -raw curriculum_ingestion_workload_identity_provider

# Get Service Account Email
terraform output -raw curriculum_ingestion_github_service_account
```

### Step 4: Add GitHub Secrets

Go to your GitHub repository settings and add these two secrets:

| Secret Name                      | Description                | Example Value                                                                               |
| -------------------------------- | -------------------------- | ------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider | `projects/123456789/locations/global/workloadIdentityPools/github-actions/providers/github` |
| `GCP_SERVICE_ACCOUNT`            | Service Account Email      | `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`                      |

**To add secrets:**

1. Go to: `https://github.com/YOUR_ORG/YOUR_REPO/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add each secret with the name and value from above

### Step 5: Update Your GitHub Actions Workflow

Add this authentication step to your `.github/workflows/*.yml` file:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write # Required for Workload Identity

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      # Now you can use gcloud commands
      - name: Deploy Cloud Function
        run: |
          gcloud functions deploy curriculum-ingestion \
            --region=us-central1 \
            --runtime=go121 \
            --entry-point=ProcessPDFUpload \
            # ... other flags
```

---

## 🔧 Service Account Permissions

Your service account already has these roles:

- ✅ `roles/datastore.user` - Firestore access
- ✅ `roles/storage.objectAdmin` - Cloud Storage access
- ✅ `roles/documentai.apiUser` - Document AI access
- ✅ `roles/logging.logWriter` - Logging
- ✅ `roles/run.invoker` - Call Cloud Run services
- ✅ `roles/cloudfunctions.developer` - Deploy Cloud Functions
- ✅ `roles/iam.serviceAccountUser` - Act as service account
- ✅ `roles/artifactregistry.reader` - Read container images

---

## 🧪 Testing

After setting up, test the workflow:

```bash
# Trigger workflow manually
gh workflow run your-workflow.yml

# Or push to trigger
git push origin main
```

Check the GitHub Actions logs to verify authentication is working.

---

## 🆘 Troubleshooting

### Error: "Failed to generate Google Cloud access token"

**Solution:** Check that:

1. The GitHub repository name in Terraform matches exactly
2. Both secrets are added correctly in GitHub
3. The workflow has `id-token: write` permission

### Error: "Permission denied"

**Solution:** Verify service account has required roles:

```bash
gcloud projects get-iam-policy octo-education-ddc76 \
  --flatten="bindings[].members" \
  --filter="bindings.members:sa-curriculum-ingestion@*" \
  --format="table(bindings.role)"
```

---

## 📞 Questions?

Contact the infrastructure team or check:

- [Workload Identity Federation Docs](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions Auth](https://github.com/google-github-actions/auth)

---

## 🔐 Security Notes

- ✅ No service account keys needed
- ✅ Automatic credential rotation
- ✅ Scoped to specific GitHub repository
- ✅ Only works from GitHub Actions (not from local dev)

For local development, you can still use `gcloud auth application-default login` or create a temporary service account key if needed.
