# Lesson 7 - EKS Kubernetes Cluster with Django Application

This project builds on the ideas from lesson-5 and includes everything needed to deploy:

1. **EKS Kubernetes Cluster**: Managed Kubernetes cluster in its own VPC module
2. **Django Application Deployment**: Helm chart with autoscaling and load balancing
3. **ECR Integration**: ECR repository for storing the Django application image

All required Terraform modules (`s3-backend`, `vpc`, `ecr`, `eks`) находятся внутри `lesson-7`, поэтому проект самодостаточный.

## Prerequisites

- **AWS account** with permissions to create VPC, ECR, EKS, S3 and DynamoDB
- **Terraform**
- **AWS CLI** configured with appropriate credentials (`aws configure` или профиль)
- **kubectl** (Kubernetes CLI)
- **Helm** (Kubernetes package manager)

> При необходимости вы можете переиспользовать те же имена бакета/репозитория, что и в lesson-5, но это не обязательно — конфигурация lesson-7 может работать самостоятельно.

## Usage

### Phase 1: Deploy EKS Infrastructure

1. **Navigate to lesson-7**:

   ```bash
   cd lesson-7
   ```

2. **Initialize Terraform**:

   ```bash
   terraform init
   ```

3. **Review and apply the plan**:

   ```bash
   terraform plan
   terraform apply
   ```

   Это создаст:
   - S3 + DynamoDB для backend’а (через модуль `s3-backend`, если он используется в `main.tf`)
   - VPC и подсети (модуль `vpc`)
   - ECR-репозиторий (модуль `ecr`)
   - EKS-кластер и node group (модуль `eks`)

### Phase 2: Configure kubectl

1. **Update kubeconfig** (используя имя кластера из переменной `cluster_name`, по умолчанию `lesson-7-eks`):

   ```bash
   aws eks update-kubeconfig --region eu-central-1 --name lesson-7-eks
   ```

2. **Verify cluster access**:

   ```bash
   kubectl get nodes
   ```

   Если видите список нод — доступ к кластеру настроен корректно.

### Phase 3: Build & push Django image and deploy via Helm

1. **Build Docker image** (из директории с вашим Django-приложением):

   ```bash
   docker build -t your-django-image:latest .
   ```

2. **Log in to ECR and push image**  
   Получите URL репозитория из Terraform-вывода `ecr_repository_url` или из AWS Console, затем:

   ```bash
   AWS_ACCOUNT_ID=<your_aws_account_id>
   REGION=eu-central-1
   REPO_NAME=<your_ecr_repository_name>   # например, lesson-5-ecr

   aws ecr get-login-password --region $REGION      | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

   docker tag your-django-image:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest
   docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest
   ```

3. **Update image settings in `charts/django-app/values.yaml`**:

   В блоке `image` укажите репозиторий и тег, который вы только что запушили:

   ```yaml
   image:
     repository: "<AWS_ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/<REPOSITORY_NAME>"
     tag: "latest"
   ```

4. **Install or upgrade Helm release**:

   ```bash
   helm upgrade --install django-app ./charts/django-app
   ```

5. **Get LoadBalancer URL**:

   ```bash
   kubectl get service django-app
   ```

   В колонке `EXTERNAL-IP` появится публичный адрес для доступа к приложению.

## Configuration

### EKS Cluster

- **Cluster name**: configurable via `variable "cluster_name"` (default: `lesson-7-eks`)
- **Node group size**: configurable via `node_group_desired_size`, `node_group_min_size`, `node_group_max_size` (по умолчанию — небольшой кластер 2–4 ноды)
- **Network**: VPC и приватные подсети создаются модулем `vpc` в рамках этого проекта

### Django Application (Helm chart)

- **Deployment**:
  - Использует образ из ECR (`image.repository` + `image.tag` из `values.yaml`)
  - Подключает `ConfigMap` через `envFrom.configMapRef` для всех переменных окружения
- **Replicas / Autoscaling**:
  - Минимум 2 реплики (через `replicaCount` / HPA)
  - HPA масштабирует поды от 2 до 6 при загрузке CPU > 70%
- **Service**:
  - Тип `LoadBalancer` для внешнего доступа
- **ConfigMap**:
  - Содержит настройки базы данных и приложения (DB_HOST, DB_USER, DB_NAME, DB_PASSWORD, порты и т.д.), перенесённые из темы 4

## Cleanup

```bash
# Remove Django application
helm uninstall django-app

# Destroy EKS infrastructure
terraform destroy
```

> Обратите внимание: если вы используете общий S3-бакет и DynamoDB-таблицу для backend’а Terraform между разными уроками, прежде чем удалять их, убедитесь, что другие проекты больше не используют этот backend.
