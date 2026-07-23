output "project_id" {
  description = "The provisioned GCP/Firebase project id."
  value       = google_project.mle.project_id
}

output "project_number" {
  description = "The numeric project id (used by some GCP APIs)."
  value       = google_project.mle.number
}

output "firestore_database" {
  description = "Firestore database name and location."
  value = {
    name     = google_firestore_database.default.name
    location = google_firestore_database.default.location_id
  }
}

output "enabled_apis" {
  description = "APIs enabled on the project."
  value       = sort([for s in google_project_service.apis : s.service])
}
