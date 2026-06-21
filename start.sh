#!/bin/bash
set -euo pipefail 
# 1. Traefik terminates HTTPS and exposes Argo CD at:
#    https://argocd.127.0.0.1.nip.io
# 2. Argo CD server runs with server.insecure=true so Traefik can forward
#    plain HTTP to the in-cluster argocd-server service.
#
# WARNING:
# This uses a self-signed certificate and is intended only for local clusters.
# Do not use this configuration in production environments.

echo "Setting up the environment..."

# Create the namespace if it doesn't already exist
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd

# Navigate to the 'argocd' directory, run Skaffold, and return to the original directory
cd argocd || exit
skaffold run
cd ..

# argo cd by default ha ingress secure true so if we want to access on http then we need to apply it manually and restart deployment
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge -p '{"data":{"server.insecure":"true"}}'

kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd --timeout=180s

kubectl apply -f argocd/applicationset.yaml

echo "Argo CD should be available at: https://argocd.127.0.0.1.nip.io"
echo "Username: admin"

if kubectl get secret argocd-initial-admin-secret -n argocd >/dev/null 2>&1; then
  password="$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
  echo "Password: ${password}"
else
  echo "Password: argocd-initial-admin-secret was not found. It may have been deleted after the admin password was changed."
fi

# echo "Port-forwarding Argo CD server to localhost:8080..."
# kubectl port-forward svc/argocd-server -n argocd 8080:443
