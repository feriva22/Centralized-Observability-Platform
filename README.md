# Centralized Observability Platform

LGTM stack (Loki, Grafana, Tempo, Mimir) with self-hosted MinIO as S3-compatible storage and Kafka KRaft for message streaming, deployed on Kubernetes via ArgoCD.

## Folder Structure

```
infra/k8s/observability/
├── argocd-apps/
│   ├── observability-appset-sandbox.yaml
│   └── observability-appset-prod.yaml
├── minio/
│   ├── .helmignore
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-sandbox.yaml
│   ├── values-prod.yaml
│   └── templates/
│       └── namespace.yaml
├── kafka/
│   ├── .helmignore
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-sandbox.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── namespace.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── service.yaml
│       ├── statefulset.yaml
│       └── job-topic-provisioner.yaml
├── loki/
│   ├── .helmignore
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-sandbox.yaml
│   ├── values-prod.yaml
│   └── templates/
│       └── namespace.yaml
├── tempo/
│   ├── .helmignore
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-sandbox.yaml
│   ├── values-prod.yaml
│   └── templates/
│       └── namespace.yaml
├── mimir/
│   ├── .helmignore
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-sandbox.yaml
│   ├── values-prod.yaml
│   └── templates/
│       └── namespace.yaml
└── grafana/
    ├── .helmignore
    ├── Chart.yaml
    ├── values.yaml
    ├── values-sandbox.yaml
    ├── values-prod.yaml
    └── templates/
        └── namespace.yaml
```

## Prerequisites

- Kubernetes cluster
- Helm 3

## Folder Structure

```
infra/
├── k8s/
│   ├── gitops/
│   │   └── argocd/
│   │       ├── .helmignore
│   │       ├── Chart.yaml
│   │       ├── install.sh
│   │       ├── values.yaml
│   │       ├── values-sandbox.yaml
│   │       ├── values-prod.yaml
│   │       └── templates/
│   │           └── namespace.yaml
│   └── observability/
│       ├── argocd-apps/
│       │   ├── observability-appset-sandbox.yaml
│       │   └── observability-appset-prod.yaml
│       ├── minio/
│       ├── kafka/
│       ├── loki/
│       ├── tempo/
│       ├── mimir/
│       └── grafana/
```

## Bootstrap

1. Install ArgoCD:
   ```bash
   # sandbox
   bash infra/k8s/gitops/argocd/install.sh sandbox

   # production
   bash infra/k8s/gitops/argocd/install.sh prod
   ```

   Get the initial admin password:
   ```bash
   kubectl get secret argocd-initial-admin-secret -n argocd \
     -o jsonpath='{.data.password}' | base64 -d
   ```

2. Apply the observability ApplicationSet:
   ```bash
   # sandbox
   kubectl apply -f infra/k8s/observability/argocd-apps/observability-appset-sandbox.yaml

   # production
   kubectl apply -f infra/k8s/observability/argocd-apps/observability-appset-prod.yaml
   ```

   This creates two ApplicationSets:

   | ApplicationSet | Target | Apps Created |
   |---|---|---|
   | `observability-sandbox` | sandbox cluster | `obs-sandbox-minio`, `obs-sandbox-kafka`, `obs-sandbox-loki`, `obs-sandbox-tempo`, `obs-sandbox-mimir`, `obs-sandbox-grafana` |
   | `observability-prod` | prod cluster | `obs-prod-minio`, `obs-prod-kafka`, `obs-prod-loki`, `obs-prod-tempo`, `obs-prod-mimir`, `obs-prod-grafana` |

   > **Note:** Deploy in order — `minio` first (buckets), then `kafka` (topics), then the rest.

   > **Namespace:** Each chart renders its own `namespace.yaml` template. The `observability` namespace is created automatically on first sync per component.

   > **Prod safety:** `prune: false` on prod — resources are never auto-deleted. Manual sync required for removals.

3. Update Helm dependencies for each component before first sync:
   ```bash
   helm dependency update infra/k8s/observability/minio
   helm dependency update infra/k8s/observability/kafka
   helm dependency update infra/k8s/observability/loki
   helm dependency update infra/k8s/observability/tempo
   helm dependency update infra/k8s/observability/mimir
   helm dependency update infra/k8s/observability/grafana
   ```

## Configuration

### MinIO
Set `minio.auth.rootPassword` in `minio/values.yaml` or inject via a Kubernetes Secret.

Default buckets are auto-created on startup:
- `loki-chunks`
- `tempo-traces`
- `mimir-blocks`
- `mimir-alertmanager`
- `mimir-ruler`

### S3 credentials per component
All components are pre-configured to point to MinIO in-cluster at `obs-minio.observability.svc.cluster.local:9000`.
Fill in `secret_access_key` / `secret_key` to match `minio.auth.rootPassword`:

| Component | Values key |
|---|---|
| Loki | `loki.loki.storage.s3.secret_access_key` |
| Tempo | `tempo.tempo.storage.trace.s3.secret_key` |
| Mimir | `mimir-distributed.mimir.structuredConfig.common.storage.s3.secret_access_key` |

### Grafana
Set `grafana.adminPassword` in `grafana/values.yaml` or use a Kubernetes Secret.

## ArgoCD Apps

| App | Component | Path |
|---|---|---|
| obs-minio | S3-compatible object storage | `infra/k8s/observability/minio` |
| obs-kafka | Kafka KRaft message streaming | `infra/k8s/observability/kafka` |
| obs-loki | Log aggregation | `infra/k8s/observability/loki` |
| obs-tempo | Distributed tracing | `infra/k8s/observability/tempo` |
| obs-mimir | Metrics storage | `infra/k8s/observability/mimir` |
| obs-grafana | Dashboards & UI | `infra/k8s/observability/grafana` |
