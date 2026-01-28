#!/bin/bash
set -euo pipefail 
# 1. Traefik Ingress is used to expose ArgoCD at https://argocd.127.0.0.1.nip.io (via localhost-mapped Traefik)
# 2. ArgoCD server runs with --insecure flag to disable HTTPS redirect
#
# WARNING:
# This setup exposes ArgoCD over plain HTTP without authentication.
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
# echo "Port-forwarding Argo CD server to localhost:8080..."
# kubectl port-forward svc/argocd-server -n argocd 8080:443
