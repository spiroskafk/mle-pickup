# The GCP project itself. A Firebase project is a GCP project with Firebase
# services enabled on top (see firebase.tf).
resource "google_project" "mle" {
  name       = var.project_name
  project_id = var.project_id

  # billing_account is optional so the config can be `plan`ned without one.
  # It must be set (via tfvars) before `apply` — Firestore/Functions require it.
  billing_account = var.billing_account != "" ? var.billing_account : null
  org_id          = var.org_id != "" ? var.org_id : null

  labels = {
    app         = "mle"
    environment = var.environment
    managed_by  = "terraform"
  }

  # Firebase requires this so the project can be reused/deleted cleanly.
  deletion_policy = "DELETE"
}

# APIs the app depends on. Enabling is idempotent; disabling on destroy is off
# so tearing down infra doesn't thrash shared Google APIs.
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "firebase.googleapis.com",
    "firestore.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com", # Cloud Functions v2 run on Cloud Run
    "eventarc.googleapis.com",
    "identitytoolkit.googleapis.com", # Firebase Auth
    "fcm.googleapis.com",             # Cloud Messaging
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
  ])

  project = google_project.mle.project_id
  service = each.value

  disable_on_destroy = false
}
