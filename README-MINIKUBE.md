# 🚀 Counter App - Minikube Deployment Guide

A full-stack application (React frontend, Node.js backend, PostgreSQL database) optimized for deployment on **Minikube** in **WSL**.

## 📋 Architecture for Minikube

```
[User Browser]
    ↓ (HTTP)
[Frontend Service @ minikube-ip:30080]
    ↓ (API calls to minikube-ip:30001)
[Backend NodePort Service @ minikube-ip:30001]
    ↓ (Internal cluster communication)
[PostgreSQL ClusterIP @ postgres-service:5432]
    ↑
[Minikube Docker Daemon] ← Local Docker Images
```

## 🔒 Security Model

- **PostgreSQL**: Only accessible within the Kubernetes cluster
- **Backend**: Exposed via NodePort for frontend communication
- **Frontend**: Publicly accessible via NodePort service
- **Images**: Built directly in Minikube's Docker daemon (no external registry needed)

## 🛠️ Prerequisites

### 1. WSL2 Setup
- **Windows Subsystem for Linux 2** installed and running
- **Ubuntu 20.04/22.04** (recommended) or any compatible Linux distribution

### 2. Required Tools in WSL

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Logout and login again (or restart WSL) to apply docker group changes
```

### 3. Verify Installation

```bash
# Check versions
docker --version
kubectl version --client
minikube version

# Test Docker
docker run hello-world
```

## 🚀 Quick Start

### 1. Start Minikube

```bash
# Start Minikube with recommended settings
minikube start --driver=docker --memory=4096 --cpus=2

# Verify Minikube is running
minikube status

# Get Minikube IP (note this down)
minikube ip
```

### 2. Clone and Navigate to Project

```bash
# Clone the repository (if not already done)
git clone <your-repo-url>
cd K8sExample

# Make scripts executable (in WSL)
chmod +x *.sh
```

### 3. Build Docker Images

```bash
# Build images using Minikube's Docker daemon
./build-and-push-minikube.sh
```

### 4. Deploy to Minikube

```bash
# Deploy all components
./deploy-k8s-minikube.sh
```

### 5. Access the Application

The deployment script will show you the exact URL, but typically:

```bash
# Get the frontend URL
echo "Frontend: http://$(minikube ip):30080"

# Or use Minikube's service command (opens automatically)
minikube service frontend-service

# Get backend URL (for debugging)
minikube service backend-nodeport-service --url
```

## 📁 Project Structure (Minikube-Optimized)

```
K8sExample/
├── frontend/                    # React application
│   ├── src/
│   ├── Dockerfile              # Multi-stage build optimized
│   └── nginx.conf              # Nginx configuration
│
├── backend/                     # Node.js API
│   ├── server.js               # Express server with PostgreSQL
│   ├── Dockerfile              # Alpine-based for efficiency
│   └── package.json
│
├── k8s/                        # Kubernetes manifests (Minikube-optimized)
│   ├── postgres/               # PostgreSQL deployment
│   ├── backend/                # Backend API (ClusterIP + NodePort)
│   └── frontend/               # Frontend (NodePort service)
│
├── build-and-push-minikube.sh  # Build images for Minikube
├── deploy-k8s-minikube.sh      # Deploy to Minikube
├── cleanup-minikube.sh         # Cleanup resources
├── README-MINIKUBE.md          # This file
└── README.md                   # Original multi-node guide
```

## 🎯 Key Differences from Multi-Node Setup

| Aspect | Multi-Node Setup | Minikube Setup |
|--------|-----------------|----------------|
| **Nodes** | Multiple worker nodes | Single node |
| **Registry** | External registry (192.168.0.146:5000) | Minikube's Docker daemon |
| **Image Pull Policy** | `Always` | `Never` |
| **Node Selector** | `kubernetes.io/hostname: worker1` | Removed |
| **Resource Limits** | Higher (production-like) | Lower (development) |
| **Replicas** | 2 per service | 1 per service |
| **Service Types** | LoadBalancer + NodePort | NodePort only |

## 🔧 Manual Commands

### Building Images Manually

```bash
# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)

# Backend
cd backend
docker build -t counter-backend:latest .

# Frontend
cd ../frontend
docker build -t counter-frontend:latest .

# Verify images
docker images | grep counter
```

### Deploying Manually

```bash
# Get Minikube IP first
MINIKUBE_IP=$(minikube ip)

