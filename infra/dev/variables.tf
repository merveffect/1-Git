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

variable "teams_webhook_url" {
  description = "Teams webhook url for concourse pipeline alerts"
  type        = string
  default     = "https://prod-84.westeurope.logic.azure.com:443/workflows/3874c734e9ca46ca9e8339ae9df2af0c/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=NTbSPvDToEw6h9apdS98K0j446FQCxesU0hu76_AFK8"
}
