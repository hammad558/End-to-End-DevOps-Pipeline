#!/usr/bin/env bash
# One-shot cluster bootstrap after `terraform apply`:
# ingress-nginx, Argo CD, kube-prometheus-stack, then the Argo CD Application.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-wanderlust}"
REGION="${AWS_REGION:-us-east-2}"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Ingress controller (provisions one NLB for the whole cluster)
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb

# Argo CD
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --set server.service.type=ClusterIP

# Monitoring
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f "$(dirname "$0")/../monitoring/values.yaml"

# Register the application. From here on, git is the deploy interface.
kubectl apply -f "$(dirname "$0")/../argocd/application.yaml"

echo
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "Ingress load balancer:"
kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
