# 🚀 Jenkins Pipeline Setup Guide

Bu guide Jenkins'te Counter App için pipeline job oluşturmayı açıklar.

## 📋 Pipeline Job Oluşturma

### 1. Jenkins'e Giriş Yap
- URL: `http://172.27.108.39:9090`
- Username: `admin`
- Password: `6e6a4e6fd80b4fa9b804bd6ee5fae7fe`

### 2. New Job Oluştur
1. **New Item** tıkla
2. **Item name**: `counter-app-pipeline`
3. **Pipeline** seç
4. **OK** tıkla

### 3. Pipeline Configuration

#### General Settings
- **Description**: `Counter App Build and Deploy Pipeline`
- **GitHub project**: GitHub repo URL'ini ekle (opsiyonel)

#### Build Triggers
- ☑️ **GitHub hook trigger for GITScm polling** (GitHub webhook için)
- ☑️ **Poll SCM**: `H/5 * * * *` (5 dakikada bir kontrol et)

#### Pipeline
- **Definition**: `Pipeline script from SCM`
- **SCM**: `Git`
- **Repository URL**: `git@github.com:YOUR_USERNAME/YOUR_REPO.git`
- **Credentials**: `jenkins-github-ssh` (daha önce oluşturduğun SSH key)
- **Branch**: `*/main` veya `*/master`
- **Script Path**: `Jenkinsfile`

### 4. Save ve Build

**Save** tıkla ve **Build Now** ile ilk build'i başlat!

## 🔧 Pipeline Özellikleri

### Stage'ler
1. **Checkout** - GitHub'dan kod çekme
2. **Setup Minikube Docker Environment** - Docker ortamı hazırlama
3. **Build Backend** - Backend Docker image oluşturma
4. **Build Frontend** - Frontend Docker image oluşturma
5. **Test Images** - Image'ları test etme
6. **Deploy PostgreSQL** - PostgreSQL deploy etme
7. **Deploy Backend** - Backend deploy etme
8. **Deploy Frontend** - Frontend deploy etme
9. **Health Check** - Servis sağlık kontrolü
10. **Display Access Information** - Erişim bilgilerini gösterme

### Environment Variables
- `BACKEND_IMAGE`: counter-backend
- `FRONTEND_IMAGE`: counter-frontend
- `K8S_NAMESPACE`: default
- `IMAGE_TAG`: ${BUILD_NUMBER}-${GIT_COMMIT_SHORT}

### Automatic Features
- ✅ **Minikube Docker environment** otomatik setup
- ✅ **Image tagging** build number + git commit ile
- ✅ **Health checks** deploy sonrası
- ✅ **Rollback support** deployment hatası durumunda
- ✅ **Access URLs** build sonrası gösterme
- ✅ **Debug information** hata durumunda

## 🌐 Build Sonrası Erişim

Pipeline başarıyla tamamlandıktan sonra:

### Frontend
```
http://$(minikube ip):30080
```

### Backend API
```
http://$(minikube ip):30001
```

### Jenkins Console Output
Build detayları ve erişim bilgileri console output'ta görünecek.

## 🐛 Troubleshooting

### Pipeline Hataları
1. **Docker build fails**: 
   - Docker daemon'un çalıştığını kontrol et
   - `eval $(minikube docker-env)` komutunun çalıştığını kontrol et

2. **Kubernetes deploy fails**:
   - `kubectl` komutunun erişilebilir olduğunu kontrol et
   - Minikube'un çalıştığını kontrol et

3. **SSH key errors**:
   - GitHub'da public key'in ekli olduğunu kontrol et
   - Jenkins'te SSH credential'ın doğru oluşturulduğunu kontrol et

### Useful Commands
```bash
# Minikube status kontrol
minikube status

# Pipeline debug için
kubectl get pods -n default
kubectl logs -l app=backend
kubectl logs -l app=frontend

# Jenkins logs
kubectl logs -n jenkins deployment/jenkins
```

## 📝 Pipeline Customization

### Image Tag'leri Değiştirme
Jenkinsfile'da `IMAGE_TAG` environment variable'ını değiştirebilirsin:

```groovy
env.IMAGE_TAG = "v${env.BUILD_NUMBER}"  // Sadece build number
env.IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"  // Branch + build
```

### Namespace Değiştirme
Farklı namespace kullanmak için:

```groovy
environment {
    K8S_NAMESPACE = 'production'  // veya 'staging'
}
```

### Health Check Timeout'ları
Deploy timeout'larını ayarlamak için:

```bash
kubectl rollout status deployment/backend-deployment --timeout=600s  # 10 dakika
```

Bu pipeline Counter App'inizi GitHub'dan otomatik olarak build edip Minikube'a deploy edecek! 🚀
