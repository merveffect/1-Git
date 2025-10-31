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






