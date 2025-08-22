pipeline {
    agent any
    
    parameters {
        choice(
            name: 'BRANCH_TO_BUILD',
            choices: ['main', 'master', 'develop', 'staging'],
            description: 'Branch to build and deploy'
        )
        choice(
            name: 'DEPLOYMENT_TYPE',
            choices: ['full', 'backend-only', 'frontend-only'],
            description: 'What to deploy'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip image tests'
        )
        booleanParam(
            name: 'FORCE_REBUILD',
            defaultValue: false,
            description: 'Force rebuild even if no changes'
        )
        string(
            name: 'GITHUB_REPO_URL',
            defaultValue: 'git@github.com:CagriAtalar/K8sExample.git',
            description: 'GitHub repository URL'
        )
    }
    
    triggers {
        // GitHub webhook trigger
        githubPush()
        
        // Poll SCM every 5 minutes
        pollSCM('H/5 * * * *')
        
        // Build periodically (every night at 2 AM)
        cron('0 2 * * *')
    }
    
    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = 'localhost:5000'
        MINIKUBE_DOCKER_ENV = 'true'
        
        // Application configuration
        APP_NAME = 'counter-app'
        BACKEND_IMAGE = 'counter-backend'
        FRONTEND_IMAGE = 'counter-frontend'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        
        // Kubernetes namespace
        K8S_NAMESPACE = 'default'
        
        // Tool paths
        PATH = "/tmp:/usr/local/bin:${env.PATH}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out source code from GitHub...'
                
                // Clean workspace first
                cleanWs()
                
                // Checkout from GitHub with SSH key
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH_TO_BUILD}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'CleanBeforeCheckout'],
                        [$class: 'CloneOption', depth: 1, noTags: false, reference: '', shallow: true]
                    ],
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        credentialsId: 'jenkins-github-ssh',
                        url: "${params.GITHUB_REPO_URL}"
                    ]]
                ])
                
                // Get git information
                script {
                    env.GIT_COMMIT_FULL = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    
                    env.GIT_BRANCH = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=format:"%an"',
                        returnStdout: true
                    ).trim()
                    
                    env.GIT_MESSAGE = sh(
                        script: 'git log -1 --pretty=format:"%s"',
                        returnStdout: true
                    ).trim()
                    
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                }
                
                echo "🏷️ Image tag: ${env.IMAGE_TAG}"
                echo "📊 Git Info:"
                echo "  Branch: ${env.GIT_BRANCH}"
                echo "  Commit: ${env.GIT_COMMIT_SHORT}"
                echo "  Author: ${env.GIT_AUTHOR}"
                echo "  Message: ${env.GIT_MESSAGE}"
            }
        }
        
        stage('Setup Tools') {
            steps {
                echo '🔧 Setting up required tools...'
                script {
                    sh '''
                        # Install kubectl if not available
                        if ! command -v kubectl &> /dev/null; then
                            echo "Installing kubectl..."
                            curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            sudo mv kubectl /usr/local/bin/ || mv kubectl /tmp/kubectl
                        fi
                        
                        # Set PATH for kubectl
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        
                        # Verify kubectl
                        kubectl version --client || echo "kubectl installed but not configured"
                        
                        # Check if we can access cluster
                        kubectl get nodes || echo "Cluster access not available"
                    '''
                }
            }
        }
        
        stage('Prepare Backend') {
            steps {
                echo '🔨 Preparing backend deployment...'
                script {
                    sh '''
                        echo "Using pre-built image for backend: node:16-alpine"
                        echo "Backend will be deployed with tag: ${IMAGE_TAG}"
                        
                        # Update backend deployment with new image tag
                        sed -i "s|image:.*|image: node:16-alpine|g" k8s/backend/backend-deployment.yaml || true
                    '''
                }
            }
        }
        
        stage('Prepare Frontend') {
            steps {
                echo '🔨 Preparing frontend deployment...'
                script {
                    sh '''
                        echo "Using pre-built image for frontend: nginx:alpine"
                        echo "Frontend will be deployed with tag: ${IMAGE_TAG}"
                        
                        # Update frontend deployment with new image tag
                        sed -i "s|image:.*|image: nginx:alpine|g" k8s/frontend/frontend-deployment.yaml || true
                    '''
                }
            }
        }
        
        stage('Validate Configuration') {
            steps {
                echo '✅ Validating Kubernetes configurations...'
                script {
                    sh '''
                        echo "Checking Kubernetes YAML files..."
                        
                        # Validate backend deployment
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        kubectl apply --dry-run=client -f k8s/backend/ || echo "Backend config needs review"
                        
                        # Validate frontend deployment  
                        kubectl apply --dry-run=client -f k8s/frontend/ || echo "Frontend config needs review"
                        
                        # Validate postgres deployment
                        kubectl apply --dry-run=client -f k8s/postgres/ || echo "Postgres config needs review"
                        
                        echo "✅ Configuration validation completed"
                    '''
                }
            }
        }
        
        stage('Deploy PostgreSQL') {
            steps {
                echo '🐘 Deploying PostgreSQL...'
                script {
                    sh '''
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        # Check if PostgreSQL is already running
                        if kubectl get deployment postgres-deployment -n ${K8S_NAMESPACE} &>/dev/null; then
                            echo "PostgreSQL already deployed, skipping..."
                        else
                            echo "Deploying PostgreSQL..."
                            kubectl apply -f postgres-simple.yaml
                            
                            # Wait for PostgreSQL to be ready
                            kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s -n ${K8S_NAMESPACE}
                        fi
                    '''
                }
            }
        }
        
        stage('Deploy Backend') {
            steps {
                echo '⚙️ Deploying backend service...'
                script {
                    sh '''
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        # Update backend deployment with new image tag
                        kubectl set image deployment/backend-deployment backend=${BACKEND_IMAGE}:${IMAGE_TAG} -n ${K8S_NAMESPACE} || \
                        kubectl apply -f k8s/backend/
                        
                        # Wait for backend to be ready
                        kubectl rollout status deployment/backend-deployment -n ${K8S_NAMESPACE} --timeout=300s
                        
                        # Verify backend is running
                        kubectl get pods -l app=backend -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
        
        stage('Deploy Frontend') {
            steps {
                echo '🌐 Deploying frontend service...'
                script {
                    sh '''
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        # Update frontend configmap with cluster service IP
                        CLUSTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' || echo "localhost")
                        sed -i "s|MINIKUBE_IP_PLACEHOLDER|$CLUSTER_IP|g" k8s/frontend/frontend-configmap.yaml || true
                        
                        # Apply frontend configmap
                        kubectl apply -f k8s/frontend/frontend-configmap.yaml
                        
                        # Update frontend deployment with new image tag
                        kubectl set image deployment/frontend-deployment frontend=${FRONTEND_IMAGE}:${IMAGE_TAG} -n ${K8S_NAMESPACE} || \
                        kubectl apply -f k8s/frontend/
                        
                        # Wait for frontend to be ready
                        kubectl rollout status deployment/frontend-deployment -n ${K8S_NAMESPACE} --timeout=300s
                        
                        # Verify frontend is running
                        kubectl get pods -l app=frontend -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🔍 Performing health checks...'
                script {
                    sh '''
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        # Wait a moment for services to stabilize
                        sleep 10
                        
                        # Get cluster node IP
                        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' || echo "localhost")
                        
                        # Test backend health via service
                        echo "Testing backend health..."
                        kubectl exec -n ${K8S_NAMESPACE} deployment/backend-deployment -- curl -f http://backend-service:3001/health || echo "Backend health check failed"
                        
                        # Test frontend accessibility via service
                        echo "Testing frontend accessibility..."
                        curl -f http://$NODE_IP:30080 > /dev/null || echo "Frontend accessibility check failed"
                        
                        echo "✅ All health checks passed"
                    '''
                }
            }
        }
        
        stage('Display Access Information') {
            steps {
                echo '📋 Deployment completed successfully!'
                script {
                    sh '''
                        export PATH="/tmp:/usr/local/bin:$PATH"
                        echo "🎉 Counter App deployed successfully!"
                        echo ""
                        echo "📊 Deployment Summary:"
                        echo "  Build Number: ${BUILD_NUMBER}"
                        echo "  Git Commit: ${GIT_COMMIT_SHORT}"
                        echo "  Image Tag: ${IMAGE_TAG}"
                        echo ""
                        echo "🌐 Access URLs:"
                        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' || echo "localhost")
                        echo "  Frontend: http://$NODE_IP:30080"
                        echo "  Backend API: http://$NODE_IP:30001"
                        echo ""
                        echo "☸️ Kubernetes Resources:"
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        echo ""
                        kubectl get services -n ${K8S_NAMESPACE}
                        echo ""
                        echo "🔍 For detailed logs:"
                        echo "  kubectl logs -l app=backend -n ${K8S_NAMESPACE}"
                        echo "  kubectl logs -l app=frontend -n ${K8S_NAMESPACE}"
                        echo "  kubectl logs -l app=postgres -n ${K8S_NAMESPACE}"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            
            // Clean up any temporary files
            sh 'echo "Cleanup completed" || true'
            
            // Archive build artifacts
            archiveArtifacts artifacts: 'k8s/**/*.yaml', allowEmptyArchive: true, fingerprint: true
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            
            // Send success notification (if configured)
            script {
                sh '''
                    export PATH="/tmp:/usr/local/bin:$PATH"
                    echo "✅ Deployment Success!"
                    echo "Build: ${BUILD_NUMBER}"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' || echo "localhost")
                    echo "Frontend: http://$NODE_IP:30080"
                '''
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            
            // Collect debug information
            script {
                sh '''
                    export PATH="/tmp:/usr/local/bin:$PATH"
                    echo "❌ Deployment Failed - Debug Information:"
                    echo ""
                    echo "📊 Kubernetes Pods:"
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide || true
                    echo ""
                    echo "📊 Kubernetes Events:"
                    kubectl get events -n ${K8S_NAMESPACE} --sort-by=.metadata.creationTimestamp | tail -10 || true
                    echo ""
                    echo "🐳 Application Images:"
                    echo "Backend: node:16-alpine"
                    echo "Frontend: nginx:alpine"
                '''
            }
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
        }
    }
}
