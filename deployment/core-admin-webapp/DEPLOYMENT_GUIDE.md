# Core Admin Web App - Deployment Guide

**Service Name:** `core-admin-webapp`  
**Type:** Angular 18 Static Web Application  
**Hosting:** GCP Cloud Run (nginx container)  
**Project:** `octo-education-ddc76`  
**Region:** `us-central1`  
**Last Updated:** December 12, 2025

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Initial Setup](#initial-setup)
5. [Deployment Process](#deployment-process)
6. [Environment Configuration](#environment-configuration)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
9. [Rollback Procedures](#rollback-procedures)

---

## 🎯 Overview

The Core Admin Web App is an Angular 18 application that provides an administrative dashboard for managing the educational ecosystem. It includes:

- **Student Management** - View and manage student accounts
- **AI Mentor Monitoring** - Monitor AI mentor interactions
- **Curriculum Management** - Manage course content and objectives
- **Squad/Coalition Management** - Organize students into teams
- **Feature Flags** - Control feature rollouts
- **Analytics Dashboard** - View system metrics and usage
- **Audit Logs** - Track administrative actions

---

## 🏗️ Architecture

### Deployment Architecture

```
┌─────────────────────────────────────────────┐
│         GitHub Repository                    │
│    samahfashi6-blip/core_adminstration      │
└──────────────┬──────────────────────────────┘
               │
               │ Push to main/production
               ▼
┌─────────────────────────────────────────────┐
│       GitHub Actions Workflow                │
│  - Build Angular app (ng build --prod)      │
│  - Build Docker image (nginx + static)      │
│  - Push to Artifact Registry                │
│  - Deploy to Cloud Run                      │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│    GCP Artifact Registry                     │
│  us-central1-docker.pkg.dev/                │
│    octo-education-ddc76/services/           │
│      core-admin-webapp:latest               │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│         Cloud Run Service                    │
│  Name: core-admin-webapp                    │
│  Region: us-central1                        │
│  Runtime: nginx:1.25-alpine                 │
│  Port: 8080                                 │
│  Auth: Allow unauthenticated (public)       │
└─────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│         Backend Services                     │
│  - Core Admin API                           │
│  - AI Mentor Service                        │
│  - Curriculum Service                       │
│  - CIE API                                  │
│  - Math/Physics/Chemistry Services          │
│  - Squad Service                            │
└─────────────────────────────────────────────┘
```

### Runtime Configuration Flow

1. **Container Startup** → `docker-entrypoint.sh` runs
2. **Environment Injection** → Env vars → `/usr/share/nginx/html/assets/env.js`
3. **Angular Loads** → Reads `window.__env` object
4. **API Calls** → Uses injected URLs for backend communication

---

## ✅ Prerequisites

### 1. GCP Setup

```bash
# Authenticate with GCP
gcloud auth login
gcloud config set project octo-education-ddc76

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com
```

### 2. Terraform Infrastructure

The infrastructure must be deployed first using Terraform:

```bash
cd infra/env/main
terraform init
terraform plan
terraform apply
```

This creates:

- Service account: `sa-core-admin-webapp@octo-education-ddc76.iam.gserviceaccount.com`
- Cloud Run service: `core-admin-webapp`
- IAM bindings and permissions

### 3. Artifact Registry Repository

```bash
# Create repository if not exists
gcloud artifacts repositories create services \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker images for microservices"
```

### 4. GitHub Secrets

Configure these secrets in your GitHub repository:

| Secret Name                      | Description                                   |
| -------------------------------- | --------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider for GitHub Actions |
| `GCP_SERVICE_ACCOUNT`            | Service account email for deployment          |

---

## 🚀 Initial Setup

### Step 1: Copy Deployment Files to Your Repository

Copy the following files from `octo-infra` to your `core_adminstration` repository:

```bash
# In your core_adminstration repository
mkdir -p deployment

# Copy files
cp /path/to/octo-infra/deployment/core-admin-webapp/Dockerfile ./deployment/
cp /path/to/octo-infra/deployment/core-admin-webapp/nginx.conf ./deployment/
cp /path/to/octo-infra/deployment/core-admin-webapp/docker-entrypoint.sh ./deployment/
cp /path/to/octo-infra/deployment/core-admin-webapp/env-template.js ./deployment/

# Copy GitHub workflow
mkdir -p .github/workflows
cp /path/to/octo-infra/deployment/core-admin-webapp/.github-workflows-deploy-admin-webapp.yml \
   .github/workflows/deploy-admin-webapp.yml
```

### Step 2: Update Angular Configuration

#### 2.1 Add Environment Service

Create `src/app/core/services/environment.service.ts`:

```typescript
import { Injectable } from "@angular/core";

interface Environment {
  apiCoreAdminUrl: string;
  apiAiMentorUrl: string;
  apiCurriculumUrl: string;
  apiCieUrl: string;
  apiMathUrl: string;
  apiPhysicsUrl: string;
  apiChemistryUrl: string;
  apiSquadUrl: string;
  firebaseProjectId: string;
  environment: string;
  appVersion: string;
  enableAnalytics: boolean;
  debug: boolean;
}

declare global {
  interface Window {
    __env: Environment;
  }
}

@Injectable({
  providedIn: "root",
})
export class EnvironmentService {
  private env: Environment;

  constructor() {
    // Load environment from window object (injected by docker-entrypoint.sh)
    this.env = window.__env || this.getDefaultEnvironment();
  }

  get apiCoreAdminUrl(): string {
    return this.env.apiCoreAdminUrl;
  }

  get apiAiMentorUrl(): string {
    return this.env.apiAiMentorUrl;
  }

  get apiCurriculumUrl(): string {
    return this.env.apiCurriculumUrl;
  }

  get apiCieUrl(): string {
    return this.env.apiCieUrl;
  }

  get apiMathUrl(): string {
    return this.env.apiMathUrl;
  }

  get apiPhysicsUrl(): string {
    return this.env.apiPhysicsUrl;
  }

  get apiChemistryUrl(): string {
    return this.env.apiChemistryUrl;
  }

  get apiSquadUrl(): string {
    return this.env.apiSquadUrl;
  }

  get firebaseProjectId(): string {
    return this.env.firebaseProjectId;
  }

  get environment(): string {
    return this.env.environment;
  }

  get appVersion(): string {
    return this.env.appVersion;
  }

  get isProduction(): boolean {
    return this.env.environment === "production";
  }

  get enableAnalytics(): boolean {
    return this.env.enableAnalytics;
  }

  get debug(): boolean {
    return this.env.debug;
  }

  private getDefaultEnvironment(): Environment {
    return {
      apiCoreAdminUrl: "",
      apiAiMentorUrl: "",
      apiCurriculumUrl: "",
      apiCieUrl: "",
      apiMathUrl: "",
      apiPhysicsUrl: "",
      apiChemistryUrl: "",
      apiSquadUrl: "",
      firebaseProjectId: "octo-education-ddc76",
      environment: "development",
      appVersion: "1.0.0",
      enableAnalytics: false,
      debug: true,
    };
  }
}
```

#### 2.2 Update index.html

Add this in your `src/index.html` before the closing `</head>` tag:

```html
<!-- Runtime environment configuration -->
<script src="assets/env.js"></script>
```

#### 2.3 Update angular.json

Ensure your build output directory is `dist/core-admin-webapp`:

```json
{
  "projects": {
    "core-admin-webapp": {
      "architect": {
        "build": {
          "options": {
            "outputPath": "dist/core-admin-webapp"
          }
        }
      }
    }
  }
}
```

### Step 3: Update Your Services to Use EnvironmentService

Example for API services:

```typescript
import { Injectable } from "@angular/core";
import { HttpClient } from "@angular/common/http";
import { EnvironmentService } from "./environment.service";

@Injectable({
  providedIn: "root",
})
export class AdminApiService {
  constructor(private http: HttpClient, private env: EnvironmentService) {}

  getStudents() {
    return this.http.get(`${this.env.apiCoreAdminUrl}/api/students`);
  }
}
```

---

## 📦 Deployment Process

### Option 1: Automated Deployment (Recommended)

1. **Push to main branch:**

   ```bash
   git add .
   git commit -m "Deploy admin webapp"
   git push origin main
   ```

2. **Monitor deployment:**
   - Go to GitHub Actions tab
   - Watch the "Deploy Core Admin Web App to Cloud Run" workflow
   - Check the summary for the deployed URL

### Option 2: Manual Deployment

```bash
# 1. Build locally
cd /path/to/core_adminstration
docker build -t core-admin-webapp:latest -f deployment/Dockerfile .

# 2. Tag for Artifact Registry
docker tag core-admin-webapp:latest \
  us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest

# 3. Push to registry
docker push us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest

# 4. Deploy to Cloud Run
gcloud run deploy core-admin-webapp \
  --image=us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:latest \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated
```

### Option 3: Using Terraform

```bash
# In octo-infra repository
cd infra/env/main

# Ensure the image is pushed, then apply
terraform apply -target=module.core_admin_webapp
```

---

## ⚙️ Environment Configuration

### Available Environment Variables

| Variable              | Description                 | Example                                     |
| --------------------- | --------------------------- | ------------------------------------------- |
| `API_CORE_ADMIN_URL`  | Core Admin API endpoint     | `https://core-admin-api-*.run.app`          |
| `API_AI_MENTOR_URL`   | AI Mentor Service endpoint  | `https://ai-mentor-service-*.run.app`       |
| `API_CURRICULUM_URL`  | Curriculum Service endpoint | `https://curriculum-service-*.run.app`      |
| `API_CIE_URL`         | CIE API endpoint            | `https://curriculum-intelligence-*.run.app` |
| `API_MATH_URL`        | Math Service endpoint       | `https://mathematic-service-*.run.app`      |
| `API_PHYSICS_URL`     | Physics Gateway endpoint    | `https://physics-gateway-*.run.app`         |
| `API_CHEMISTRY_URL`   | Chemistry Gateway endpoint  | `https://chemistry-gateway-*.run.app`       |
| `API_SQUAD_URL`       | Squad Service endpoint      | `https://squad-service-*.run.app`           |
| `FIREBASE_PROJECT_ID` | Firebase project ID         | `octo-education-ddc76`                      |
| `ENVIRONMENT`         | Environment name            | `production`                                |
| `APP_VERSION`         | Application version         | `1.0.0`                                     |
| `ENABLE_ANALYTICS`    | Enable analytics            | `true`                                      |
| `DEBUG`               | Enable debug mode           | `false`                                     |

### Updating Environment Variables

**Via Terraform (Recommended):**

Edit `infra/env/main/main.tf` and update the `env_vars` block:

```terraform
module "core_admin_webapp" {
  # ... other config ...

  env_vars = {
    API_CORE_ADMIN_URL = module.core_admin_api.url
    # ... add or update variables ...
  }
}
```

Then apply:

```bash
terraform apply
```

**Via gcloud CLI:**

```bash
gcloud run services update core-admin-webapp \
  --region=us-central1 \
  --set-env-vars="NEW_VAR=value"
```

---

## 🔄 CI/CD Pipeline

### Pipeline Stages

1. **Checkout** - Clone repository
2. **Authenticate** - GCP authentication via Workload Identity
3. **Build** - Build Docker image with Angular app
4. **Push** - Push to Artifact Registry
5. **Deploy** - Deploy to Cloud Run
6. **Test** - Run smoke tests
7. **Notify** - Report status

### Triggering Deployments

- **Automatic:** Push to `main` or `production` branch
- **Manual:** GitHub Actions → "Deploy Core Admin Web App to Cloud Run" → Run workflow

### Workflow Configuration

Located at: `.github/workflows/deploy-admin-webapp.yml`

Key features:

- Workload Identity for secure GCP access
- Multi-stage Docker build
- Automated smoke tests
- Deployment summary in GitHub Actions UI

---

## 📊 Monitoring & Troubleshooting

### View Logs

```bash
# View recent logs
gcloud run services logs read core-admin-webapp \
  --region=us-central1 \
  --limit=100

# Follow logs in real-time
gcloud run services logs tail core-admin-webapp \
  --region=us-central1
```

### Check Service Status

```bash
# Get service details
gcloud run services describe core-admin-webapp \
  --region=us-central1

# Get service URL
gcloud run services describe core-admin-webapp \
  --region=us-central1 \
  --format='value(status.url)'
```

### Common Issues

#### Issue: "Container failed to start"

**Solution:**

```bash
# Check build logs
gcloud builds list --limit=5

# Check service logs
gcloud run services logs read core-admin-webapp --region=us-central1

# Verify Dockerfile and entrypoint script
```

#### Issue: "API calls failing"

**Solution:**

```bash
# Verify environment variables
gcloud run services describe core-admin-webapp \
  --region=us-central1 \
  --format='value(spec.template.spec.containers[0].env)'

# Check if env.js is generated correctly
# Access https://[your-url]/assets/env.js
```

#### Issue: "404 on Angular routes"

**Solution:** Check nginx.conf has:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

---

## ⏮️ Rollback Procedures

### Rollback to Previous Version

```bash
# List recent revisions
gcloud run revisions list \
  --service=core-admin-webapp \
  --region=us-central1

# Rollback to specific revision
gcloud run services update-traffic core-admin-webapp \
  --region=us-central1 \
  --to-revisions=core-admin-webapp-00002-abc=100
```

### Rollback via Terraform

```bash
# In main.tf, update the image tag
module "core_admin_webapp" {
  image = "us-central1-docker.pkg.dev/octo-education-ddc76/services/core-admin-webapp:previous-tag"
}

# Apply
terraform apply
```

---

## 📞 Support & Contact

**Team:** Infrastructure Team  
**Repository:** `samahfashi6-blip/core_adminstration`  
**Infrastructure Repo:** `octo-infra`  
**Slack Channel:** #infra-support

---

## 🔐 Security Considerations

1. **Authentication:** Implement Firebase Auth checks in the Angular app
2. **CORS:** Backend services should whitelist the admin webapp URL
3. **Content Security Policy:** Configured in nginx.conf
4. **HTTPS Only:** Cloud Run provides automatic HTTPS
5. **Service Account:** Minimal permissions (logging + monitoring only)

---

## 📝 Next Steps

1. ✅ **Infrastructure deployed** via Terraform
2. ⏳ **Copy deployment files** to your repository
3. ⏳ **Update Angular app** to use EnvironmentService
4. ⏳ **Configure GitHub secrets** for Workload Identity
5. ⏳ **Push to main** to trigger deployment
6. ⏳ **Test the deployed app** at the Cloud Run URL
7. ⏳ **Configure custom domain** (optional)

---

**Deployment Status:** ✅ Infrastructure Ready  
**Next Action:** Copy files to `core_adminstration` repository and update Angular app
