# CIE Worker - Pub/Sub Integration Issue Report

**Date:** December 15, 2025  
**To:** CIE Team  
**From:** Octo Infrastructure Team  
**Subject:** URGENT: CIE Worker Unable to Process Curriculum Objectives Messages

---

## Executive Summary

We have successfully completed the infrastructure setup for the Pub/Sub integration between the Curriculum Ingestion Service and the CIE Worker. However, the CIE Worker is unable to process messages due to a **hardcoded subscription name** in the worker code that conflicts with the environment variable configuration.

**Status:**

- ✅ Pub/Sub topic and subscription created
- ✅ IAM permissions configured (project and subscription level)
- ✅ Messages successfully published (3 messages waiting)
- ✅ Worker service running with `min_instances = 1`
- ❌ Worker unable to pull messages (PermissionDenied errors)

---

## Infrastructure Completed

### 1. Pub/Sub Resources

- **Topic:** `curriculum-objectives-created`
- **Subscription:** `cie-objectives-subscription`
  - Mode: PULL
  - Ack Deadline: 600 seconds
  - Retry Backoff: 10s - 600s

### 2. IAM Permissions

- Service Account: `sa-cie-worker@octo-education-ddc76.iam.gserviceaccount.com`
- Project-level: `roles/pubsub.subscriber`
- Subscription-level: `roles/pubsub.subscriber` on `cie-objectives-subscription`

### 3. Cloud Run Configuration

- Service: `curriculum-intelligence-engine-worker`
- Min Instances: **1** (always running to poll subscription)
- Service Account: `sa-cie-worker@octo-education-ddc76.iam.gserviceaccount.com`
- Environment Variable: `PUBSUB_SUBSCRIPTION_ID=projects/octo-education-ddc76/subscriptions/cie-objectives-subscription`

---

## The Problem

### What We're Seeing

Worker logs show:

```
2025/12/15 21:07:20 📡 Listening on: cie-curriculum-updates
2025/12/15 21:07:20 🔄 Starting Pub/Sub subscription...
2025/12/15 21:07:20 ❌ Subscriber error: failed to receive messages: rpc error: code = PermissionDenied desc = User not authorized to perform this action.
2025/12/15 21:07:20 ⏳ Retrying in 10s...
```

### Root Cause

The worker is **hardcoded** to listen on subscription `cie-curriculum-updates`, but:

1. The `PUBSUB_SUBSCRIPTION_ID` environment variable is set to `projects/octo-education-ddc76/subscriptions/cie-objectives-subscription`
2. The worker code is **ignoring** this environment variable
3. IAM permissions are configured for `cie-objectives-subscription`, not `cie-curriculum-updates`

### Evidence

**Environment Variable (Correctly Set):**

```bash
$ gcloud run services describe curriculum-intelligence-engine-worker --format=json | \
  jq -r '.spec.template.spec.containers[0].env[] | select(.name=="PUBSUB_SUBSCRIPTION_ID") | .value'

projects/octo-education-ddc76/subscriptions/cie-objectives-subscription
```

**Worker Logs (Using Hardcoded Name):**

```
📡 Listening on: cie-curriculum-updates
```

**Mismatch:** Environment variable says `cie-objectives-subscription`, logs say `cie-curriculum-updates`.

---

## What We've Tried

### Workaround Attempt #1: Create Matching Subscription

We created a temporary subscription `cie-curriculum-updates` with proper IAM bindings, but the worker still receives PermissionDenied errors. This suggests the worker may have additional authentication issues beyond just the subscription name.

### Workaround Attempt #2: Added Project-Level IAM

Added `roles/pubsub.subscriber` at the project level in addition to subscription-level IAM, but PermissionDenied persists.

---

## Required Code Changes

The CIE Worker code needs to be updated to:

### 1. Read Environment Variable

```go
// Instead of hardcoded:
// subscriptionID := "cie-curriculum-updates"

// Read from environment:
subscriptionID := os.Getenv("PUBSUB_SUBSCRIPTION_ID")
if subscriptionID == "" {
    log.Fatal("PUBSUB_SUBSCRIPTION_ID environment variable not set")
}
```

### 2. Ensure Proper Authentication

Verify that the Pub/Sub client is using Application Default Credentials (ADC) from the Cloud Run metadata server:

```go
ctx := context.Background()
client, err := pubsub.NewClient(ctx, projectID)
if err != nil {
    log.Fatalf("Failed to create pubsub client: %v", err)
}
```

The client should automatically use the service account (`sa-cie-worker`) attached to the Cloud Run service.

### 3. Use Full Subscription Path

If the environment variable doesn't include the full path, construct it:

```go
subscriptionID := os.Getenv("PUBSUB_SUBSCRIPTION_ID")
if !strings.HasPrefix(subscriptionID, "projects/") {
    subscriptionID = fmt.Sprintf("projects/%s/subscriptions/%s", projectID, subscriptionID)
}
```

---

## Messages Waiting

**3 curriculum objective messages** are currently queued and waiting to be processed:

1. **Document:** `5f3108ba-79eb-469f-8d61-20ca98d1f133` (3 objectives) - Published: 2025-12-15T20:33:55Z
2. **Document:** `3c1dbbb7-f726-45c8-9ab7-21997a29f08e` (5 objectives) - Published: 2025-12-15T20:52:37Z
3. **Document:** `0f593c71-1aa0-4ee1-bed4-b0954c6578f7` (3 objectives) - Published: 2025-12-15T20:39:55Z

These messages will be automatically processed once the worker code is fixed and deployed.

---

## Next Steps

### For CIE Team:

1. ✅ **Update worker code** to read `PUBSUB_SUBSCRIPTION_ID` environment variable
2. ✅ **Verify authentication** using Application Default Credentials
3. ✅ **Test locally** with the correct subscription ID
4. ✅ **Deploy updated worker** to Cloud Run
5. ✅ **Verify** messages are processed successfully

### For Infrastructure Team (Us):

- ✅ Infrastructure is ready and waiting
- ⏸️ Standing by to assist with deployment
- ⏸️ Can provide additional debugging support if needed

---

## Testing the Fix

Once the code is updated, you can verify it works by:

1. **Check startup logs:**

   ```bash
   gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="curriculum-intelligence-engine-worker"' \
     --project=octo-education-ddc76 --limit=10 --format="table(timestamp,textPayload)"
   ```

2. **Verify message processing:**

   ```bash
   gcloud pubsub subscriptions pull cie-objectives-subscription --limit=5 --project=octo-education-ddc76
   ```

   (Should show 0 messages after worker processes them)

3. **Check for successful processing logs:**
   Look for logs indicating objectives were saved to Firestore.

---

## Additional Resources

- **Subscription Name:** `cie-objectives-subscription`
- **Topic Name:** `curriculum-objectives-created`
- **Service Account:** `sa-cie-worker@octo-education-ddc76.iam.gserviceaccount.com`
- **Cloud Run Service:** `curriculum-intelligence-engine-worker`
- **Region:** `us-central1`

---

## Questions?

Feel free to reach out if you need:

- Access to test the subscription manually
- Help with local development/testing
- Additional IAM permissions
- Deployment support

We're ready to help get this working as soon as possible!

---

**Infrastructure Team**  
Octo Education Platform
