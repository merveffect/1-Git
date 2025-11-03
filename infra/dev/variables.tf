variable project_id {
  default = "dat-analytics-eng-ec869189"
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
      "roles/storage.objectAdmin",
      "roles/storage.admin",
      "roles/drive.readonly",
      "roles/bigquery.connectionUser",
      "roles/drive.file",
      "roles/bigquery.jobUser"
    ]
    runner = [
      "roles/bigquery.admin",
      "roles/iam.serviceAccountAdmin",
            "roles/artifactregistry.admin",
      "roles/cloudbuild.builds.builder",
      "roles/run.admin",
      "roles/cloudscheduler.admin",
      "roles/iam.serviceAccountUser",
      "roles/iam.serviceAccountAdmin",
      "roles/serviceusage.serviceUsageConsumer",
      "roles/iam.securityAdmin",
      "roles/bigquery.admin",
      "roles/storage.objectAdmin",
      "roles/storage.admin",
      "roles/drive.readonly",
      "roles/bigquery.connectionUser",
      "roles/drive.file",
      "roles/bigquery.jobUser"

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
      account_id   = "dev-analytics-dbt-deployer"
      display_name = "Analytics DBT Deployer"
      description  = "Service account used to deploy infrastructure"
    },
    runner = {
      account_id   = "dev-analytics-dbt-runner"
      display_name = "Analytics DBT Runner"
      description  = "Service account used to run jobs"
    }
  }
}

