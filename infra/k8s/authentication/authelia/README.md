# Authelia

[Authelia](https://www.authelia.com/) adalah Single Sign-On Multi-Factor portal untuk web apps.

## Prerequisites

- Kubernetes 1.30+
- Helm 3.8+
- PersistentVolume provisioner (jika persistence enabled)
- Redis (wajib untuk production, opsional untuk sandbox)

## Add Repository

```bash
helm repo add authelia https://charts.authelia.com
helm repo update
```

## Install

### Sandbox (file-based auth, SQLite, filesystem notifier)

```bash
helm upgrade --install authelia . \
  -n authentication --create-namespace \
  -f values.yaml -f values-sandbox.yaml
```

### Production (LDAP, PostgreSQL, SMTP, Redis)

```bash
helm upgrade --install authelia . \
  -n authentication --create-namespace \
  -f values.yaml -f values-prod.yaml
```

## Dependencies

Chart ini menggunakan dependency ke upstream chart `authelia/authelia` (v0.11.6 / app v4.39.20).

Sebelum install, jalankan:

```bash
helm dependency update
```

## Struktur File

```
authelia/
├── Chart.yaml            # Dependency ke upstream authelia chart
├── values.yaml           # Base values (default sandbox)
├── values-sandbox.yaml   # Override untuk environment sandbox
├── values-prod.yaml      # Override untuk environment production
└── README.md
```

## Konfigurasi

### Authentication Backend

| Environment | Backend     | Keterangan                         |
|-------------|-------------|------------------------------------|
| Sandbox     | File        | Users disimpan di file users.yml   |
| Production  | LDAP        | Integrasi dengan LDAP server       |

### Storage Backend

| Environment | Backend     | Keterangan                          |
|-------------|-------------|-------------------------------------|
| Sandbox     | SQLite      | Local database, cukup untuk testing |
| Production  | PostgreSQL  | Production-grade, high availability |

### Notifier

| Environment | Backend     | Keterangan                          |
|-------------|-------------|-------------------------------------|
| Sandbox     | Filesystem  | Notifikasi ditulis ke file          |
| Production  | SMTP        | Email notification via SMTP server  |

### Session Storage

| Environment | Backend | Keterangan                          |
|-------------|---------|-------------------------------------|
| Sandbox     | Memory  | Sederhana, tidak perlu Redis        |
| Production  | Redis   | Production-grade session store      |

## Important Notes

- **Sandbox**: Gunakan file-based auth, SQLite, dan filesystem notifier untuk development.
- **Production**: Wajib menggunakan PostgreSQL, Redis, LDAP/remote auth backend, dan SMTP notifier.
- **Secrets**: Password dan key sensitif dikelola via Kubernetes Secrets. Untuk production, jangan gunakan `value:` langsung di values.
- **Ingress**: Sesuaikan domain dan TLS certificate dengan environment masing-masing.
