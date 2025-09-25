!/usr/bin/env bash
set -euo pipefail

function setup_gcloud_credentials() {
  local BASE_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
  cd "$BASE_DIR"

  local COMMON_BIN="$(cd "$BASE_DIR/../common/bin" && pwd)"
  if ! source "$COMMON_BIN/gcp-lib.sh"; then echo -e "Cannot find $COMMON_BIN/gcp-lib.sh; exiting..."; exit 1; fi

  export_google_application_credentials

  gcloud_authenticate_with_google_application_credentials
}

function apply_terraform() {
  local env_dir=$1
  cd "$env_dir"

  terraform version
  terraform init
  terraform apply -auto-approve
}

function main() {
  local env_dir=$1

  setup_gcloud_credentials
  apply_terraform "$env_dir"
}


main "${1:-$TF_ENV_DIR}"