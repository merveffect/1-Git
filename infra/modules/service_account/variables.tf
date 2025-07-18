variable "project_id" {}

variable "service_account_roles" {
  description = "Roles per service account"
  type = map(list(string))
}

variable "service_accounts" {
  type = map(object({
    account_id   = string
    display_name = string
    description  = string
  }))
}