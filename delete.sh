#!/bin/bash
set -euo pipefail

echo "Deleting all files in the current directory..."
kubectl delete namespace argocd || true