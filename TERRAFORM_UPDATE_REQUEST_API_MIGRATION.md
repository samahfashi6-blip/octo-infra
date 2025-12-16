# Terraform Update Request: API Migration

**Date:** December 16, 2025
**Priority:** High
**Status:** Pending Infrastructure Update

We have completed the code refactoring for the `curriculum-ingestion` service to migrate from Pub/Sub to direct API calls. Please apply the following changes to the Terraform configuration to support the new architecture.

## 1. Cloud Function Configuration (`curriculum-ingestion`)

Please update the environment variables for the Cloud Function:

- **ADD**: `CIE_API_URL`
  - Value: The URL of the `curriculum-intelligence-engine-api` Cloud Run service.
- **REMOVE**: `PUBSUB_TOPIC_ID`
  - Reason: The service no longer publishes to Pub/Sub.

## 2. IAM Permissions

The service account for `curriculum-ingestion` needs updated permissions:

- **ADD**: `roles/run.invoker`
  - Target: `curriculum-intelligence-engine-api` (Cloud Run Service)
  - Reason: To allow the function to make authenticated HTTP requests to the CIE API.
- **REMOVE**: `roles/pubsub.publisher`
  - Target: `curriculum-objectives-created` (Pub/Sub Topic)
  - Reason: Publishing capability is no longer required.

## 3. Resource Cleanup (Post-Verification)

Once the migration is verified in production, the following resources can be deprecated and removed:

- Pub/Sub Topic: `curriculum-objectives-created`
- Pub/Sub Subscription: `cie-objectives-subscription`
- Cloud Run Service: `curriculum-intelligence-engine-worker` (The worker that consumed the Pub/Sub messages)

## Reference

These changes align with the approved `API_MIGRATION_PLAN.md`.
