variable "project_id" {
  description = "GCP/Firebase project id (globally unique). e.g. mle-pickup-dev."
  type        = string
}

variable "project_name" {
  description = "Human-readable project display name."
  type        = string
  default     = "MLE"
}

variable "billing_account" {
  description = <<-EOT
    Billing account id to attach (format: XXXXXX-XXXXXX-XXXXXX).
    Required for `apply` (Firestore/Functions need billing). Leave empty to
    `plan` the config without a billing account attached.
  EOT
  type        = string
  default     = ""
}

variable "org_id" {
  description = "GCP organization id, if the project lives under an org. Empty for a standalone project."
  type        = string
  default     = ""
}

variable "region" {
  description = "Default region for regional resources (Functions, etc.)."
  type        = string
  default     = "europe-west1"
}

variable "firestore_location" {
  description = "Firestore location. Multi-region (eur3/nam5) or a region. Immutable once set."
  type        = string
  default     = "eur3"
}

variable "environment" {
  description = "Environment label (dev|prod). Used in labels/naming."
  type        = string
  default     = "dev"
}

variable "budget_amount_eur" {
  description = "Monthly budget threshold in EUR for the billing alert."
  type        = number
  default     = 5
}

variable "budget_alert_emails" {
  description = "Emails to notify when budget thresholds are crossed."
  type        = list(string)
  default     = []
}
