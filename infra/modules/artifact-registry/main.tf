resource "google_artifact_registry_repository" "terraform-artifact-registry" {
  location      = var.bq_location
  repository_id = var.repository_id
  description   = var.repository_description
  format        = var.repository_format
}