#!/bin/bash
# Setup Minikube cluster on macOS

set -e

echo "Setting up Minikube cluster..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is for macOS only"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew if needed
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Docker Desktop if needed
if ! command_exists docker; then
    echo "Installing Docker Desktop..."
    brew install --cask docker
    echo "Please start Docker Desktop from Applications and run this script again"
    open -a Docker
    exit 0
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Starting Docker Desktop..."
    open -a Docker
    echo "Waiting for Docker to start..."
    for i in {1..30}; do
        if docker info >/dev/null 2>&1; then
            echo "Docker is running"
            break
        fi
        sleep 2
    done
    
    if ! docker info >/dev/null 2>&1; then
        echo "Docker failed to start. Please start it manually and try again"
        exit 1
    fi
fi

# Install kubectl
if ! command_exists kubectl; then
    echo "Installing kubectl..."
    brew install kubectl
fi

# Install Minikube
if ! command_exists minikube; then
    echo "Installing Minikube..."
    brew install minikube
fi

# Start Minikube if not running
if minikube status >/dev/null 2>&1; then
    echo "Minikube is already running"
else
    echo "Starting Minikube cluster..."
    echo "This will take a few minutes on first run..."
    minikube start --driver=docker --cpus=2 --memory=4096
fi

# Set kubectl context
kubectl config use-context minikube

# Enable useful addons
echo "Enabling metrics-server addon..."
minikube addons enable metrics-server

echo "Enabling dashboard addon..."
minikube addons enable dashboard

# Show cluster info
echo ""
echo "Cluster setup complete!"
echo ""
kubectl cluster-info
echo ""
kubectl get nodes
