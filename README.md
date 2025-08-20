# 🚀 Counter App - Kubernetes Deployment

A full-stack application demonstrating a React frontend, Node.js backend, and PostgreSQL database deployed on Kubernetes with proper network isolation and local registry.

## 📋 Architecture

```
[User @ 192.168.0.16] 
    ↓ (HTTP)
[Frontend LoadBalancer @ 192.168.0.233:30080]
    ↓ (API calls to :30001)
[Backend NodePort @ 192.168.0.233:30001]
    ↓ (Internal cluster communication)
[PostgreSQL ClusterIP @ postgres-service:5432]
    ↑
[Local Registry @ 192.168.0.146:5000] ← Docker Images
```

## 🔒 Security Model

- **PostgreSQL**: Only accessible within the Kubernetes cluster
- **Backend**: Exposed via NodePort for frontend communication, not directly accessible to external users
- **Frontend**: Publicly accessible via LoadBalancer service
- **Registry**: Local registry on master node for image distribution

## 🛠️ Prerequisites

1. **Kubernetes Cluster** with:
   - Master node: `192.168.0.146` (Debian-based)
   - Worker node: `192.168.0.233` (Debian-based, where the app will run)
   
2. **On Master Node (192.168.0.146)**:
   - `nerdctl` installed and configured
   - Container runtime (containerd)
   - Access to internet for pulling registry:2 image
   
3. **On Worker Node (192.168.0.233)**:
   - `nerdctl` installed and configured
   - Container runtime (containerd)
   - Access to master node registry (192.168.0.146:5000)
   
4. **On Control Machine**:
   - `kubectl` configured to access the cluster
   - Bash shell (Linux/WSL/Git Bash)

## 🚀 Quick Start

### 1. Setup Local Registry

Run on the master node (192.168.0.146):

```bash
# Copy the project to master node
cd /path/to/K8sExample

# Make scripts executable
chmod +x *.sh

# Setup local registry
./setup-registry.sh
```

### 2. Build and Push Images

Run on the worker node (192.168.0.233):

```bash
# Copy the project to worker1
cd /path/to/K8sExample

# Make scripts executable
chmod +x *.sh

# Build images and push to registry
./build-and-push.sh
```

### 3. Deploy to Kubernetes

Run from any machine with kubectl access:

```bash
# Deploy all components
./deploy-k8s.sh
```

### 4. Access the Application

Open your browser and navigate to:
```
http://192.168.0.233:30080
```

## 📁 Project Structure

```
K8sExample/
├── frontend/                 # React application
│   ├── src/
│   │   ├── App.js           # Main component with counter logic
│   │   ├── App.css          # Styling
│   │   └── index.js         # Entry point
│   ├── public/
│   ├── Dockerfile           # Frontend container build
│   ├── nginx.conf           # Nginx configuration
│   └── package.json
│
├── backend/                  # Node.js API
│   ├── server.js            # Express server with PostgreSQL
│   ├── Dockerfile           # Backend container build
│   ├── package.json
│   └── env.template         # Environment variables template
│
├── k8s/                     # Kubernetes manifests
│   ├── postgres/            # PostgreSQL deployment
│   │   ├── postgres-secret.yaml
│   │   ├── postgres-pvc.yaml
│   │   ├── postgres-deployment.yaml
│   │   └── postgres-service.yaml
│   ├── backend/             # Backend API deployment
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── frontend/            # Frontend deployment
│       ├── frontend-configmap.yaml
│       ├── frontend-deployment.yaml
│       ├── frontend-service.yaml
│       └── backend-nodeport-service.yaml
│
├── setup-registry.sh       # Setup local Docker registry
├── build-and-push.sh       # Build and push images to registry
├── deploy-k8s.sh           # Kubernetes deployment script
├── cleanup.sh              # Cleanup script
└── README.md               # This file
```

## 🔧 Manual Commands

### Setup Registry Manually

```bash
# On master node (192.168.0.146)
nerdctl run -d -p 5000:5000 --name local-registry registry:2
```

### Build and Push Images Manually

```bash
# Backend
cd backend
nerdctl build -t 192.168.0.146:5000/counter-backend:latest .
nerdctl push 192.168.0.146:5000/counter-backend:latest

# Frontend
cd ../frontend
nerdctl build -t 192.168.0.146:5000/counter-frontend:latest .
nerdctl push 192.168.0.146:5000/counter-frontend:latest
```

### Deploy Manually

```bash
# PostgreSQL
kubectl apply -f k8s/postgres/

# Backend
kubectl apply -f k8s/backend/

# Frontend
kubectl apply -f k8s/frontend/
```

### Check Status

```bash
# Pods
kubectl get pods -o wide

# Services
kubectl get services

# Logs
kubectl logs -l app=backend
kubectl logs -l app=frontend
kubectl logs -l app=postgres
```

## 🌐 API Endpoints

The backend API provides:

- `GET /health` - Health check
- `GET /api/count` - Get current counter value
- `POST /api/increment` - Increment counter by 1
- `POST /api/reset` - Reset counter to 0

## 🐛 Troubleshooting

### Common Issues

1. **Images not found**: Ensure images are built on the correct node
2. **Pod pending**: Check node selector and resource availability
3. **Connection refused**: Verify service configurations and network policies

### Debug Commands

```bash
# Check pod details
kubectl describe pod <pod-name>

# Check service endpoints
kubectl get endpoints

# Check node status
kubectl get nodes -o wide

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🧹 Cleanup

To remove all deployed resources:

```bash
./cleanup.sh
```

To also remove the registry (on master node):

```bash
nerdctl stop local-registry
nerdctl rm local-registry
```

Or manually:

```bash
kubectl delete -f k8s/frontend/
kubectl delete -f k8s/backend/
kubectl delete -f k8s/postgres/
```

## 📊 Resource Requirements

- **PostgreSQL**: 256Mi RAM, 250m CPU, 5Gi storage
- **Backend**: 128Mi RAM, 100m CPU (2 replicas)
- **Frontend**: 64Mi RAM, 50m CPU (2 replicas)

## 🔑 Default Credentials

- **PostgreSQL**:
  - User: `postgres`
  - Password: `password`
  - Database: `counterdb`

> ⚠️ **Security Note**: Change default passwords in production environments!

## 📝 Notes

- All components are configured to run on the `worker1` node using `nodeSelector`
- The application uses persistent storage for PostgreSQL data
- Health checks are configured for all services
- The frontend makes API calls to the backend via the NodePort service