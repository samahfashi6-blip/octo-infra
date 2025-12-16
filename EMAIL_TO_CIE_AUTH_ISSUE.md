# 📧 URGENT: CIE API Authentication Middleware Issue

**To:** CIE Development Team  
**From:** Infrastructure Team  
**Subject:** 🚨 CIE API Rejecting Valid Authenticated Requests (403 Forbidden)  
**Date:** December 16, 2025

---

Hi CIE Team,

We've investigated a 403 Forbidden error reported by the Curriculum Ingestion team and identified an issue in the CIE API service.

## 🔍 Issue Summary

The CIE API endpoint `/api/v1/objectives/process` is **rejecting valid authenticated requests** from the curriculum ingestion function.

### Evidence from Your Service Logs:
```
2025-12-16 10:45:27 POST 403 /api/v1/objectives/process | 122ms
2025-12-16 10:53:04 POST 403 /api/v1/objectives/process | 566µs
```

## ✅ Verified Infrastructure Configuration

We confirmed:
1. **IAM Permission:** `sa-curriculum-ingestion` has `roles/run.invoker` on your service ✅
2. **Service Account:** Ingestion function runs as the correct service account ✅
3. **Client Code:** They're using `idtoken.NewClient` with correct audience ✅
4. **Service URL:** Correct (`curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app`) ✅

## 🚨 Root Cause: Authentication Middleware Issue

The requests are **reaching your service** but being rejected with 403. This indicates a problem in your API's authentication middleware.

### Comparison:
```
✅ GET /health → 200 OK (no auth required, works fine)
🔴 POST /api/v1/objectives/process → 403 Forbidden (auth required, fails)
```

## 🔍 Possible Causes

### 1. **Token Validation Logic Error**
Your middleware might be incorrectly validating the ID token:
```go
// Example issue - checking wrong audience or issuer
func validateToken(token string) error {
    // Are you checking the token audience matches your service URL?
    // Are you verifying the issuer is Google?
}
```

### 2. **Missing Service Account Allowlist**
You might be checking if the calling service account is in an allowlist:
```go
// Example issue - hardcoded allowed accounts
allowedAccounts := []string{
    "sa-old-account@project.iam.gserviceaccount.com", // ❌ Old account
}
// Missing: sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com
```

### 3. **Authorization Header Not Processed**
Your middleware might not be reading the `Authorization: Bearer` header:
```go
// Example issue
authHeader := r.Header.Get("Authorization") // Returns ""?
if authHeader == "" {
    return 403 // ❌ Rejects valid token
}
```

### 4. **IP/Network Restrictions**
You might have IP allowlists that don't include Cloud Function IPs.

## 🛠️ Debugging Steps

### 1. Add Detailed Logging
Log the authentication flow:
```go
log.Printf("Authorization header present: %v", r.Header.Get("Authorization") != "")
log.Printf("Extracted token: %s...", token[:20])
log.Printf("Token validation result: %v", err)
log.Printf("Caller service account: %s", extractedEmail)
```

### 2. Check Your Auth Middleware
Review the middleware that runs before `/api/v1/objectives/process`:
- Is it correctly extracting the JWT from the `Authorization` header?
- Is it validating against the right audience?
- Is it allowing the service account `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`?

### 3. Test with Manual Token
Generate a token manually and test:
```bash
# Generate token as the ingestion service account
TOKEN=$(gcloud auth print-identity-token \
  --impersonate-service-account=sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com \
  --audiences=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app)

# Test your endpoint
curl -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"curriculum_id":"test","objectives":[]}' \
  https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app/api/v1/objectives/process
```

## 📊 Impact

- Curriculum ingestion pipeline cannot notify your service of new objectives
- Objectives are saved to Firestore staging but not processed for embeddings
- **No data loss** (objectives are staged), but CIE processing is blocked

## 🎯 Action Required

Please:
1. Review your authentication middleware code
2. Add detailed logging to identify where the 403 is triggered
3. Test with a manually generated token (command above)
4. Let us know what you find

We're standing by to assist with testing once you've identified the issue.

---

**Infrastructure Team**
