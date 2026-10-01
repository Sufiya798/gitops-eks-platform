# Architecture

```
 Developer
     |
     | git push (app code)
     v
 GitHub Actions  ---- build & test --->  Docker Hub (image registry)
     |
     | commits new image tag to k8s/base/deployment.yaml
     v
 Git repo (source of truth)
     |
     | detects change (auto-sync, every ~3 min by default)
     v
   ArgoCD  ---- applies manifests --->  EKS cluster (namespace: app)
                                              |
                                              v
                                   Deployment + Service + Ingress
                                              |
                                              v
                                   Prometheus scrapes metrics
                                              |
                                              v
                              Grafana dashboards + Alertmanager -> Slack
```

## Flow, in words

1. Code changes to `app/` trigger the GitHub Actions workflow (`.github/workflows/ci.yml`).
2. The workflow runs tests, builds a Docker image, pushes it to Docker Hub tagged
   with the short Git SHA, and commits the new tag into `k8s/base/deployment.yaml`.
3. That commit is the only thing that changes the cluster — nobody runs
   `kubectl apply` by hand. This is the core GitOps principle: Git is the
   single source of truth for what should be running.
4. ArgoCD watches the repo and detects the manifest change, then syncs it to
   the EKS cluster. `selfHeal: true` means if someone manually edits something
   in the cluster, ArgoCD reverts it back to match Git.
5. Prometheus scrapes pod and node metrics; Grafana visualizes them; Alertmanager
   routes alerts (crash loops, high error rate, replica mismatches) to Slack.

## Why these choices

- **Single NAT gateway** instead of one per AZ — cheaper for a portfolio project.
  Note this tradeoff explicitly if asked: production would use one per AZ for
  availability.
- **ArgoCD over "push from CI"** — CI pushing directly to the cluster means CI
  needs cluster credentials, and there's no record of desired state outside
  Git. ArgoCD pulls instead, so the cluster converges to Git state
  independently, and credentials never leave the cluster.
- **Kustomize overlays (dev/prod)** — one base manifest set, environment-specific
  patches (replica count, resource limits) layered on top instead of duplicated
  YAML.
