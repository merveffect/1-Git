resource "google_storage_bucket" "storage-bucket" {
  location                    = var.location
  name                        = var.name
  uniform_bucket_level_access = var.uniform_bucket_level_access
  labels                      = var.default_labels
  enable_object_retention     = var.enable_object_retention

  versioning {
    enabled = var.versioning_enabled
  }
}