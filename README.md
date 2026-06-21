# Argo CD Local Setup

This repo is the GitOps layer for the local Kind platform created by:

```text
https://github.com/bikramjitchawla/Kubernetes-cluster-development.git
```

Use `Kubernetes-cluster-development` to create the shared local cluster and platform add-ons. Use this repo to install Argo CD into that cluster and define what Argo CD should manage.

## End-to-End Flow

```text
Kubernetes-cluster-development
  -> creates the shared Kind cluster
  -> installs platform services like Calico, MetalLB, cert-manager, Traefik, Polaris

Argo-CD-local-setup
  -> installs Argo CD into that cluster
  -> exposes Argo CD through Traefik
  -> applies ApplicationSets

Argo CD
  -> syncs app workloads and tenant namespace configuration from Git
```

## Repo Responsibilities

### Kubernetes-cluster-development

This is the local cluster/platform repo:

```text
https://github.com/bikramjitchawla/Kubernetes-cluster-development.git
```

Its `start.sh` creates and configures the cluster:

```text
Kind cluster
Calico
MetalLB
cert-manager
Traefik
Polaris
```

Those are platform/bootstrap components and should generally stay outside Argo CD for this local setup.

This repo assumes that cluster already exists before `./start.sh` is run here.

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

It also contains the namespace-based tenant model used in the shared cluster:

```text
platform/tenants/*
apps/tenants/*
```

## Current Argo-Managed Apps

The current app workload `ApplicationSet` is `kind-app-workloads`.

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

Tenant ownership is split into two ApplicationSets.

The platform-side tenant ApplicationSet is `kind-tenant-platform`.

It generates one Argo CD Application per tenant boundary:

```text
tenant-a-platform
tenant-b-platform
```

Sources:

```text
tenant-a-platform
  repo: https://github.com/bikramjitchawla/Argo-CD-local-setup.git
  path: platform/tenants/tenant-a
  namespace: tenant-a

tenant-b-platform
  repo: https://github.com/bikramjitchawla/Argo-CD-local-setup.git
  path: platform/tenants/tenant-b
  namespace: tenant-b
```

The app-side tenant ApplicationSet is `kind-tenant-workloads`.

It generates one Argo CD Application per tenant workload:

```text
tenant-a-workloads
tenant-b-workloads
```

Sources:

```text
tenant-a-workloads
  repo: https://github.com/bikramjitchawla/Argo-CD-local-setup.git
  path: apps/tenants/tenant-a
  namespace: tenant-a
  url: https://app.tenant-a.127.0.0.1.nip.io

tenant-b-workloads
  repo: https://github.com/bikramjitchawla/Argo-CD-local-setup.git
  path: apps/tenants/tenant-b
  namespace: tenant-b
  url: https://app.tenant-b.127.0.0.1.nip.io
```

Argo CD reads GitHub, not local folders. Push changes to the GitHub repos before expecting Argo CD to sync them.

For example, changing `apps/tenants/tenant-a/app.yaml` locally does nothing until the change is pushed to:

```text
https://github.com/bikramjitchawla/Argo-CD-local-setup.git
```

## Install Flow

Start the local platform cluster first:

```bash
git clone https://github.com/bikramjitchawla/Kubernetes-cluster-development.git
cd Kubernetes-cluster-development
./start.sh
```

Then install Argo CD:

```bash
git clone https://github.com/bikramjitchawla/Argo-CD-local-setup.git
cd Argo-CD-local-setup
./start.sh
```

The Argo CD script prints the UI URL, username, and initial admin password after the server is ready.

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
kubectl -n tenant-a get pods,ingress
kubectl -n tenant-b get pods,ingress
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
  oauth, pg-vector, tenant platform boundaries, tenant workloads, future app workloads
```

This keeps cluster bootstrap separate from GitOps app delivery.

In practical terms:

```text
Do not add Calico, MetalLB, cert-manager, Traefik, or Polaris to this repo's ApplicationSets.
Do add tenant boundaries, tenant apps, and other app workloads to this repo's ApplicationSets.
```

## Tenant Model

This repo demonstrates namespace-based tenancy in one shared local Kind cluster.

Each platform-side tenant Application gets:

```text
Namespace
ResourceQuota
LimitRange
Role
RoleBinding
NetworkPolicy
```

Each app-side tenant Application gets:

```text
Deployment
Service
Ingress
```

The `kind-tenant-platform` ApplicationSet represents platform-team ownership. The `kind-tenant-workloads` ApplicationSet represents app-team ownership. This is the same pattern that can later be extended to multiple clusters after registering those clusters in Argo CD.
