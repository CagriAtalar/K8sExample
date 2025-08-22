#!/bin/bash
# Script to cleanup Counter App from Minikube
# Run this script in WSL

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up Counter App from Minikube...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to delete Kubernetes resources
cleanup_k8s_resources() {
    local path=$1
    local description=$2
    
    echo -e "${YELLOW}🗑️ Removing $description...${NC}"
    
    if [ -d "$path" ]; then
        for file in "$path"/*.yaml; do
            if [ -f "$file" ]; then
                echo -e "   Deleting resources from $(basename "$file")..."
                kubectl delete -f "$file" --ignore-not-found=true
            fi
        done
        echo -e "${GREEN}✅ $description removed successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️ Path $path not found, skipping...${NC}"
    fi
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not available!${NC}"
    exit 1
fi

# Delete resources in reverse order: Frontend -> Backend -> PostgreSQL
echo -e "${BLUE}📊 Cleanup order: Frontend -> Backend -> PostgreSQL${NC}"

cleanup_k8s_resources "./k8s/frontend" "Frontend"
cleanup_k8s_resources "./k8s/backend" "Backend API" 
cleanup_k8s_resources "./k8s/postgres" "PostgreSQL"

# Clean up any remaining pods
echo -e "${YELLOW}🔍 Checking for remaining pods...${NC}"
REMAINING_PODS=$(kubectl get pods --no-headers 2>/dev/null | grep -E "(frontend|backend|postgres)" | wc -l)
if [ "$REMAINING_PODS" -gt 0 ]; then
    echo -e "${YELLOW}⏳ Waiting for pods to terminate...${NC}"
    kubectl wait --for=delete pod -l app=frontend --timeout=60s 2>/dev/null || true
    kubectl wait --for=delete pod -l app=backend --timeout=60s 2>/dev/null || true  
    kubectl wait --for=delete pod -l app=postgres --timeout=60s 2>/dev/null || true
fi

# Optionally remove Docker images from Minikube
echo -e "${BLUE}🤔 Do you want to remove Docker images from Minikube? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${YELLOW}🗑️ Removing Docker images...${NC}"
    eval $(minikube docker-env)
    docker rmi counter-frontend:latest 2>/dev/null || echo -e "${YELLOW}   Frontend image not found${NC}"
    docker rmi counter-backend:latest 2>/dev/null || echo -e "${YELLOW}   Backend image not found${NC}"
    echo -e "${GREEN}✅ Docker images removed!${NC}"
fi

# Show final status
echo -e "${BLUE}📋 Final Status:${NC}"
kubectl get pods 2>/dev/null || echo "No pods found"
echo ""
kubectl get services 2>/dev/null || echo "No services found"  
echo ""

echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
echo -e "${BLUE}💡 Helpful commands:${NC}"
echo -e "   kubectl get all              # Check all resources"
echo -e "   minikube stop               # Stop Minikube"
echo -e "   minikube delete             # Delete entire Minikube cluster"
echo -e "   minikube start              # Start Minikube again"
