# Enable Firebase on the GCP project. Uses google-beta (Firebase resources are
# beta-tier in the provider).
resource "google_firebase_project" "mle" {
  provider = google-beta
  project  = google_project.mle.project_id

  depends_on = [google_project_service.apis]
}

# Firestore database (Native mode). Location is immutable after creation.
resource "google_firestore_database" "default" {
  provider = google-beta
  project  = google_project.mle.project_id

  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"

  # Guard against accidental deletion of the database in non-dev environments.
  deletion_policy = var.environment == "prod" ? "DELETE_PROTECTION_ENABLED" : "DELETE"

  depends_on = [google_firebase_project.mle]
}

# NOTE: Firestore security rules and indexes are managed by the Firebase CLI
# (firestore.rules / firestore.indexes.json at the repo root, deployed via
# `firebase deploy`), not Terraform. Terraform owns the project and database;
# the Firebase CLI owns the app-level config. This split keeps rules iteration
# fast (no terraform apply per rule tweak) while infra stays declarative here.
