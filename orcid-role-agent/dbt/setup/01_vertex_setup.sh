#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Vertex AI <-> BigQuery baglantisi. BIR KEZ calistirilir.
# Bu adim icin proje uzerinde yetki gerekir - altyapi ekibiyle yapilir.
# ---------------------------------------------------------------------------
set -euo pipefail

PROJECT="researcher-360-prod-e7fd74be"
LOCATION="EU"                 # profiles.yml ile AYNI olmali
CONNECTION="vertex_ai_conn"
DATASET="orcid_role_agent"

echo "==> API'ler aciliyor"
gcloud services enable aiplatform.googleapis.com \
                       bigqueryconnection.googleapis.com \
                       --project="${PROJECT}"

echo "==> Dataset"
bq --location="${LOCATION}" mk --dataset --force "${PROJECT}:${DATASET}"

echo "==> BigQuery -> Vertex baglantisi"
bq mk --connection \
      --location="${LOCATION}" \
      --project_id="${PROJECT}" \
      --connection_type=CLOUD_RESOURCE \
      "${CONNECTION}" || echo "    (zaten var)"

SA=$(bq show --format=json --connection \
       "${PROJECT}.${LOCATION}.${CONNECTION}" \
     | python3 -c 'import json,sys; print(json.load(sys.stdin)["cloudResource"]["serviceAccountId"])')

echo "==> Baglanti service account: ${SA}"
gcloud projects add-iam-policy-binding "${PROJECT}" \
  --member="serviceAccount:${SA}" \
  --role="roles/aiplatform.user" \
  --condition=None

echo
echo "TAMAM. Simdi setup/02_create_models.sql dosyasini BigQuery'de calistir."
echo "NOT: IAM yayilmasi 1-2 dakika surebilir."
