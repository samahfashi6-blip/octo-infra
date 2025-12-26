# Response to Core Service Team: Admin API Deployment

**To:** Core Service Development Team  
**From:** Terraform Infrastructure Team  
**Date:** December 26, 2025  
**Re:** Core Admin API Handoff - Deployment Plan

---

## Summary

Hi Core Admin API team — thanks for the handoff. We have everything we need to deploy this service. Here's what we're going to implement based on your requirements:

---

## What We're Implementing

### Service Configuration

- Deploy **Core Administration API** to **Cloud Run** (Go 1.23 / Fiber)
- Container listens on **port 8080** (standard)
- Health check configured on `GET /health` (no authentication required)

### Access & Security

- Configure **public Cloud Run access**: Cloud Run ingress set to `INGRESS_TRAFFIC_ALL`
- **No internal HTTPS Load Balancer** and **no internal DNS** required
- Keep **WebSocket support** available on the public endpoint for `GET /ws` (HTTP/1.1 upgrade)
- All admin endpoints protected by **Firebase ID token** authentication (you handle this in the app)

Optional: if you want to restrict access further at the edge, we can place **Cloud Armor** in front of the public endpoint (IP allowlist).

### Resource Sizing (Low-Traffic Optimized)

Based on your "1–3 admin users, very low traffic" requirement:

```yaml
CPU: 0.5 (half vCPU - sufficient for low admin workload)
Memory: 512Mi
Min Instances: 0 (scale to zero when idle)
Max Instances: 1-2 (sufficient for admin workload)
Concurrency: 1 (required when CPU < 1 vCPU on Cloud Run)
```

**Note:** This configuration optimizes for cost while maintaining responsiveness for admin users.

### Service Account & IAM Permissions

Create/attach a dedicated runtime service account with least-privilege access:

**Required (always enabled):**

- ✅ `roles/datastore.user` - Firestore access for admin metadata + audit logs
- ✅ `roles/secretmanager.secretAccessor` - Access to JWT_SECRET and other secrets
- ✅ `roles/logging.logWriter` - Cloud Logging
- ✅ `roles/monitoring.metricWriter` - Cloud Monitoring

**Conditional (based on active features):**

- `roles/bigquery.jobUser` + `roles/bigquery.dataViewer` - **If analytics endpoints are enabled**
- `roles/storage.objectAdmin` on curriculum bucket - **If curriculum upload endpoints are used**

### Environment Variables & Secrets

Wire configuration via Terraform + Secret Manager:

**Standard environment variables:**

```yaml
GCP_PROJECT_ID: "octo-education-ddc76"
ENVIRONMENT: "production"
FIRESTORE_DATABASE: "(default)" # Firestore default database
```

**Configuration from you:**

```yaml
ALLOWED_ORIGINS: "[Admin Web App origin URL]"
BIGQUERY_DATASET: "[dataset name if analytics enabled]"
STORAGE_BUCKET: "[bucket name if curriculum enabled]"
```

**Secrets (from Secret Manager):**

```yaml
JWT_SECRET: core-admin-api-jwt-secret (version: latest)
```

### Not Required

Based on your handoff, we're **not** provisioning:

- ❌ Pub/Sub topics or subscriptions
- ❌ Memorystore/Redis
- ❌ Internal HTTPS load balancer / internal DNS

---

## Information We Need Before Deployment

Please confirm the following details so we can apply Terraform:

1. **Admin Web App origin** (for CORS / `ALLOWED_ORIGINS`)

   - Example: `https://admin.octo-education.com`
   - Your URL: `_______________________________`

2. **BigQuery analytics**

   - Confirmed: **not enabled in this release** (we’ll request dataset + IAM later)

3. **Cloud Storage curriculum upload**

   - Confirmed: **not enabled in this release** (bucket name will be provided later)

4. **Cloud Armor restriction (optional)**

   - [ ] Not needed
   - [ ] Yes - restrict by IP allowlist (we'll need allowed CIDRs): `_______________________________`

---

## Deployment Timeline

Once you provide the information above:

1. **Day 1:** We apply Terraform configuration

   - Deploy Cloud Run service with public ingress (`INGRESS_TRAFFIC_ALL`)
   - Configure service account + IAM
   - Wire environment variables + secrets

2. **Day 1-2:** Deploy to **staging environment** first

   - Share staging public Cloud Run URL
   - You test: authentication, WebSocket, health checks

3. **Day 2:** After your approval → **deploy to production**
   - Share production public Cloud Run URL

**Estimated timeline:** 1-2 business days from confirmation

---

## Cost Estimate

**Monthly cost breakdown:**

- Cloud Run (low traffic, 0-2 instances): ~$5-10/month (based on actual usage)

**Total: ~$5-10/month** (plus any optional edge controls like Cloud Armor, if enabled)

This is acceptable for a low-traffic admin service with application-layer security.

---

## Terraform Team Response to Your Clarifications

Thanks for the quick review! Here are the confirmations you requested:

### 1. Ingress Setting ✅

Status: Public Cloud Run access

- Final setting: `INGRESS_TRAFFIC_ALL`
- No internal HTTPS load balancer
- No internal DNS

### 2. CPU Sizing ✅

Status: CPU 0.5 for low admin workload

- CPU: `0.5` (half vCPU)
- Memory: `512Mi`
- Max Instances: `1-2`
- Min Instances: `0` (scale to zero)

This is appropriate for 1-3 admin users and provides sufficient resources while optimizing cost.

### 3. Firestore Database Value ✅

**Confirmed: `FIRESTORE_DATABASE: "(default)"`**

Our convention uses `"(default)"` (with parentheses) to reference Firestore's default database. This matches GCP's naming for the default database instance.

---

## Received Your Inputs

We've received your configuration values:

```yaml
Admin Web App Origin (ALLOWED_ORIGINS): <TBD>
BigQuery Analytics: Not enabled in this release
Curriculum Upload: Not enabled in this release
JWT_SECRET: core-admin-api-jwt-secret
```

### Secret Name Convention

For `JWT_SECRET`, we can use either:

- **Option A:** `jwt-secret` (shared/generic secret, if other services use the same JWT secret)
- **Option B:** `core-admin-api-jwt-secret` (service-specific secret, recommended for isolation)

**Our recommendation:** Use `core-admin-api-jwt-secret` for better secret isolation and service-specific key rotation policies.

**Confirmed:** We'll use `core-admin-api-jwt-secret`.

---

## Ready to Proceed

Once you provide the `<TBD>` values above and confirm the secret name, we'll:

1. Apply Terraform configuration
2. Deploy to **staging first** (public Cloud Run URL)
3. Wait for your approval after testing
4. Promote to **production**

All three clarifications are now confirmed and consistent. We're ready when you are!

---

## Next Steps

1. **You:** Provide the information listed above (Admin Web App origin, optional Cloud Armor CIDRs, feature flags)
2. **Us:** Apply Terraform and deploy to staging
3. **You:** Test and approve staging deployment
4. **Us:** Promote to production and share service URL

---

## Questions or Concerns?

**Slack:** #infrastructure-terraform  
**This Thread:** Reply here with answers to open questions

We're ready to proceed as soon as you confirm the configuration!

---

Terraform Infrastructure Team
