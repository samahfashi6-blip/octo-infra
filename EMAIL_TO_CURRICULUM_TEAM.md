# Email to Curriculum Ingestion Team

**Subject:** Infrastructure Complete - Add These Files to Deploy 🚀

Hi Curriculum Ingestion Team,

Great news! All infrastructure is deployed and ready. Here's everything you need to set up automatic deployment.

## ⚠️ IMPORTANT: Code Update Required

During our testing, we found your code needs one additional dependency:

**Add to your `go.mod`:**

```go
require (
    github.com/GoogleCloudPlatform/functions-framework-go v1.8.0
    // ... your other dependencies
)
```

**Then run:**

```bash
go mod tidy
go mod vendor
```

This is required for Cloud Functions Gen 2. Please make this change before pushing your code.

---

## 📝 Step 1: Add GitHub Workflow File

Create this file in your repository: `.github/workflows/deploy.yml`

```yaml
name: Deploy Curriculum Ingestion Function

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  GCP_PROJECT_ID: octo-education-ddc76
  GCP_REGION: us-central1
  FUNCTION_NAME: curriculum-ingestion
  SOURCE_BUCKET: octo-education-ddc76-curriculum-function-source

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.21"

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Setup Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Build and package function
        run: |
          # Download dependencies
          go mod download
          go mod vendor

          # Create deployment package
          zip -r curriculum-ingestion-source.zip . -x ".git/*" ".github/*" "*.md"

      - name: Upload source to GCS
        run: |
          gsutil cp curriculum-ingestion-source.zip gs://${{ env.SOURCE_BUCKET }}/curriculum-ingestion-source.zip

      - name: Deploy Cloud Function
        run: |
          gcloud functions deploy ${{ env.FUNCTION_NAME }} \
            --gen2 \
            --region=${{ env.GCP_REGION }} \
            --runtime=go121 \
            --entry-point=ProcessPDFUpload \
            --source=gs://${{ env.SOURCE_BUCKET }}/curriculum-ingestion-source.zip \
            --service-account=sa-curriculum-ingestion@${{ env.GCP_PROJECT_ID }}.iam.gserviceaccount.com \
            --memory=512Mi \
            --timeout=540s \
            --max-instances=10 \
            --min-instances=0 \
            --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
            --trigger-event-filters="bucket=octo-education-ddc76-curriculum-pdfs" \
            --set-env-vars="GCP_PROJECT_ID=${{ env.GCP_PROJECT_ID }},FIRESTORE_PROJECT_ID=${{ env.GCP_PROJECT_ID }},CURRICULUM_API_URL=https://curriculum-service-3dh2p4j4qq-uc.a.run.app,DOCUMENT_AI_PROCESSOR_ID=${{ secrets.DOCUMENT_AI_PROCESSOR_ID }},PROCESSING_RESULTS_BUCKET=octo-education-ddc76-curriculum-processing-results"

      - name: Deployment complete
        run: |
          echo "✅ Cloud Function deployed successfully!"
          echo "Function name: ${{ env.FUNCTION_NAME }}"
          echo "Trigger bucket: octo-education-ddc76-curriculum-pdfs"
```

---

## 🔐 Step 2: Add GitHub Secrets

Go to: https://github.com/samahfashi6-blip/curriculum_ingestion/settings/secrets/actions

Click "New repository secret" and add these **3 secrets**:

### Secret 1: GCP_WORKLOAD_IDENTITY_PROVIDER

**Name:** `GCP_WORKLOAD_IDENTITY_PROVIDER`  
**Value:**

```
projects/79785327518/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

### Secret 2: GCP_SERVICE_ACCOUNT

**Name:** `GCP_SERVICE_ACCOUNT`  
**Value:**

```
sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com
```

### Secret 3: DOCUMENT_AI_PROCESSOR_ID

**Name:** `DOCUMENT_AI_PROCESSOR_ID`  
**Value:**

```
projects/79785327518/locations/us/processors/a81a921a9fa90f91
```

---

## 🚀 Step 3: Push Your Code

Once you've added the workflow file and secrets:

```bash
git add .github/workflows/deploy.yml
git commit -m "Add deployment workflow"
git push origin main
```

The workflow will automatically trigger and deploy your function!

---

## 📊 Monitor Deployment

- **GitHub Actions:** https://github.com/samahfashi6-blip/curriculum_ingestion/actions
- **Cloud Function Logs:** https://console.cloud.google.com/functions/details/us-central1/curriculum-ingestion?project=octo-education-ddc76

---

## ✅ Test Your Function

After deployment, test by uploading a PDF:

```bash
gsutil cp test.pdf gs://octo-education-ddc76-curriculum-pdfs/
```

The function will automatically trigger and process the PDF!

---

## 📦 What's Deployed

✅ Infrastructure ready  
✅ Document AI Processor: `a81a921a9fa90f91`  
✅ Curriculum Service: `https://curriculum-service-3dh2p4j4qq-uc.a.run.app`  
✅ Storage buckets created  
✅ Service account configured  
✅ All permissions granted

**You're ready to deploy!**

Any questions, let us know!

Best regards,  
**Terraform Team**
