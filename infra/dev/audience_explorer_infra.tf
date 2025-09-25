terraform {
  # Pre-create this
  backend "gcs" {
    bucket = "dbt-analytics-engineering-tf-backend"
    prefix = "dev-tf-state"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.39.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}

resource "time_static" "trigger" {}

locals {
  project_id = var.project_id
  env        = "dev"
  default_labels = {
    "terraform" : true
    "env" : local.env
    "domain" : "analytics_engineering"
  }
}

provider "google" {
  project = local.project_id
  region  = "EU"
  zone    = "EU"
  default_labels = {
    "updated-on" : formatdate("YYYYMMDD-HHmmss", time_static.trigger.rfc3339)
  }
}

# Create service accounts for runner and deployer
# NOTE: This part should be run manually from local, as halfpipe depends on it
module "analytics_sa_dev" {
  source                = "../modules/service_account"
  service_account_roles = var.service_account_roles
  project_id            = local.project_id
  service_accounts      = var.service_accounts
}


module "analytics_engineering_dbt_artifact_registry" {
  source = "../modules/artifact-registry"
  bq_location            = "europe-west1"
  repository_description = "AE DBT docker repository"
  repository_format      = "DOCKER"
  repository_id          = "sn-dbt-deploy"
}

module "google_cloud_storage_for_analytics_dbt_dev" {
  source = "../modules/google_storage_bucket"
  default_labels = local.default_labels
  location                    = "EU"
  name                        = "${local.project_id}-sn-dbt_cloudbuild"
  uniform_bucket_level_access = true

  depends_on = [module.analytics_sa_dev]
}
