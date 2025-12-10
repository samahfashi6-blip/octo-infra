# ==============================================================================
# Terraform Backend Configuration
# ==============================================================================
# Configure where Terraform stores state files.
# For production use, store state in a GCS bucket for team collaboration.
#
# To use this backend:
# 1. Create a GCS bucket for state storage
# 2. Uncomment and configure the backend block below
# 3. Run: terraform init -migrate-state
# ==============================================================================

# terraform {
#   backend "gcs" {
#     bucket = "octo-education-ddc76-terraform-state"
#     prefix = "env/main"
#   }
# }

# For local development, you can use local backend (default):
# State will be stored in terraform.tfstate file in this directory
