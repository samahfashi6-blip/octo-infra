# Terraform Handoff — Core Administration API (Cloud Run)

**Date:** 2025-12-26  
**Service:** Core Administration API (Go 1.23 + Fiber)  
**Deployment intent:** **Public Cloud Run access** (no internal LB/VPN/DNS)  
**Traffic expectation:** Single admin user (very low traffic)  
**Not used:** Pub/Sub, Memorystore/Redis

---

## 1) What this service is (plain English)

The Core Administration API is the backend for the Admin Web App. It provides admin-only APIs for:

- Student management (view, suspend/unsuspend, login history, password reset)
- AI Mentor monitoring (review conversations, flagged content, moderation)
- Curriculum ingestion/management (uploads, concept extraction/job tracking)
- Feature flags (toggle/rollout management)
- Analytics (BigQuery-backed reporting)
- Audit logs (track every admin action)
- Real-time updates via WebSocket

---

## 2) Endpoints / routing requirements

- **Health (no auth):** `GET /health`
- **REST base path:** `/api/v1/*`
- **WebSocket:** `GET /ws` (requires auth)

**WebSocket support is required on the public endpoint** (HTTP/1.1 upgrade).

---

## 3) Auth requirements (important)

- All admin endpoints (everything except `/health`) require:
  - `Authorization: Bearer <Firebase ID token>`
- RBAC is enforced via Firebase custom claims on the ID token (e.g., `role`, `permissions`).

Note: There is also an API endpoint that can issue a service JWT (`/api/v1/auth/refresh`), but **current request authentication is still performed using Firebase ID tokens** for protected routes.

---

## 4) Cloud Run requirements

- Runtime: Go service in a container
- **Port:** `8080` (service reads `PORT`; default `8080`)
- **Ingress:** **public** (`INGRESS_TRAFFIC_ALL`)
- **Scaling (low traffic):** keep conservative
  - Suggested: `max_instances = 1..2`
  - Suggested: `min_instances = 0`
  - CPU / Memory: `0.5 vCPU` / `512Mi`
  - Concurrency: default is fine unless you have a standard
- Service account: dedicated runtime SA (least privilege)

---

## 5) Load balancer / DNS requirements

Not required for this service in this release.

- No internal HTTPS load balancer
- No internal DNS record

Optional hardening (only if needed): place Cloud Armor (IP allowlist) in front of the public endpoint.

---

## 6) Required GCP dependencies & IAM

### Firestore

Used for admin metadata and audit logs.

- Minimum: `roles/datastore.user` on project (or tighter if you scope by database/project conventions)

### BigQuery

Not enabled in this release.

If/when analytics endpoints are enabled later:

- `roles/bigquery.jobUser` on project
- Dataset-level permissions to the analytics dataset:
  - at least read (`bigquery.dataViewer`)
  - write only if you explicitly materialize or persist results

### Cloud Storage (curriculum)

Not enabled in this release.

If/when curriculum upload/ingestion is enabled later:

- Bucket-level permissions for the curriculum bucket:
  - read/write as required

### Secret Manager (recommended)

- `roles/secretmanager.secretAccessor` for runtime SA

### Logging / Monitoring

- Standard Cloud Run logging + metrics enabled

---

## 7) Configuration: environment variables & secrets

Prefer: Terraform wires values via Secret Manager → Cloud Run env vars.

### Required

- `GCP_PROJECT_ID`
- `JWT_SECRET` (store as secret; do not use a placeholder in prod)
  - Secret name: `core-admin-api-jwt-secret`

### Recommended

- `ALLOWED_ORIGINS` (Admin Web App origin)
  - Note: current behavior expects a single origin string; if multiple origins are needed, we may need an application change.

### Optional (feature-driven)

- `BIGQUERY_DATASET`
- `STORAGE_BUCKET`
- `FIRESTORE_DATABASE`

---

## 8) Operational notes

- For public access: all endpoints except `GET /health` must enforce Firebase ID token + RBAC at the application layer.
- Request tracing: service supports request IDs; LB should pass through `X-Request-ID` when present.

---

## 9) Open questions for Terraform team

- Confirm Cloud Run is configured for public ingress (`INGRESS_TRAFFIC_ALL`).
- Confirm whether you want to add Cloud Armor IP allowlisting in front of the public endpoint.
- Confirm the Admin Web App origin for `ALLOWED_ORIGINS` when available.
