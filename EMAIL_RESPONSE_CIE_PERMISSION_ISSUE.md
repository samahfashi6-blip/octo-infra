# 📧 Response: CIE API Permission Issue Investigation

**To:** Curriculum Ingestion Team
**From:** Infrastructure Team
**Subject:** Re: 🚨 CIE API Returns 403 Forbidden - IAM Permission Issue

---

Hi Team,

We have investigated the 403 Forbidden issue you reported.

## ✅ Verification Results

We verified the infrastructure configuration and everything appears correct:

1.  **IAM Binding Exists:**
    The service account `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com` **DOES** have `roles/run.invoker` on the CIE API.
    ```bash
    $ gcloud run services get-iam-policy curriculum-intelligence-engine-api ...
    "serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com"
    ```

2.  **Function Service Account Correct:**
    The function is correctly running as `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com`.

3.  **Ingress Settings Correct:**
    The CIE API is configured with `run.googleapis.com/ingress: all`, allowing traffic from all sources (including internal).

## 🔍 Potential Root Causes

Since the infrastructure configuration is correct, the 403 error might be caused by:

1.  **Token Audience Mismatch:**
    Ensure your code is generating the ID token with the **exact** audience URL of the CIE API service:
    `https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app`
    
    *If your code uses a trailing slash or different protocol in the audience claim, the token will be rejected.*

2.  **Token Generation Issue:**
    Verify that `idtoken.NewClient` is successfully retrieving a token.

## 🛠️ Troubleshooting Step

To rule out infrastructure propagation issues, we have re-applied the IAM policy binding manually just to be safe:

```bash
gcloud run services add-iam-policy-binding curriculum-intelligence-engine-api \
  --region=us-central1 \
  --member="serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

## 👉 Action Required

Please **check your code** to ensure the ID token is being generated for the correct audience.

If the issue persists, please share the code snippet where you initialize the `idtoken.NewClient` so we can verify the implementation.

Best,
Infrastructure Team
