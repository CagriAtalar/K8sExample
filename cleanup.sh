#!/bin/bash
# Script to clean up the Counter App deployment
# Run this script to remove all deployed resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🧹 Cleaning up Counter App from Kubernetes...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to delete Kubernetes manifests
remove_k8s_manifests() {
    local path=$1
    local description=$2
    
    echo -e "${RED}🗑️ Removing $description...${NC}"
    
    if [ -d "$path" ]; then
        for file in "$path"/*.yaml; do
            if [ -f "$file" ]; then
                echo -e "   Deleting $(basename "$file")..."
                kubectl delete -f "$file" --ignore-not-found=true
            fi
        done
        echo -e "${GREEN}✅ $description removed!${NC}"
    fi
}

# Remove in reverse order: Frontend -> Backend -> PostgreSQL
echo -e "${BLUE}📊 Cleanup order: Frontend -> Backend -> PostgreSQL${NC}"

# Remove Frontend
remove_k8s_manifests "./k8s/frontend" "Frontend"

# Remove Backend
remove_k8s_manifests "./k8s/backend" "Backend API"

# Remove PostgreSQL
remove_k8s_manifests "./k8s/postgres" "PostgreSQL"

# Show remaining resources
echo -e "${BLUE}📋 Remaining resources:${NC}"
kubectl get pods,services,pvc | grep -E "counter|postgres|backend|frontend" || echo "No related resources found"

echo -e "${GREEN}🎉 Cleanup completed!${NC}"

# Optional: Clean up registry
echo ""
echo -e "${YELLOW}💡 Optional: To also remove the local registry, run on master node:${NC}"
echo -e "   nerdctl stop local-registry"
echo -e "   nerdctl rm local-registry"
