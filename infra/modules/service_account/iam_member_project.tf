locals {
  service_accounts_map = {
    deployer = google_service_account.terraform_sa["deployer"].email,
    runner   = google_service_account.terraform_sa["runner"].email
  }

  role_bindings_map = {
    for pair in flatten([
      for sa_key, sa_email in local.service_accounts_map : [
        for role in var.service_account_roles[sa_key] : {
          role   = role
          member = "serviceAccount:${sa_email}"
          key    = "${sa_key}-${role}"
        }
      ]
    ]) : pair.key => {
      role   = pair.role
      member = pair.member
    }
  }
}


resource "google_project_iam_member" "terraform_sa_bindings" {
  for_each = local.role_bindings_map

  project = var.project_id
  role    = each.value.role
  member  = each.value.member
}