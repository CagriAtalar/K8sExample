#!/bin/bash
# Script to build Docker images for Minikube
# Run this script in WSL with Minikube running

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building Counter App Docker Images for Minikube...${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}📁 Current directory: $(pwd)${NC}"

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo -e "${RED}❌ Minikube is not running!${NC}"
    echo -e "${YELLOW}   Please start Minikube first: minikube start${NC}"
    exit 1
fi

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ docker is not available!${NC}"
    echo -e "${YELLOW}   Please install docker first.${NC}"
    exit 1
fi

# Configure docker to use Minikube's Docker daemon
echo -e "${YELLOW}🔧 Configuring Docker to use Minikube's Docker daemon...${NC}"
eval $(minikube docker-env)

# Function to build image
build_image() {
    local service=$1
    local image_name="counter-$service:latest"
    
    echo -e "${YELLOW}🔨 Building $service image...${NC}"
    cd "$service"
    
    # Build the image
    docker build -t "$image_name" .
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ $service build failed!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ $service image built successfully!${NC}"
    cd ..
}

# Build backend image
build_image "backend"

# Build frontend image  
build_image "frontend"

# List images
echo -e "${BLUE}📋 Images in Minikube Docker daemon:${NC}"
docker images | grep counter

echo -e "${GREEN}🎉 All images built successfully!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "   1. Run ./deploy-k8s-minikube.sh to deploy to Minikube"
echo -e "   2. Access frontend at http://\$(minikube ip):30080"

echo -e "${YELLOW}📋 Built images:${NC}"
echo -e "   Frontend: counter-frontend:latest"
echo -e "   Backend:  counter-backend:latest"

echo -e "${BLUE}💡 Tip: Use 'minikube service frontend-service' to automatically open the app${NC}"
