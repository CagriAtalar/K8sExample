#!/bin/bash
# Script to fix PostgreSQL storage issues and redeploy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔧 Fixing PostgreSQL Storage Issues...${NC}"

# Delete existing PostgreSQL resources
echo -e "${YELLOW}🗑️ Cleaning up existing PostgreSQL resources...${NC}"
kubectl delete deployment postgres-deployment --ignore-not-found=true
kubectl delete pvc postgres-pvc --ignore-not-found=true
kubectl delete pv postgres-pv --ignore-not-found=true

# Wait a moment for cleanup
sleep 5

# Create the storage directory on worker1 node
echo -e "${YELLOW}📁 Creating storage directory on worker1...${NC}"
echo -e "${BLUE}   Please run this command on worker1 node:${NC}"
echo -e "${GREEN}   sudo mkdir -p /data/postgres && sudo chmod 777 /data/postgres${NC}"
echo ""
read -p "Press Enter after creating the directory on worker1..."

# Apply the persistent volume first
echo -e "${YELLOW}💾 Creating Persistent Volume...${NC}"
kubectl apply -f k8s/postgres/postgres-pv.yaml

# Apply the PVC
echo -e "${YELLOW}📄 Creating Persistent Volume Claim...${NC}"
kubectl apply -f k8s/postgres/postgres-pvc.yaml

# Wait for PVC to be bound
echo -e "${YELLOW}⏳ Waiting for PVC to be bound...${NC}"
kubectl wait --for=condition=Bound pvc/postgres-pvc --timeout=60s

# Apply other PostgreSQL resources
echo -e "${YELLOW}🔐 Creating PostgreSQL secrets...${NC}"
kubectl apply -f k8s/postgres/postgres-secret.yaml

echo -e "${YELLOW}🐘 Creating PostgreSQL deployment...${NC}"
kubectl apply -f k8s/postgres/postgres-deployment.yaml

echo -e "${YELLOW}🌐 Creating PostgreSQL service...${NC}"
kubectl apply -f k8s/postgres/postgres-service.yaml

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

echo -e "${GREEN}✅ PostgreSQL is now running successfully!${NC}"

# Show status
echo -e "${BLUE}📋 PostgreSQL Status:${NC}"
kubectl get pods -l app=postgres
kubectl get pvc postgres-pvc
kubectl get pv postgres-pv

echo -e "${GREEN}🎉 PostgreSQL fix completed!${NC}"
echo -e "${BLUE}📝 Next step: Deploy backend and frontend${NC}"
