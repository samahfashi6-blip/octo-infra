# Core Admin Web App - Quick Reference

## 🚀 Quick Deploy Commands

### Deploy Infrastructure (First Time)

```bash
cd /Users/amjed/octo-infra/infra/env/main
terraform init
terraform plan
terraform apply
```

### Build & Deploy Manually

```bash
# From core_adminstration repository
docker build -t us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest \
  -f deployment/Dockerfile .

docker push us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest

gcloud run deploy core-admin-webapp \
  --image=us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated
```

## 📋 Checklist for Team

- [x] Terraform infrastructure created (service account + Cloud Run config)
- [ ] Deployment files copied to `core_adminstration` repository
- [ ] EnvironmentService created in Angular app
- [ ] Services updated to use EnvironmentService
- [ ] env.js script added to index.html
- [ ] GitHub secrets configured (Workload Identity)
- [ ] First deployment successful
- [ ] Custom domain configured (optional)

## 📂 Files to Copy to `core_adminstration` Repository

```
core_adminstration/
├── deployment/
│   ├── Dockerfile                    # ✅ Created
│   ├── nginx.conf                    # ✅ Created
│   ├── docker-entrypoint.sh          # ✅ Created
│   └── env-template.js               # ✅ Created
└── .github/
    └── workflows/
        └── deploy-admin-webapp.yml   # ✅ Created
```

## 🔗 Service URLs

After deployment, the service will be available at:

- **Cloud Run URL:** `https://core-admin-webapp-3dh2p4j4qq-uc.a.run.app` (generated)
- **Custom Domain:** TBD

## 🌐 Backend API URLs (Auto-injected)

These are automatically configured in Terraform:

```javascript
window.__env = {
  apiCoreAdminUrl: "https://core-admin-api-3dh2p4j4qq-uc.a.run.app",
  apiAiMentorUrl: "https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app",
  apiCurriculumUrl: "https://curriculum-service-3dh2p4j4qq-uc.a.run.app",
  apiCieUrl:
    "https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app",
  apiMathUrl: "https://mathematic-service-3dh2p4j4qq-uc.a.run.app",
  apiPhysicsUrl: "https://physics-gateway-3dh2p4j4qq-uc.a.run.app",
  apiChemistryUrl: "https://chemistry-gateway-3dh2p4j4qq-uc.a.run.app",
  apiSquadUrl: "https://squad-service-3dh2p4j4qq-uc.a.run.app",
  firebaseProjectId: "octo-education-ddc76",
  environment: "production",
};
```

## ⚡ Common Commands

### View Logs

```bash
gcloud run services logs read core-admin-webapp --region=us-central1 --limit=50
```

### Get Service URL

```bash
gcloud run services describe core-admin-webapp --region=us-central1 --format='value(status.url)'
```

### Update Environment Variable

```bash
gcloud run services update core-admin-webapp \
  --region=us-central1 \
  --set-env-vars="DEBUG=true"
```

### Rollback

```bash
gcloud run revisions list --service=core-admin-webapp --region=us-central1
gcloud run services update-traffic core-admin-webapp \
  --region=us-central1 \
  --to-revisions=REVISION_NAME=100
```

## 🎯 Naming Convention

Following the existing pattern:

- **Service Name:** `core-admin-webapp` (kebab-case)
- **Service Account:** `sa-core-admin-webapp`
- **Image Name:** `core-admin-webapp`
- **Module Name:** `core_admin_webapp` (snake_case in Terraform)

## 🔧 Configuration

**Resources:**

- CPU: 1 core
- Memory: 256Mi
- Min Instances: 0 (scales to zero)
- Max Instances: 5
- Concurrency: 80
- Port: 8080
- Ingress: Allow all traffic (public)

## 📞 Questions Answered

1. **Naming convention?** → `core-admin-webapp` ✅
2. **Firebase Hosting or Cloud Run?** → Cloud Run (more flexible for Angular SPA) ✅
3. **Environment variables?** → Injected at runtime via docker-entrypoint.sh ✅
4. **Deployment process?** → GitHub Actions → Artifact Registry → Cloud Run ✅

## 📚 Documentation

- **Full Guide:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Terraform:** [infra/env/main/main.tf](../../infra/env/main/main.tf)
- **Service Endpoints:** [SERVICE_ENDPOINTS.md](../../SERVICE_ENDPOINTS.md)