# Update frontend config with actual IP
sed -i "s|MINIKUBE_IP_PLACEHOLDER|$MINIKUBE_IP|g" k8s/frontend/frontend-configmap.yaml

# Deploy components
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/frontend/
```

### Monitoring and Debugging

```bash
# Check pods
kubectl get pods -o wide

# Check services
kubectl get services

# Check logs
kubectl logs -l app=backend
kubectl logs -l app=frontend
kubectl logs -l app=postgres

# Open Kubernetes dashboard
minikube dashboard

# SSH into Minikube node
minikube ssh
```

## 🌐 API Endpoints

The backend API provides:

- `GET /health` - Health check
- `GET /api/count` - Get current counter value
- `POST /api/increment` - Increment counter by 1
- `POST /api/reset` - Reset counter to 0

## 🐛 Troubleshooting

### Common Issues

1. **Minikube won't start**
   ```bash
   # Check Docker is running
   sudo systemctl status docker
   
   # Clean start
   minikube delete
   minikube start --driver=docker
   ```

2. **Images not found**
   ```bash
   # Make sure Docker environment is set
   eval $(minikube docker-env)
   docker images | grep counter
   
   # Rebuild if needed
   ./build-and-push-minikube.sh
   ```

3. **Pods stuck in Pending**
   ```bash
   # Check resources
   kubectl describe nodes
   kubectl top nodes  # if metrics-server enabled
   
   # Check pod events
   kubectl describe pod <pod-name>
   ```

4. **Frontend can't reach backend**
   ```bash
   # Check if IP was updated correctly
   kubectl get configmap frontend-config -o yaml
   
   # Verify backend service
   kubectl get service backend-nodeport-service
   minikube service backend-nodeport-service --url
   ```

### Debug Commands

```bash
# Check cluster info
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check all resources
kubectl get all

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Port forward for debugging
kubectl port-forward service/backend-service 3001:3001
kubectl port-forward service/frontend-service 8080:80
```

## 🧹 Cleanup

### Remove Application Only
```bash
# Remove all app resources
./cleanup-minikube.sh
```

### Complete Cleanup
```bash
# Remove application
./cleanup-minikube.sh

# Stop Minikube
minikube stop

# Delete Minikube cluster (this removes everything)
minikube delete
```

## 📊 Resource Requirements (Minikube-Optimized)

| Component | Memory Request | Memory Limit | CPU Request | CPU Limit | Replicas |
|-----------|---------------|--------------|-------------|-----------|----------|
| **PostgreSQL** | 128Mi | 256Mi | 100m | 200m | 1 |
| **Backend** | 64Mi | 128Mi | 50m | 100m | 1 |
| **Frontend** | 32Mi | 64Mi | 25m | 50m | 1 |

**Total Requirements:**
- **Memory**: ~224Mi (minimum), ~448Mi (with limits)
- **CPU**: ~175m (minimum), ~350m (with limits)

**Recommended Minikube Settings:**
```bash
minikube start --driver=docker --memory=4096 --cpus=2
```

## 🔑 Default Credentials

- **PostgreSQL**:
  - User: `postgres`
  - Password: `password`
  - Database: `counterdb`

> ⚠️ **Security Note**: Change default passwords in production environments!

## 💡 Useful Minikube Commands

```bash
# Minikube management
minikube start                    # Start cluster
minikube stop                     # Stop cluster
minikube status                   # Check status
minikube ip                       # Get cluster IP
minikube delete                   # Delete cluster

# Service access
minikube service <service-name>   # Open service in browser
minikube service list             # List all services
minikube tunnel                   # Enable LoadBalancer services

# Debugging
minikube dashboard               # Kubernetes dashboard
minikube logs                    # Minikube logs
minikube ssh                     # SSH into node

# Docker environment
eval $(minikube docker-env)      # Use Minikube's Docker
docker context use default      # Back to host Docker
```

## 🎮 Testing the Application

Once deployed, you can test the counter functionality:

1. **Access the frontend**: `http://$(minikube ip):30080`
2. **Increment counter**: Click the "+" button
3. **Reset counter**: Click the "Reset" button
4. **Check persistence**: Refresh the page - counter value should persist

The data is stored in PostgreSQL and will persist across pod restarts (but not cluster deletion).

## 📝 Notes

- All components run on a single Minikube node
- Images are built directly in Minikube's Docker daemon (no registry needed)
- Resource limits are optimized for development/testing
- Use `minikube service` commands for easy access to services
- The frontend automatically gets the correct backend URL via ConfigMap
