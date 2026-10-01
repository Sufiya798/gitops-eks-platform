# GitOps EKS Platform

A self-contained example of a GitOps delivery pipeline: Terraform provisions
the infrastructure, GitHub Actions builds and tags images, ArgoCD continuously
syncs the cluster to what's declared in Git, and Prometheus/Grafana/Alertmanager
provide observability with Slack alerts.

See [docs/architecture.md](docs/architecture.md) for the full data flow and
the reasoning behind each design choice.

## Stack

| Layer           | Tool                                   |
|------------------|-----------------------------------------|
| Infra provisioning | Terraform (VPC, EKS, IAM)             |
| CI               | GitHub Actions (build, test, push, tag)  |
| CD / GitOps      | ArgoCD                                  |
| Orchestration    | Kubernetes (EKS)                        |
| Observability    | Prometheus, Grafana, Alertmanager       |
| Alerting         | Slack                                   |

## Repo layout

```
terraform/          Infra as code (VPC, IAM, EKS modules + root env)
app/                 Sample Flask app + Dockerfile
.github/workflows/   CI pipeline
k8s/                 Kustomize base + dev/prod overlays
argocd/              ArgoCD Application manifest + install guide
monitoring/          Prometheus/Grafana/Alertmanager Helm values + alert rules
docs/                Architecture notes
```

## Prerequisites

- AWS account (free tier works, but EKS control plane and NAT gateway are
  **not** free — see Cost notes below)
- AWS CLI, Terraform >= 1.6, kubectl, helm installed locally
- A Docker Hub account (or swap for ECR)
- `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` added as GitHub Actions secrets

## Setup, step by step

### 1. Provision infrastructure

```bash
cd terraform/environments
terraform init      # uses the S3 backend — create that bucket/table first,
                     # see the multi-env-terraform project's s3-backend module
terraform plan
terraform apply
```

### 2. Connect kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name gitops-eks-platform
kubectl get nodes
```

### 3. Install ArgoCD

Follow [argocd/install.md](argocd/install.md).

### 4. Point ArgoCD at this repo

Edit `argocd/application.yaml` — replace `YOUR_GITHUB_USERNAME` — then:

```bash
kubectl apply -f argocd/application.yaml
```

### 5. Install the monitoring stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/prometheus-values.yaml
kubectl apply -f monitoring/alert-rules.yaml
```

Put your real Slack webhook URL in a Kubernetes Secret rather than the values
file — don't commit secrets to Git.

### 6. Push a change and watch it flow

Edit `app/app.py`, push to `main`, and watch:
GitHub Actions build → image pushed → manifest commit → ArgoCD sync → new pods.

## Metrics to capture for your resume/README

Once this is running, record real numbers instead of placeholders:

- **Deploy frequency** — how often ArgoCD synced over a week
- **Rollback time** — `argocd app rollback <app-name>` and time it
- **Lead time** — commit timestamp to pod-ready timestamp

## Cost notes (read before deploying)

- EKS control plane: ~$0.10/hour (not covered by AWS free tier)
- NAT Gateway: hourly + per-GB charges
- `t3.medium` nodes: EC2 free tier covers `t2.micro`/`t3.micro` only

**Run `terraform destroy` after each demo session** to avoid ongoing charges.
Budget a few hours of runtime, not days.

## What I'd improve with more time

- Canary/blue-green rollouts with Argo Rollouts instead of a plain Deployment
- Centralized logging with Loki
- tfsec/Checkov scanning in the Terraform CI (see the companion
  `multi-env-terraform` repo)
