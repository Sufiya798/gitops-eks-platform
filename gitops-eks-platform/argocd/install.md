# Installing ArgoCD on the cluster

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward the UI
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Register this repo as an Application
kubectl apply -f argocd/application.yaml
```

Login at https://localhost:8080 with user `admin` and the password above.
