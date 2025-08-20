#!/bin/bash
# Script to setup local Docker registry
# Run this script on the master node (192.168.0.146)

set -e

echo "🚀 Setting up local Docker registry..."

# Registry configuration
REGISTRY_PORT=5000
REGISTRY_NAME=local-registry
MASTER_IP=192.168.0.146

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📁 Current directory: $(pwd)${NC}"

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ docker is not available!${NC}"
    echo -e "${YELLOW}   Please install docker first.${NC}"
    exit 1
fi

# Stop and remove existing registry if it exists
echo -e "${YELLOW}🔍 Checking for existing registry...${NC}"
if docker ps -a | grep -q $REGISTRY_NAME; then
    echo -e "${YELLOW}🛑 Stopping existing registry...${NC}"
    docker stop $REGISTRY_NAME || true
    docker rm $REGISTRY_NAME || true
fi

# Run the registry container
echo -e "${YELLOW}🔨 Starting local registry on port $REGISTRY_PORT...${NC}"
docker run -d \
    -p $REGISTRY_PORT:5000 \
    --name $REGISTRY_NAME \
    --restart unless-stopped \
    registry:2

# Wait for registry to be ready
echo -e "${YELLOW}⏳ Waiting for registry to be ready...${NC}"
sleep 5

# Test registry connectivity
if curl -f http://localhost:$REGISTRY_PORT/v2/ &> /dev/null; then
    echo -e "${GREEN}✅ Registry is running successfully!${NC}"
else
    echo -e "${RED}❌ Registry failed to start properly!${NC}"
    docker logs $REGISTRY_NAME
    exit 1
fi

# Show registry information
echo -e "${BLUE}📋 Registry Information:${NC}"
echo -e "   Name: $REGISTRY_NAME"
echo -e "   URL: http://$MASTER_IP:$REGISTRY_PORT"
echo -e "   Status: $(docker ps --filter name=$REGISTRY_NAME --format "table {{.Status}}" | tail -n 1)"

echo -e "${GREEN}🎉 Local registry setup completed!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "   1. Run ./build-and-push.sh to build and push images"
echo -e "   2. Run ./deploy-k8s.sh to deploy to Kubernetes"
echo -e "   3. Access frontend at http://192.168.0.233:30080"

echo -e "${YELLOW}💡 Registry URLs for building:${NC}"
echo -e "   Frontend: $MASTER_IP:$REGISTRY_PORT/counter-frontend:latest"
echo -e "   Backend:  $MASTER_IP:$REGISTRY_PORT/counter-backend:latest"
