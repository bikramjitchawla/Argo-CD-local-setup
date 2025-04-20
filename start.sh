#!/bin/bash
set -euo pipefail 
# 1. Traefik IngressRoute is used to expose ArgoCD at http://argocd.localhost (no port-forwarding needed)
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

# echo "Port-forwarding Argo CD server to localhost:8080..."
# kubectl port-forward svc/argocd-server -n argocd 8080:443
