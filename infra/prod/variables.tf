variable project_id {
  default = "snproject-cbb9ca25"
}

variable "region" {
  default = "europe-west3"
}


variable "service_account_roles" {
  description = "Roles per service account"
  type = map(list(string))
  default = {
    deployer = [
      "roles/artifactregistry.admin",
      "roles/cloudbuild.builds.builder",
      "roles/run.admin",
      "roles/cloudscheduler.admin",
      "roles/iam.serviceAccountUser",
      "roles/iam.serviceAccountAdmin",
      "roles/serviceusage.serviceUsageConsumer",
      "roles/iam.securityAdmin",
      "roles/bigquery.admin",
      "roles/storage.objectAdmin"
    ]
    runner = [
      "roles/bigquery.admin",
      "roles/iam.serviceAccountAdmin"
    ]
  }
}

variable "service_accounts" {
  type = map(object({
    account_id   = string
    display_name = string
    description  = string
  }))
  default = {
    deployer = {
      account_id   = "prod-analytics-dbt-deployer"
      display_name = "Analytics DBT Deployer"
      description  = "Service account used to deploy infrastructure"
    },
    runner = {
      account_id   = "prod-analytics-dbt-runner"
      display_name = "Analytics DBT Runner"
      description  = "Service account used to run jobs"
    }
  }
}