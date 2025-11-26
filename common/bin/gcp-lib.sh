#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

export_google_application_credentials() {

  GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-}
  if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then

    GCP_SERVICE_ACCOUNT_INFO=${GCP_SERVICE_ACCOUNT_INFO:-}
    if [[ -z "$GCP_SERVICE_ACCOUNT_INFO" ]]; then

      GIT_REVISION=${GIT_REVISION:-}
      if [[ -n "$GIT_REVISION" ]]; then
          echo "We appear to be on CI and without an explict service account, exiting"
          exit 1
      else
        echo "Didn't find GOOGLE_APPLICATION_CREDENTIALS or GCP_SERVICE_ACCOUNT_INFO, doing nothing."
      fi
    else
      export GOOGLE_APPLICATION_CREDENTIALS="/tmp/gcp.json"
      echo "Didn't find GOOGLE_APPLICATION_CREDENTIALS. Writing value of GCP_SERVICE_ACCOUNT_INFO into /tmp/gcp.json and pointing GOOGLE_APPLICATION_CREDENTIALS to /tmp/gcp.json"
      echo "$GCP_SERVICE_ACCOUNT_INFO" > "$GOOGLE_APPLICATION_CREDENTIALS"
    fi
  fi
}

friendly_project_name(){
  local project_id=$1

  gcloud projects describe $project_id  --format="value(name)"
}

gcloud_authenticate_with_file(){
  local file=$1
  gcloud auth activate-service-account --key-file="$file"

  echo "running 'gcloud --version':"
  gcloud --version
}

gcloud_authenticate_with_google_application_credentials(){
  GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-}
  if [[ "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    gcloud_authenticate_with_file $GOOGLE_APPLICATION_CREDENTIALS
  else
    echo "Could not authenticate with gcloud as \$GOOGLE_APPLICATION_CREDENTIALS was not set"
  fi
}
