#!/bin/bash
# Script to build Docker images and push to local registry
# Run this script on the worker1 node (192.168.0.233)

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

echo -e "${GREEN}🚀 Building Counter App Docker Images with nerdctl...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}📁 Current directory: $(pwd)${NC}"

# Check if nerdctl is available
if ! command -v nerdctl &> /dev/null; then
    echo -e "${RED}❌ nerdctl is not available!${NC}"
    echo -e "${YELLOW}   Please install nerdctl first.${NC}"
    exit 1
fi

# Test registry connectivity
echo -e "${YELLOW}🔍 Testing registry connectivity...${NC}"
if ! curl -f http://$REGISTRY_URL/v2/ &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to registry at $REGISTRY_URL${NC}"
    echo -e "${YELLOW}   Please ensure the registry is running on the master node.${NC}"
    echo -e "${YELLOW}   Run ./setup-registry.sh on the master node first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Registry is accessible${NC}"

# Function to build and push image
build_and_push() {
    local service=$1
    local image_name="$REGISTRY_URL/counter-$service:latest"
    
    echo -e "${YELLOW}🔨 Building $service image...${NC}"
    cd "$service"
    
    # Build the image
    nerdctl build -t "$image_name" .
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ $service build failed!${NC}"
        exit 1
    fi
    
    # Push to registry
    echo -e "${YELLOW}📤 Pushing $service image to registry...${NC}"
    nerdctl push "$image_name"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ $service push failed!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ $service image built and pushed successfully!${NC}"
    cd ..
}

# Build backend image
build_and_push "backend"

# Build frontend image  
build_and_push "frontend"

# List images in registry
echo -e "${BLUE}📋 Images in registry:${NC}"
curl -s http://$REGISTRY_URL/v2/_catalog | jq '.' 2>/dev/null || echo "Registry catalog:"
curl -s http://$REGISTRY_URL/v2/_catalog

echo -e "${GREEN}🎉 All images built and pushed successfully!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "   1. Run ./deploy-k8s.sh to deploy to Kubernetes"
echo -e "   2. Access frontend at http://192.168.0.233:30080"

echo -e "${YELLOW}📋 Built and pushed images:${NC}"
echo -e "   Frontend: $REGISTRY_URL/counter-frontend:latest"
echo -e "   Backend:  $REGISTRY_URL/counter-backend:latest"
