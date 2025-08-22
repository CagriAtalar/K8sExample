#!/bin/bash
# Script to deploy the Counter App to Minikube
# Run this script in WSL with Minikube running

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}☸️ Deploying Counter App to Minikube...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}📁 Current directory: $(pwd)${NC}"

# Function to apply Kubernetes manifests
apply_k8s_manifests() {
    local path=$1
    local description=$2
    
    echo -e "${YELLOW}🚀 Deploying $description...${NC}"
    
    if [ -d "$path" ]; then
        for file in "$path"/*.yaml; do
            if [ -f "$file" ]; then
                echo -e "   Applying $(basename "$file")..."
                kubectl apply -f "$file"
                if [ $? -ne 0 ]; then
                    echo -e "${RED}❌ Failed to apply $(basename "$file")${NC}"
                    return 1
                fi
            fi
        done
        echo -e "${GREEN}✅ $description deployed successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ Path $path not found!${NC}"
        return 1
    fi
}

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo -e "${RED}❌ Minikube is not running!${NC}"
    echo -e "${YELLOW}   Please start Minikube first: minikube start${NC}"
    exit 1
fi

# Check if kubectl is available and configured for minikube
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster!${NC}"
    echo -e "${YELLOW}   Please ensure kubectl is configured for Minikube.${NC}"
    exit 1
fi

# Check if images are built
echo -e "${BLUE}🔍 Checking if images are built...${NC}"
eval $(minikube docker-env)
if ! docker images | grep -q "counter-backend"; then
    echo -e "${RED}❌ Backend image not found!${NC}"
    echo -e "${YELLOW}   Please run ./build-and-push-minikube.sh first.${NC}"
    exit 1
fi

if ! docker images | grep -q "counter-frontend"; then
    echo -e "${RED}❌ Frontend image not found!${NC}"
    echo -e "${YELLOW}   Please run ./build-and-push-minikube.sh first.${NC}"
    exit 1
fi

# Get Minikube IP and update frontend config
MINIKUBE_IP=$(minikube ip)
echo -e "${BLUE}🌐 Minikube IP: $MINIKUBE_IP${NC}"

# Update frontend configmap with actual Minikube IP
sed -i "s|MINIKUBE_IP_PLACEHOLDER|$MINIKUBE_IP|g" k8s/frontend/frontend-configmap.yaml

# Deploy in order: PostgreSQL -> Backend -> Frontend
echo -e "${BLUE}📊 Deployment order: PostgreSQL -> Backend -> Frontend${NC}"

# Deploy PostgreSQL
if ! apply_k8s_manifests "./k8s/postgres" "PostgreSQL"; then
    exit 1
fi

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ PostgreSQL deployment timed out!${NC}"
    exit 1
fi

# Deploy Backend
if ! apply_k8s_manifests "./k8s/backend" "Backend API"; then
    exit 1
fi

# Wait for Backend to be ready
echo -e "${YELLOW}⏳ Waiting for Backend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Backend deployment timed out!${NC}"
    exit 1
fi

# Deploy Frontend
if ! apply_k8s_manifests "./k8s/frontend" "Frontend"; then
    exit 1
fi

# Wait for Frontend to be ready
echo -e "${YELLOW}⏳ Waiting for Frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Frontend deployment timed out!${NC}"
    exit 1
fi

# Show deployment status
echo -e "${BLUE}📋 Deployment Status:${NC}"
kubectl get pods -o wide
echo ""
kubectl get services
echo ""

# Show access information
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}🌐 Access Information:${NC}"
echo -e "   Frontend URL: http://$MINIKUBE_IP:30080"
echo -e "   Backend API: http://$MINIKUBE_IP:30001 (for debug only)"
echo ""
echo -e "${YELLOW}🚀 Quick access commands:${NC}"
echo -e "   minikube service frontend-service    # Opens frontend automatically"
echo -e "   minikube service backend-nodeport-service --url  # Gets backend URL"
echo ""
echo -e "${BLUE}📝 Troubleshooting:${NC}"
echo -e "   kubectl logs -l app=postgres"
echo -e "   kubectl logs -l app=backend"
echo -e "   kubectl logs -l app=frontend"
echo -e "   minikube dashboard    # Open Kubernetes dashboard"
echo ""
echo -e "${YELLOW}📋 Minikube Information:${NC}"
echo -e "   Minikube IP: $MINIKUBE_IP"
echo -e "   Docker environment: Use 'eval \$(minikube docker-env)'"
