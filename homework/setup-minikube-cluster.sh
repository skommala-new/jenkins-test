#!/bin/bash
# Setup Minikube Cluster (macOS + Docker driver)
# Creates/starts a local Kubernetes cluster and prints a short summary.

set -e

echo "=== Minikube Cluster Setup ==="

# --- Basic command checks ---
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    echo "Please install it and re-run this script."
    exit 1
  fi
}

# macOS hint (safe to skip if you want cross-platform)
case "$OSTYPE" in
  darwin*) : ;;
  *) echo "Note: this script is written for macOS + Docker Desktop."; ;;
esac

require_cmd docker
require_cmd kubectl
require_cmd minikube

# --- Ensure Docker is running ---
if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop does not appear to be running."
  echo "Please start Docker Desktop, wait until it's ready, then re-run."
  exit 1
fi

# --- Start or reuse Minikube ---
if minikube status >/dev/null 2>&1; then
  echo "Minikube is already running."
else
  echo "Starting Minikube (driver=docker, cpus=2, memory=4g, disk=20g)..."
  minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g
fi

# --- Set kubectl context to minikube ---
kubectl config use-context minikube >/dev/null 2>&1 || true

# --- Optional addons (best-effort; ignore errors) ---
echo "Enabling metrics-server addon (optional)..."
minikube addons enable metrics-server >/dev/null 2>&1 || true

echo "Enabling dashboard addon (optional)..."
minikube addons enable dashboard >/dev/null 2>&1 || true

# --- Summary ---
echo
echo "=== Cluster Summary ==="
kubectl version --client --short || true
kubectl cluster-info
echo
echo "Nodes:"
kubectl get nodes -o wide
echo
echo "System pods (kube-system):"
kubectl get pods -n kube-system
echo
echo "Done."
echo
echo "Next step:"
echo "  ./deploy-application.sh"
echo
echo "Useful commands:"
echo "  kubectl get pods,svc           # see workloads and services"
echo "  minikube service <svc> --url   # get a URL for a NodePort service"
echo "  minikube stop                  # stop the cluster"
echo "  minikube delete                # delete the cluster"