# Argo CD Local Setup

This repo bootstraps Argo CD into the local Kind cluster created by:

```text
/Users/bikramjitsingh/Desktop/Projects/Kubernetes-cluster-development
```

Use this repo for Argo CD itself and for Argo CD `ApplicationSet` definitions. Use `Kubernetes-cluster-development` for the local cluster platform setup.

## Repo Responsibilities

### Kubernetes-cluster-development

This is the local cluster/platform repo. Its `start.sh` creates and configures the cluster:

```text
Kind cluster
Calico
MetalLB
cert-manager
Traefik
Polaris
```

Those are platform/bootstrap components and should generally stay outside Argo CD for this local setup.

### Argo-CD-local-setup

This repo installs Argo CD into the already-running local cluster:

```text
argocd namespace
Argo CD install manifests
self-signed ClusterIssuer
Argo CD Ingress through Traefik
ApplicationSet for app workloads
```

Argo CD then manages app workloads declared in `argocd/applicationset.yaml`.

## Current Argo-Managed Apps

The current `ApplicationSet` is `kind-app-workloads`.

It generates these Argo CD Applications:

```text
oauth
pg-vector
```

Sources:

```text
oauth
  repo: https://github.com/bikramjitchawla/Kubernetes-cluster-development.git
  path: Oauth
  files: installation.yaml, ingress.yaml
  namespace: oauth

pg-vector
  repo: https://github.com/bikramjitchawla/pg-vector.git
  path: .
  files: 01-cnpg-operator.yaml, cnpg-operator.yaml, pgvector-cluster.yaml, pgvector-nodeport.yaml
  namespace: vector-db
```

Argo CD reads GitHub, not local folders. Push changes to the GitHub repos before expecting Argo CD to sync them.

## Install Flow

Start the local platform cluster first:

```bash
cd /Users/bikramjitsingh/Desktop/Projects/Kubernetes-cluster-development
./start.sh
```

Then install Argo CD:

```bash
cd /Users/bikramjitsingh/Desktop/Projects/Argo-CD-local-setup
./start.sh
```

## Access Argo CD

Open:

```text
https://argocd.127.0.0.1.nip.io
```

The browser certificate warning is expected because this uses a self-signed certificate.

Username:

```text
admin
```

Get the admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## Useful Commands

Check Argo CD:

```bash
kubectl -n argocd get pods
kubectl -n argocd get ingress argocd-server
kubectl -n argocd get applications,applicationsets
```

Apply only the ApplicationSet changes:

```bash
kubectl apply -f argocd/polaris-exempt-namespaces.yaml
kubectl apply -f argocd/applicationset.yaml
```

Check generated workloads:

```bash
kubectl -n oauth get pods
kubectl -n vector-db get pods
kubectl -n cnpg-system get pods
```

## Local Domains

This setup uses `nip.io` so names resolve automatically to localhost:

```text
argocd.127.0.0.1.nip.io -> 127.0.0.1
```

That works with the Kind cluster because `Kubernetes-cluster-development/Kind/cluster.yaml` maps host port `443` to Traefik.

For a custom local domain, add it to `/etc/hosts`, then update the Ingress host and TLS host:

```text
127.0.0.1 argocd.local.test
```

## Ownership Model

Avoid double-managing the same resources from both local Skaffold and Argo CD.

Recommended local split:

```text
Local platform repo manages:
  kind, calico, metallb, cert-manager, traefik, polaris

Argo CD manages:
  oauth, pg-vector, future app workloads
```

This keeps cluster bootstrap separate from GitOps app delivery.
