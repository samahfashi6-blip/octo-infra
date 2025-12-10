# octo-infra

Production-grade Infrastructure-as-Code repository for managing Google Cloud Platform resources with Terraform.

## Project Structure

```
octo-infra/
├── infra/
│   ├── modules/              # Reusable Terraform modules
│   │   ├── cloud_run_service/
│   │   ├── service_account/
│   │   ├── pubsub_topic/
│   │   ├── pubsub_subscription/
│   │   └── bucket/
│   └── env/                  # Environment-specific configurations
│       └── main/
│           ├── provider.tf
│           ├── variables.tf
│           ├── main.tf
│           ├── outputs.tf
│           └── backend.tf
└── README.md
```

## Modules

### Cloud Run Service

Creates a fully configured Cloud Run service with:

- CPU and memory allocation
- Auto-scaling (min/max instances)
- Concurrency controls
- Environment variables
- Service account association
- IAM policies

### Service Account

Creates GCP service accounts with:

- Custom account ID and display name
- Project-level IAM role bindings
- Outputs for integration with other resources

### Pub/Sub Topic

Creates Pub/Sub topics for asynchronous messaging with:

- Message retention configuration
- Labels for organization

### Pub/Sub Subscription

Creates Pub/Sub subscriptions with support for:

- Pull or Push delivery
- OIDC token authentication for push endpoints
- Configurable acknowledgment deadlines
- Message retention settings

### Cloud Storage Bucket

Creates GCS buckets with:

- Versioning support
- Lifecycle management rules
- Storage class optimization
- Uniform bucket-level access

## Default Configuration

- **Project ID**: `octo-education-ddc76`
- **Region**: `us-central1`

## Getting Started

### Prerequisites

1. Install Terraform (>= 1.5)
2. Install and configure Google Cloud SDK
3. Authenticate with GCP:
   ```bash
   gcloud auth application-default login
   ```

### Initialize Terraform

Navigate to your environment directory and initialize:

```bash
cd infra/env/main
terraform init
```

### Plan and Apply

1. Review the planned changes:

   ```bash
   terraform plan
   ```

2. Apply the infrastructure:
   ```bash
   terraform apply
   ```

### Using Modules

To use a module, add a module block in `infra/env/main/main.tf`:

```hcl
module "example_service" {
  source = "../../modules/cloud_run_service"

  project_id    = var.project_id
  region        = var.region
  service_name  = "my-service"
  image         = "gcr.io/${var.project_id}/my-service:latest"
  # ... additional configuration
}
```

## State Management

For production use, configure remote state storage in `backend.tf`:

1. Create a GCS bucket for state:

   ```bash
   gcloud storage buckets create gs://octo-education-ddc76-terraform-state \
     --project=octo-education-ddc76 \
     --location=us-central1
   ```

2. Enable versioning:

   ```bash
   gcloud storage buckets update gs://octo-education-ddc76-terraform-state \
     --versioning
   ```

3. Uncomment the backend configuration in `backend.tf`

4. Migrate state:
   ```bash
   terraform init -migrate-state
   ```

## Best Practices

1. **Module Development**: Keep modules generic and reusable
2. **Variables**: Use sensible defaults, document all variables
3. **Outputs**: Export useful attributes for cross-module references
4. **State**: Always use remote state for team collaboration
5. **Security**: Never commit credentials or sensitive data
6. **Version Control**: Tag releases and use semantic versioning

## Next Steps

1. Fill in the module resource blocks with actual Terraform code
2. Define your infrastructure in `infra/env/main/main.tf`
3. Configure remote state backend
4. Set up CI/CD pipelines for automated deployments
5. Add additional environments (dev, staging) as needed

## Support

For questions or issues, refer to:

- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Documentation](https://cloud.google.com/docs)
