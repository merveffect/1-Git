#!/bin/bash
# ============================================================
# Creates a GCE VM for DataMonitor
# Run this from your local machine (needs gcloud installed)
# ============================================================

# ---------- EDIT THESE ----------
PROJECT="dat-analytics-eng-ec869189"   # your GCP project
REGION="us-central1"
ZONE="us-central1-a"
VM_NAME="datamonitor"
MACHINE_TYPE="e2-small"               # ~$13/month. Use e2-micro for free tier.
# ---------------------------------

echo "==> Creating VM $VM_NAME in $PROJECT..."
gcloud compute instances create $VM_NAME \
  --project=$PROJECT \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --tags=http-server \
  --scopes=https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/cloud-platform

echo "==> Creating firewall rule to allow HTTP traffic..."
gcloud compute firewall-rules create allow-http-datamonitor \
  --project=$PROJECT \
  --allow=tcp:80 \
  --target-tags=http-server \
  --description="Allow HTTP for DataMonitor" 2>/dev/null || echo "  (firewall rule already exists, skipping)"

echo ""
echo "==> VM created. Next steps:"
echo ""
echo "  1. SSH into the VM:"
echo "     gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT"
echo ""
echo "  2. Inside the VM, run the setup script:"
echo "     curl -fsSL https://raw.githubusercontent.com/merveffect/1-Git/main/deploy/setup.sh | sudo bash"
echo ""
echo "  3. Get the external IP:"
EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --project=$PROJECT --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "     http://$EXTERNAL_IP"
echo ""
echo "  4. Share that URL with your team!"
echo ""
echo "Note: The VM's service account has BigQuery access via --scopes above."
echo "      No service account key file needed."
