Subject: Request for Terraform Enrollment: Curriculum Ingestion Service (pdf-curriculum-extractor)

Hi Terraform Team,

We are the team responsible for the **Curriculum Ingestion Service** (specifically the `pdf-curriculum-extractor` Cloud Function). We understand that the organization is migrating to a new Terraform-based cloud architecture, and we would like to enroll our service in this new system.

Below are the technical details and requirements for our service to assist with the migration:

### Service Overview

- **Service Name:** `pdf-curriculum-extractor`
- **Description:** A Go-based Cloud Function that processes educational PDF content. It triggers on file uploads, extracts text using Document AI and Gemini, and stores structured data in Firestore.

### Infrastructure Requirements

**1. Compute (Cloud Function Gen 2)**

- **Runtime:** Go 1.25 (or latest supported)
- **Entry Point:** `ProcessPDFUpload`
- **Region:** `us-central1` (Current deployment)
- **Memory:** 2Gi
- **Timeout:** 540s
- **Max Instances:** 10

**2. Triggers**

- **Event Type:** `google.cloud.storage.object.v1.finalized`
- **Source Bucket:** `octo-education-curriculum-morocco` (We need this bucket managed or imported)

**3. IAM & Permissions**

- **Service Account:** Needs permissions for:
  - Storage Object Viewer (for the input bucket)
  - Firestore User (read/write access)
  - Document AI User (to invoke processors)
  - Vertex AI User (for Gemini API access)

**4. Environment Variables**
We require the following configuration to be injected:

- `PROJECT_ID`: [Target Project ID]
- `DOCUMENT_AI_LOCATION`: `us`
- `DOCUMENT_AI_PROCESSOR_ID`: [ID of the Document AI Processor]
- `GEMINI_LOCATION`: `global`
- `GEMINI_MODEL_ID`: `gemini-3-pro-preview`
- `CURRICULUM_SERVICE_URL`: [URL of the downstream Curriculum Service]

**5. External Dependencies**

- **Document AI:** Requires a specific processor to be provisioned/available.
- **Firestore:** Requires a Firestore database instance in Native mode.

Please let us know the next steps for onboarding our service to the Terraform repository. We are happy to provide our current deployment scripts (`deploy-function.sh`) or Dockerfiles if needed for reference.

Best regards,

Curriculum Ingestion Team
