terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  # State is kept out of git. For a shared/production setup, switch this to a
  # GCS backend (uncomment and set the bucket). Left local by default so the
  # project can be `plan`ned with no cloud resources at all.
  #
  # backend "gcs" {
  #   bucket = "mle-tfstate"
  #   prefix = "infra"
  # }
}

# The default provider. project is set per-environment via tfvars.
provider "google" {
  project = var.project_id
  region  = var.region
}

# google-beta is required for some Firebase resources.
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
