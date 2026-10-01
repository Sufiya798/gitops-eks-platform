# Grafana dashboards

Export your custom dashboard JSON here after building it in the Grafana UI
(Dashboard settings -> JSON Model -> copy). Suggested panels for this project:

- Deploy frequency (count of ArgoCD syncs per day)
- Rollback count / mean time to rollback
- Pod restart count by namespace
- Request rate and error rate for the app
- Node CPU / memory utilization

Import kube-prometheus-stack's built-in dashboards first (IDs 315, 7249, 6417
on grafana.com/dashboards) and customize from there rather than starting blank.
