# Pub/Sub Integration Requirements for Terraform Team

## Overview

The Curriculum Ingestion Service needs to publish events after processing PDFs so the CIE (Curriculum Intelligence Engine) service can generate embeddings.

## Required Infrastructure

### 1. Pub/Sub Topic

**Topic Name**: `curriculum-objectives-created`  
**Purpose**: Notify CIE service when new learning objectives are saved to Firestore

**Configuration**:

```hcl
resource "google_pubsub_topic" "curriculum_objectives" {
  name    = "curriculum-objectives-created"
  project = "octo-education-ddc76"

  labels = {
    service     = "curriculum-ingestion"
    environment = "production"
  }
}
```

### 2. IAM Permissions

The `sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com` service account needs:

```hcl
resource "google_pubsub_topic_iam_member" "publisher" {
  project = "octo-education-ddc76"
  topic   = google_pubsub_topic.curriculum_objectives.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:sa-curriculum-ingestion@octo-education-ddc76.iam.gserviceaccount.com"
}
```

### 3. Cloud Function Environment Variable

Add this to the Cloud Function configuration:

```hcl
resource "google_cloudfunctions2_function" "curriculum_ingestion" {
  # ... existing configuration ...

  service_config {
    environment_variables = {
      # ... existing variables ...
      PUBSUB_TOPIC_ID = google_pubsub_topic.curriculum_objectives.id
    }
  }
}
```

## Event Schema

### Message Format

When objectives are successfully saved, the service will publish messages with this structure:

**Attributes**:

```json
{
  "eventType": "objectives.created",
  "documentId": "MAR_MATH_G07_LESSON_001",
  "objectiveCount": "6",
  "timestamp": "2025-12-15T10:30:00Z"
}
```

**Data (JSON payload)**:

```json
{
  "documentId": "MAR_MATH_G07_LESSON_001",
  "collection": "curriculum-staging",
  "objectiveIds": [
    "MAR_MATH_G07_OBJ_001",
    "MAR_MATH_G07_OBJ_002",
    "MAR_MATH_G07_OBJ_003"
  ],
  "metadata": {
    "country": "MA",
    "subject": "MATH",
    "grade": "G7",
    "pdfUrl": "gs://octo-education-ddc76-curriculum-pdfs/morocco/math/grade7/lesson.pdf"
  },
  "processedAt": "2025-12-15T10:30:00Z"
}
```

## Integration Points

### CIE Service (Consumer)

The CIE service should create a subscription to this topic:

```hcl
resource "google_pubsub_subscription" "cie_objectives_subscription" {
  name    = "cie-objectives-subscription"
  topic   = google_pubsub_topic.curriculum_objectives.name
  project = "octo-education-ddc76"

  # Push subscription to CIE Cloud Function
  push_config {
    push_endpoint = "https://REGION-octo-education-ddc76.cloudfunctions.net/cie-generate-embeddings"

    oidc_token {
      service_account_email = "sa-cie-service@octo-education-ddc76.iam.gserviceaccount.com"
    }
  }

  ack_deadline_seconds = 600  # 10 minutes for embedding generation

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}
```

## Deployment Steps

1. **Terraform Team**: Apply infrastructure changes to create topic and permissions
2. **Curriculum Ingestion Team**: Deploy updated Cloud Function with Pub/Sub client code
3. **CIE Team**: Deploy subscription and update their service to consume events
4. **Testing**: Upload test PDF and verify event flow end-to-end

## Testing Checklist

- [ ] Topic created successfully
- [ ] Service account has publisher permission
- [ ] Cloud Function has `PUBSUB_TOPIC_ID` environment variable set
- [ ] Test PDF upload triggers event publishing
- [ ] CIE subscription receives messages
- [ ] Embeddings are generated in Firestore `embeddings` collection

## Rollback Plan

If issues occur:

1. Set `PUBSUB_TOPIC_ID=""` in Cloud Function (disables publishing)
2. System continues to work without embeddings (graceful degradation)
3. Debug and fix issues
4. Re-enable by setting environment variable

## Questions for Terraform Team

1. Should we use separate topics for staging/production environments?
2. Do you want DLQ (Dead Letter Queue) configuration for failed messages?
3. Should we enable message retention for debugging? (recommended: 7 days)
4. Do you need monitoring/alerting setup for this topic?

## Contact

- **Requestor**: Amjed (Curriculum Ingestion Team)
- **Date**: December 15, 2025
- **Priority**: High (blocks CIE service integration)
