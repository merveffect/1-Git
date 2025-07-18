output "tf_sa_runner_email" {
  value = google_service_account.terraform_sa["runner"].email
}

output "tf_sa_deployer_email" {
  value = google_service_account.terraform_sa["deployer"].email
}