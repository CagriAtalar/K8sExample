#!/bin/bash
# Script to deploy the Counter App to Kubernetes
# Run this script on a machine with kubectl access to your cluster

set -e

# Registry configuration
MASTER_IP=192.168.0.146
REGISTRY_PORT=5000
REGISTRY_URL="$MASTER_IP:$REGISTRY_PORT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}☸️ Deploying Counter App to Kubernetes...${NC}"

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not available or not configured!${NC}"
    echo -e "${YELLOW}   Please ensure kubectl is installed and configured to access your cluster.${NC}"
    exit 1
fi

# Check cluster connectivity
echo -e "${BLUE}🔍 Checking cluster connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster!${NC}"
    exit 1
fi

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
echo -e "   Frontend URL: http://192.168.0.233:30080"
echo -e "   Backend API: http://192.168.0.233:30001 (internal only)"
echo ""
echo -e "${YELLOW}🔒 Security Notes:${NC}"
echo -e "   ✅ PostgreSQL: Only accessible within cluster"
echo -e "   ✅ Backend: Accessible only from worker1 node"
echo -e "   ✅ Frontend: Publicly accessible via LoadBalancer"
echo ""
echo -e "${BLUE}📝 Troubleshooting:${NC}"
echo -e "   kubectl logs -l app=postgres"
echo -e "   kubectl logs -l app=backend"
echo -e "   kubectl logs -l app=frontend"
echo ""
echo -e "${YELLOW}📋 Registry Information:${NC}"
echo -e "   Registry URL: $REGISTRY_URL"
echo -e "   Frontend Image: $REGISTRY_URL/counter-frontend:latest"
echo -e "   Backend Image: $REGISTRY_URL/counter-backend:latest"
