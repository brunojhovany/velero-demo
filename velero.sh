#!/bin/bash
BUCKET=velerobruno-$(openssl rand -hex 6)
REGION=us-east-2

# create bucket 
aws s3api create-bucket --bucket $BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

cat > /tmp/credentials-velero <<EOF
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
EOF
#aws_session_token=$AWS_SESSION_TOKEN

kubectl patch -n velero secret cloud-credentials -p '{"data": {"cloud": "'$(base64 -w 0 /tmp/credentials-velero)'"}}'

# Velero 1.10 version
# velero install \
#     --provider aws \
#     --plugins velero/velero-plugin-for-aws \
#     --bucket $BUCKET \
#     --backup-location-config region=$REGION \
#     --snapshot-location-config region=$REGION \
#     --secret-file /tmp/credentials-velero \
#     --default-volumes-to-fs-backup \
#     --use-node-agent

# velero 1.7 version
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.3.0 \
    --bucket $BUCKET \
    --backup-location-config region=$REGION \
    --use-volume-snapshots=false \
    --use-restic \
    --secret-file /tmp/credentials-velero \
    --default-volumes-to-restic
    # --no-secret
    # --pod-annotations iam.amazonaws.com/role=arn:aws:iam::729111267627:role/webfocus-eks \

kubectl -n velero get pods
kubectl logs deployment/velero -n velero


 # velero backup create nginx-proxy --include-namespaces nginx-proxy --wait