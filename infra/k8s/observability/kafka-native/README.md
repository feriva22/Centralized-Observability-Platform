# kafka-native

Apache Kafka-native KRaft cluster untuk LGTM stack ingest storage.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- PersistentVolume provisioner (jika persistence enabled)

## Install

```bash
helm upgrade --install kafka-native . -n observability --create-namespace
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `replicas` | int | `3` | Jumlah broker (KRaft mode, tiap broker juga controller) |
| `image.registry` | string | `docker.io` | Registry image |
| `image.repository` | string | `apache/kafka-native` | Repository image |
| `image.tag` | string | `4.1.0` | Tag image |
| `image.pullPolicy` | string | `IfNotPresent` | Pull policy |
| `service.port` | int | `9092` | Kafka client port |
| `service.controllerPort` | int | `9093` | Controller port |
| `service.type` | string | `ClusterIP` | Service type |
| `persistence.enabled` | bool | `true` | Enable PVC |
| `persistence.size` | string | `20Gi` | Ukuran PV per broker |
| `persistence.storageClassName` | string | `""` | Storage class (default cluster) |
| `resources.requests.cpu` | string | `2` | CPU request |
| `resources.requests.memory` | string | `2Gi` | Memory request |
| `logRetentionHours` | int | `72` | Retention log Kafka (jam) |
| `podDisruptionBudget.maxUnavailable` | int | `1` | Max unavailable pods |
| `env` | list | `[]` | Override / tambahan environment variables |
| `extraEnvFrom` | list | `[]` | Env from secrets/configmaps |
| `extraVolumes` | list | `[]` | Extra volumes |
| `extraVolumeMounts` | list | `[]` | Extra volume mounts |
| `nodeSelector` | object | `{}` | Node selector |
| `tolerations` | list | `[]` | Tolerations |
| `affinity` | object | `{}` | Affinity |
| `priorityClassName` | string | `null` | Priority class |

## Konfigurasi

### Override env vars

Gunakan `env` untuk override variable default Kafka:

```yaml
env:
  - name: KAFKA_LOG_RETENTION_HOURS
    value: "168"
  - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
    value: "3"
```

### Node selector + toleransi

```yaml
nodeSelector:
  node-type: kafka-worker

tolerations:
  - key: "kafka"
    operator: "Exists"
    effect: "NoSchedule"
```

### Resource besar (high throughput)

```yaml
replicas: 3
resources:
  requests:
    cpu: 4
    memory: 8Gi
persistence:
  size: 100Gi
```

## Integrasi dengan Mimir

Setelah deploy, disable bundled Kafka dan arahkan Mimir ke kafka-native:

```yaml
kafka:
  enabled: false

mimir:
  structuredConfig:
    ingest_storage:
      kafka:
        address: kafka-native.observability.svc.cluster.local:9092
        topic: mimir-ingest
        auto_create_topic_enabled: true
        auto_create_topic_default_partitions: 100
```

## Integrasi dengan Tempo

```yaml
tempo:
  structuredConfig:
    ingest_storage:
      kafka:
        address: kafka-native.observability.svc.cluster.local:9092
        topic: tempo-traces
        auto_create_topic_enabled: true
```

## Uninstall

```bash
helm uninstall kafka-native -n observability
```

PVC tidak otomatis terhapus. Hapus manual jika needed:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=kafka-native -n observability
```
