#!/usr/bin/env bash
# Bootstrap ArgoCD installation
# Usage:
#   ./install.sh sandbox
#   ./install.sh prod

set -euo pipefail

ENV=${1:-sandbox}
CHART_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_NAME="argocd"
NAMESPACE="argocd"

if [[ "$ENV" != "sandbox" && "$ENV" != "prod" ]]; then
  echo "Usage: $0 [sandbox|prod]"
  exit 1
fi

echo "Installing ArgoCD for environment: $ENV"

# Add Argo Helm repo if not already added
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Update chart dependencies (use update to fetch and generate Chart.lock)
helm dependency update "$CHART_DIR"

# Install or upgrade
helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$CHART_DIR/values.yaml" \
  --values "$CHART_DIR/values-${ENV}.yaml" \
  --wait \
  --timeout 10m

echo ""
echo "ArgoCD installed successfully."
echo ""
echo "Get the initial admin password:"
echo "  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Port-forward the UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "Then apply the observability ApplicationSet:"
echo "  kubectl apply -f infra/k8s/observability/argocd-apps/observability-appset-${ENV}.yaml"
