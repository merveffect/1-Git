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

#locals block: Purpose: keep repeated values in one place → makes code easier to read, maintain, and update
#These values can be referenced anywhere in the code using local.<name>.

locals { 
  ae_project_id = "	dat-analytics-eng-ec869189" # defines a local variable called ae_project_id
  env        = "dev"  #Commonly used for naming resources ("bucket-${local.env}") or labeling them.
  default_labels = {
    "terraform" : true
    "env" : local.env
    "domain" : "analytics_engineering" # label
  }
}


#This provider block configures the Google Cloud provider for Terraform.
#A provider tells Terraform which cloud platform or service it should talk to (in this case, Google Cloud Platform – GCP).

provider "google" {
  project = local.ae_project_id #Tells Terraform which GCP project it should use.
  alias = "audience_explorer_google_provider" #just names this provider configuration so you can call it explicitly in your resources.
  region  = "EU"
  zone    = "EU"
  default_labels = {
    "updated-on" = formatdate("YYYYMMDD-HHmmss", time_static.trigger.rfc3339)
  }
}


provider "google" {
  project = local.ae_project_id #Tells Terraform which GCP project it should use.
  alias = "braze_email_reporting_google_provider" #just names this provider configuration so you can call it explicitly in your resources.
  region  = "EU"
  zone    = "EU"
  default_labels = {
    "updated-on" = formatdate("YYYYMMDD-HHmmss", time_static.trigger.rfc3339)
  }
}


# Create service accounts for runner and deployer
# NOTE: This part should be run manually from local, as halfpipe depends on it
module "braze_email_reporting_sa_dev" {
  source                = "../modules/service_account"
  service_account_roles = var.service_account_roles
  project_id            = local.project_id
  service_accounts      = var.service_accounts
}


module "braze_email_reporting_artifact_registry" {
  source = "../modules/artifact-registry"
  bq_location            = "europe-west1"
  repository_description = "AE DBT docker repository"
  repository_format      = "DOCKER"
  repository_id          = "sn-dbt-deploy"
}

module "google_cloud_storage_for_braze_email_reporting_dbt_dev" {
  source = "../modules/google_storage_bucket"
  default_labels = local.default_labels
  location                    = "EU"
  name                        = "${local.project_id}-sn-dbt_cloudbuild"
  uniform_bucket_level_access = true

  depends_on = [module.braze_email_reporting_sa_dev]
}
