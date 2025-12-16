# 📧 Re: CIE API URL Verification & Issue Analysis

**To:** Curriculum Ingestion Team  
**From:** Infrastructure Team  
**Subject:** CIE API URL Confirmed - Authentication Issue in CIE Service Code  
**Date:** December 16, 2025

---

Hi Team,

Excellent investigation! We've verified the configuration and found the root cause.

## ✅ URL Confirmation

The **correct** CIE API URL is:

```
https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
```

We verified this is the active service in production:

```bash
$ gcloud run services describe curriculum-intelligence-engine-api --region=us-central1
https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
```

The other URL (`d7v6h2n4rq`) appears to be from an **old deployment** or outdated documentation.

## 🔍 Root Cause Identified

We analyzed the CIE API logs and found:

```
✅ GET /health → 200 OK (endpoint works, service is healthy)
🔴 POST /api/v1/objectives/process → 403 Forbidden (endpoint exists but rejects requests)
❌ GET /api/v1/objectives/process → 404 Not Found (wrong HTTP method)
```

**Key Finding:** The endpoint `/api/v1/objectives/process` **DOES exist** (POST returns 403, not 404), but the **CIE API service is rejecting authenticated requests**.

## 🎯 The Real Problem

Your code implementation is **100% correct**:

- ✅ Using `idtoken.NewClient` with correct audience
- ✅ Calling the right URL
- ✅ Using POST method

**The issue is in the CIE API service code**, not your ingestion function or infrastructure.

### Evidence from CIE API Logs:

```
2025-12-16 10:53:04 POST 403 /api/v1/objectives/process
2025-12-16 10:53:04 [GIN] | 403 | 566.574µs | POST /api/v1/objectives/process
```

The request is reaching the CIE API service, but something in their middleware is rejecting it with 403.

## 🚨 Issue Forwarded to CIE Team

We are notifying the CIE Development Team that their API service has an authentication middleware issue:

**Possible causes:**

1. Their authentication middleware is incorrectly validating the ID token
2. They're checking for a specific claim that doesn't exist in service-to-service tokens
3. They have IP/network restrictions that block Cloud Function IPs
4. Their code is not properly handling the `Authorization: Bearer` header

## ✅ No Action Required from Your Team

Your implementation is correct. The infrastructure is correct. This is a **CIE API service bug** that needs to be fixed by the CIE team.

We'll keep you updated on the resolution.

---

**Infrastructure Team**

### For Reference:

- Correct URL: `https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app`
- Your IAM permission: ✅ Confirmed
- Your service account: ✅ Correct
- Your code: ✅ Correct implementation
- **Issue:** CIE API middleware rejecting valid authenticated requests
