#!/bin/bash

echo "Setting up the environment..."

# Create the namespace if it doesn't already exist
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd

# Navigate to the 'argocd' directory, run Skaffold, and return to the original directory
cd argocd || exit
skaffold run
cd ..

# echo "Port-forwarding Argo CD server to localhost:8080..."
# kubectl port-forward svc/argocd-server -n argocd 8080:443