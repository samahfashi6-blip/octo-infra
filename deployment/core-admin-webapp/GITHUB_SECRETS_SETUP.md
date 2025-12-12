# GitHub Actions Workload Identity Setup

This guide will help you set up Workload Identity Federation for secure GitHub Actions authentication to GCP.

## 🎯 What Are These Secrets?

The two secrets enable **keyless authentication** from GitHub Actions to GCP using Workload Identity Federation (more secure than service account keys).

---

## 📋 Quick Setup Guide

### Option 1: Manual Setup (No Workload Identity Pool Yet)

If your team hasn't set up Workload Identity Federation yet, you can use a **Service Account Key** temporarily:

#### Create Service Account Key

```bash
# Create a key for the service account
gcloud iam service-accounts keys create ~/sa-core-admin-webapp-key.json \
  --iam-account=sa-core-admin-webapp@octo-education-ddc76.iam.gserviceaccount.com \
  --project=octo-education-ddc76

# Display the key (copy the entire output)
cat ~/sa-core-admin-webapp-key.json
```

#### GitHub Secrets (Temporary Method)

Create only **ONE secret**:

| Secret Name  | Value                                     |
| ------------ | ----------------------------------------- |
| `GCP_SA_KEY` | The entire JSON content from the key file |

#### Update Workflow

In `.github/workflows/deploy-admin-webapp.yml`, replace the auth step:

```yaml
# OLD (Workload Identity - not set up yet)
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
    service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

# NEW (Service Account Key - temporary)
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}
```

---

### Option 2: Proper Setup with Workload Identity (Recommended)

This is the secure, recommended approach. Here's how to set it up:

#### Step 1: Create Terraform Configuration

Create `infra/modules/github_workload_identity/main.tf`:

```terraform
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions from specific repository to impersonate service account
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = var.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repository}"
}
```

Create `infra/modules/github_workload_identity/variables.tf`:

```terraform
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_id" {
  description = "Service account resource ID"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
}
```

Create `infra/modules/github_workload_identity/outputs.tf`:

```terraform
output "workload_identity_provider" {
  description = "The full workload identity provider resource name"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  description = "Service account email for GitHub Actions"
  value       = var.service_account_id
}
```

#### Step 2: Add to Main Terraform

In `infra/env/main/main.tf`, add:

```terraform
# GitHub Workload Identity for Core Admin Webapp
module "github_wif_core_admin_webapp" {
  source = "../../modules/github_workload_identity"

  project_id          = local.project_id
  service_account_id  = module.sa_core_admin_webapp.id
  github_repository   = "samahfashi6-blip/core_adminstration"
}
```

#### Step 3: Add Outputs

In `infra/env/main/outputs.tf`, add:

```terraform
output "core_admin_webapp_workload_identity_provider" {
  description = "Workload Identity Provider for Core Admin Web App GitHub Actions"
  value       = module.github_wif_core_admin_webapp.workload_identity_provider
  sensitive   = false
}
```

#### Step 4: Apply Terraform

```bash
cd infra/env/main
terraform init
terraform apply
```

#### Step 5: Get the Values

```bash
# Get Workload Identity Provider
terraform output -raw core_admin_webapp_workload_identity_provider

# Get Service Account Email
terraform output -raw core_admin_webapp_service_account_email
```

#### Step 6: Create GitHub Secrets

The output will give you values like:

**Secret #1: `GCP_WORKLOAD_IDENTITY_PROVIDER`**

```
projects/123456789/locations/global/workloadIdentityPools/github-actions/providers/github
```

**Secret #2: `GCP_SERVICE_ACCOUNT`**

```
sa-core-admin-webapp@octo-education-ddc76.iam.gserviceaccount.com
```

---

## 🔒 Security Comparison

| Method                  | Security  | Setup    | Rotation  | Recommended    |
| ----------------------- | --------- | -------- | --------- | -------------- |
| **Service Account Key** | ⚠️ Medium | Easy     | Manual    | Temporary only |
| **Workload Identity**   | ✅ High   | Moderate | Automatic | ✅ Yes         |

---

## 🚀 Quick Start (Choose One)

### For Testing Right Now (5 minutes)

Use **Option 1** with Service Account Key:

```bash
# 1. Create key
gcloud iam service-accounts keys create ~/sa-key.json \
  --iam-account=sa-core-admin-webapp@octo-education-ddc76.iam.gserviceaccount.com

# 2. Add secret GCP_SA_KEY with the JSON content
# 3. Update workflow to use credentials_json
```

### For Production (30 minutes)

Use **Option 2** with Workload Identity:

```bash
# 1. Copy Terraform modules from above
# 2. terraform init && terraform apply
# 3. Get outputs and add as GitHub secrets
# 4. Workflow already configured correctly
```

---

## 📝 How to Add GitHub Secrets

1. Go to your repository: `https://github.com/samahfashi6-blip/core_adminstration`
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value from above

---

## ✅ Verification

After adding secrets, test the workflow:

```bash
# Trigger workflow manually
gh workflow run deploy-admin-webapp.yml

# Or push to main
git push origin main
```

---

## 🆘 Troubleshooting

### Error: "Workload Identity Provider not found"

→ Use Option 1 (Service Account Key) temporarily

### Error: "Permission denied"

→ Check that service account has required roles:

```bash
gcloud projects get-iam-policy octo-education-ddc76 \
  --flatten="bindings[].members" \
  --filter="bindings.members:sa-core-admin-webapp@*"
```

### Need Help?

Contact your infrastructure team for Workload Identity setup, or use Service Account Key as a temporary solution.

---

## 📚 Additional Resources

- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions Authentication](https://github.com/google-github-actions/auth)
- [Service Account Keys Best Practices](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
