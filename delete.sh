#!/bin/bash
set -euo pipefail

echo "Deleting Argo CD managed bootstrap resources..."

if kubectl get crd applicationsets.argoproj.io >/dev/null 2>&1; then
  kubectl delete applicationset -n argocd --all --ignore-not-found || true
fi

if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
  kubectl delete application -n argocd --all --ignore-not-found || true
fi

kubectl delete namespace argocd --ignore-not-found
