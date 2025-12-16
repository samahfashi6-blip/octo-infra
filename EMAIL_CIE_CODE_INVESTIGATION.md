# 📧 Re: CIE API Code Investigation Results

**To:** Infrastructure Team  
**From:** Curriculum Ingestion Team  
**Subject:** Re: CIE API Permission Issue Investigation - Code Review Complete  
**Date:** December 16, 2025

---

Hi Infrastructure Team,

Thank you for investigating the IAM configuration. We have reviewed our code implementation and found some important discrepancies.

## ✅ Our Code Implementation (Appears Correct)

We reviewed the authentication implementation and it follows best practices:

```go
// File: internal/orchestrator/orchestrator.go

// 1. Create authenticated client with correct audience
client, err := idtoken.NewClient(ctx, o.config.CieApiUrl)
// CieApiUrl = "https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app"

// 2. Build endpoint path
endpoint := fmt.Sprintf("%s/api/v1/objectives/process", o.config.CieApiUrl)

// 3. Use authenticated client to POST
resp, err := client.Post(endpoint, "application/json", bytes.NewBuffer(body))
```

**This matches the pattern you described:**

- ✅ Using `idtoken.NewClient` (not regular http.Client)
- ✅ Audience is the base service URL (no trailing slash)
- ✅ Calling endpoint on the same base URL

## 🚨 CRITICAL ISSUE DISCOVERED

However, we found a **URL mismatch** between different sources:

### URL in Environment Variable (from Terraform):

```
https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
```

### URL in API Documentation (API.md):

```
https://curriculum-intelligence-engine-api-d7v6h2n4rq-uc.a.run.app
```

**Notice the difference:** `3dh2p4j4qq` vs `d7v6h2n4rq`

## 🔍 Testing Results

We tested both URLs:

### URL from Terraform (Currently Configured):

```bash
$ curl https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app/api/v1/objectives/process

HTTP/2 404
404 page not found
```

### URL from API Documentation:

```bash
$ curl https://curriculum-intelligence-engine-api-d7v6h2n4rq-uc.a.run.app/api/v1/objectives/process

HTTP/2 500
<title>500 Server Error</title>
The service you requested is not available yet.
```

**Analysis:**

- `3dh2p4j4qq`: Returns 404 → Service doesn't exist or path not found
- `d7v6h2n4rq`: Returns 500 → Service exists but has internal error

## ❓ Questions for Infrastructure Team

1. **Which URL is the correct CIE API?**

   - Is it `curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app` (from Terraform)?
   - Or `curriculum-intelligence-engine-api-d7v6h2n4rq-uc.a.run.app` (from API docs)?

2. **Has the CIE API service been redeployed recently?**

   - Cloud Run generates new URLs when services are redeployed
   - The hash in the URL changes with each deployment

3. **Does the CIE API `/api/v1/objectives/process` endpoint exist?**

   - Can you verify the service is running and the endpoint is available?
   - Can you test it with a service account token?

4. **If the URL has changed, please update:**
   - The `CIE_API_URL` environment variable in Terraform
   - The IAM binding to point to the correct service

## 🔧 Suggested Next Steps

### Option 1: If `d7v6h2n4rq` is correct

Update the environment variable to:

```hcl
CIE_API_URL = "https://curriculum-intelligence-engine-api-d7v6h2n4rq-uc.a.run.app"
```

And verify IAM binding on that service:

```bash
gcloud run services get-iam-policy curriculum-intelligence-engine-api \
  --region=us-central1 \
  --format=json
```

### Option 2: If `3dh2p4j4qq` is correct

Please verify:

- The service exists and is healthy
- The `/api/v1/objectives/process` endpoint is implemented
- The service is not returning 404 for valid paths

## 💡 Root Cause Hypothesis

Based on our investigation, the **403 error** might actually be a **404 error** being misreported. Here's why:

1. Our function calls: `https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app/api/v1/objectives/process`
2. That URL returns 404 (path not found)
3. Cloud Run sometimes returns 403 for authentication issues OR missing services
4. The IAM binding might be on a different service URL (`d7v6h2n4rq`)

## 📊 Impact

Until the correct URL is configured, the pipeline cannot notify the CIE service. The workaround is that objectives are still saved to Firestore staging collection, so no data is lost.

---

## 🙏 Action Required

Please confirm:

1. The correct CIE API service URL
2. That the service is deployed and healthy
3. That IAM bindings are on the correct service
4. Update our `CIE_API_URL` environment variable if needed

Once confirmed, we can redeploy and test immediately.

Thank you for your help!

---

**Curriculum Ingestion Team**

### Debug Commands Run:

```bash
# Check configured URL
$ gcloud functions describe curriculum-ingestion --region=us-central1 \
  --format="value(serviceConfig.environmentVariables.CIE_API_URL)"
https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app

# Test both URLs
$ curl https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app/api/v1/objectives/process
→ 404 page not found

$ curl https://curriculum-intelligence-engine-api-d7v6h2n4rq-uc.a.run.app/api/v1/objectives/process
→ 500 Server Error (service unavailable)
```
