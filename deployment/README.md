# Deployment Configurations

This directory contains deployment configurations for all services in the octo-education ecosystem.

## 📁 Structure

```
deployment/
└── core-admin-webapp/
    ├── Dockerfile                      # Multi-stage build (Angular + nginx)
    ├── nginx.conf                      # nginx configuration for SPA
    ├── docker-entrypoint.sh           # Runtime environment injection
    ├── env-template.js                # Environment variable template
    ├── DEPLOYMENT_GUIDE.md            # Comprehensive deployment guide
    ├── QUICK_REFERENCE.md             # Quick reference for common tasks
    └── .github-workflows-deploy-admin-webapp.yml  # GitHub Actions workflow
```

## 🚀 Services

### Core Admin Web App

**Status:** ✅ Infrastructure Ready  
**Type:** Angular 18 Frontend  
**Hosting:** Cloud Run  
**Documentation:** [deployment/core-admin-webapp/DEPLOYMENT_GUIDE.md](core-admin-webapp/DEPLOYMENT_GUIDE.md)

**Quick Start:**

```bash
# Deploy infrastructure
cd infra/env/main
terraform apply -target=module.sa_core_admin_webapp -target=module.core_admin_webapp

# Get service URL
terraform output -json | jq -r '.core_admin_webapp_url.value'
```

## 📋 Adding New Services

To add a new service deployment configuration:

1. Create a new directory under `deployment/`
2. Add Dockerfile and necessary configs
3. Create a Terraform module if needed
4. Add to `infra/env/main/main.tf`
5. Document in this README

## 🔗 Related Documentation

- [Infrastructure README](../README.md)
- [Service Endpoints](../SERVICE_ENDPOINTS.md)
- [Terraform Configuration](../infra/env/main/)
