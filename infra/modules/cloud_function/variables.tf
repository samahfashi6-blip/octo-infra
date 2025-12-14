variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "name" {
  description = "Name of the Cloud Function"
  type        = string
}

variable "runtime" {
  description = "Runtime for the function (e.g., go121, python311)"
  type        = string
}

variable "entry_point" {
  description = "Entry point function name"
  type        = string
}

variable "source_bucket" {
  description = "GCS bucket containing the source code"
  type        = string
}

variable "source_object" {
  description = "GCS object path to the source code archive"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the function"
  type        = string
}

variable "memory" {
  description = "Memory allocation for the function"
  type        = string
  default     = "256Mi"
}

variable "timeout_seconds" {
  description = "Timeout in seconds"
  type        = number
  default     = 60
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "trigger_config" {
  description = "Event trigger configuration (null for HTTP trigger)"
  type = object({
    event_type   = string
    bucket       = string
    retry_policy = string
  })
  default = null
}
