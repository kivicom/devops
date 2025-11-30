# Фінальний DevOps-проєкт: Django застосунок в AWS

Проєкт розгортає **повноцінне середовище в AWS** для Django-застосунку з використанням:

- **Terraform** (IaC)
- **VPC, EKS, RDS Aurora, ECR**
- **Jenkins** (CI, побудова Docker-образу)
- **Argo CD** (CD, GitOps)
- **Prometheus + Grafana** (моніторинг)

---

## 1. Архітектура

Основні компоненти інфраструктури:

- **VPC** з приватними та публічними підмережами, NAT інстансом та Internet Gateway.
- **EKS кластер** – Kubernetes-кластер для розгортання Django-застосунку.
- **ECR репозиторій** – зберігання Docker-образу застосунку.
- **RDS Aurora PostgreSQL** – база даних для Django.
- **Jenkins** – CI, який будує Docker-образ і пушить його в ECR.
- **Argo CD** – CD, який стежить за Git-репозиторієм та розгортає застосунок у EKS.
- **Prometheus + Grafana** – моніторинг кластера та застосунку.

---

## 2. Структура проєкту

```text
final-project/
├── main.tf               # Головний файл, підключає усі модулі
├── backend.tf            # Налаштування Terraform backend (S3 + DynamoDB)
├── variables.tf          # Оголошення змінних
├── outputs.tf            # Виводи основних ресурсів
├── terraform.tfvars      # Конкретні значення змінних (секрети, імена)
│
├── modules/
│  ├── s3-backend/
│  │  ├── s3.tf           # S3-бакет для Terraform state
│  │  ├── dynamodb.tf     # DynamoDB-таблиця для блокувань стейту
│  │  ├── variables.tf
│  │  └── outputs.tf
│  │
│  ├── vpc/
│  │  ├── vpc.tf          # VPC, підмережі, Internet Gateway
│  │  ├── routes.tf       # Маршрутизація, NAT instance, IAM role
│  │  ├── variables.tf
│  │  └── outputs.tf
│  │
│  ├── ecr/
│  │  ├── ecr.tf          # ECR-репозиторій для образу Django
│  │  ├── variables.tf
│  │  └── outputs.tf
│  │
│  ├── eks/
│  │  ├── eks.tf          # EKS кластер та node group
│  │  ├── aws_ebs_csi_driver.tf  # Додаток EBS CSI driver
│  │  ├── variables.tf
│  │  └── outputs.tf
│  │
│  ├── rds/
│  │  ├── shared.tf       # Спільні ресурси (subnet group, SG)
│  │  ├── aurora.tf       # Aurora PostgreSQL кластер
│  │  ├── rds.tf          # (За потреби) стандартний RDS
│  │  ├── variables.tf
│  │  └── outputs.tf
│  │
│  ├── jenkins/
│  │  ├── jenkins.tf      # Helm release Jenkins, StorageClass, ServiceAccount
│  │  ├── providers.tf    # Kubernetes + Helm провайдери (локальні)
│  │  ├── variables.tf
│  │  ├── values.yaml     # Налаштування Jenkins (admin, plugins, pipeline)
│  │  └── outputs.tf
│  │
│  ├── argo_cd/
│  │  ├── argo_cd.tf      # Helm release Argo CD + Argo Applications
│  │  ├── providers.tf    # Kubernetes + Helm провайдери
│  │  ├── variables.tf
│  │  ├── values.yaml     # Базові налаштування Argo CD
│  │  ├── outputs.tf
│  │  └── charts/         # Helm-чарт для Argo Applications
│  │     ├── Chart.yaml
│  │     ├── values.yaml  # Список applications / repositories
│  │     └── templates/
│  │        ├── application.yaml
│  │        └── repository.yaml
│  │
│  └── monitoring/
│     ├── prometheus.tf   # Helm release kube-prometheus-stack
│     ├── providers.tf
│     └── variables.tf
│
├── charts/
│  └── django-app/
│     ├── templates/
│     │  ├── deployment.yaml   # Deployment Django + контейнер
│     │  ├── service.yaml      # Service для Django
│     │  ├── configmap.yaml    # Налаштування середовища
│     │  └── hpa.yaml          # Horizontal Pod Autoscaler
│     ├── Chart.yaml
│     └── values.yaml          # Значення для чарту
│
└── Django/
   ├── app/               # Код Django-застосунку
   ├── Dockerfile         # Опис Docker-образу
   ├── Jenkinsfile        # CI-пайплайн для Jenkins
   └── docker-compose.yaml
```

---

## 3. Попередні вимоги

Для запуску проєкту потрібні:

- **AWS акаунт** з правами на створення VPC, EKS, RDS, ECR, IAM, S3, DynamoDB, ELB.
- Встановлені інструменти:
  - `terraform` (версія 1.6+)
  - `awscli`
  - `kubectl`
  - `helm`
- Налаштований `aws configure` (Access Key, Secret, region `eu-central-1`).

---

## 4. Налаштування змінних (`terraform.tfvars`)

Конфіденційні дані (паролі, токени, назви бакетів) задаються у файлі `terraform.tfvars`.  
Приклад (скорочено, без реальних секретів):

```hcl
########################
# Налаштування проєкту
########################

name   = "django-app"
region = "eu-central-1"

########################
# Terraform backend
########################

bucket_name = "tfstate-final-igor-kurochkin-20251130-euc1"
table_name  = "terraform-locks-final"

########################
# ECR
########################

repository_name = "dev-lesson-5-ecr"

########################
# GitHub (для Jenkins та Argo CD)
########################

github_repo_url = "https://github.com/kivicom/devops.git"
github_branch   = "final-project"
github_user     = "kivicom"
github_pat      = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # реальний PAT

########################
# RDS / Aurora PostgreSQL
########################

rds_use_aurora          = true
rds_username            = "django_user"
rds_password            = "********"   # задається вручну
rds_database_name       = "django_db"
rds_publicly_accessible = false
rds_multi_az            = true
```

> **Увага:** файл `terraform.tfvars` **не** комітиться в Git, щоб не зберігати секрети у відкритому доступі.

---

## 5. Розгортання інфраструктури

### 5.1. Ініціалізація Terraform

```bash
terraform init
```

### 5.2. Перевірка плану

```bash
terraform plan
```

### 5.3. Створення ресурсів в AWS

```bash
terraform apply
# або
terraform apply -auto-approve
```

Terraform створить:

- VPC, сабнети, NAT інстанс, Internet Gateway
- EKS кластер та node group
- Aurora PostgreSQL кластер
- ECR репозиторій
- S3-бакет та DynamoDB-таблицю для Terraform state
- Jenkins (через Helm)
- Argo CD (через Helm, + Argo Applications)
- kube-prometheus-stack (Prometheus + Grafana)

Після завершення буде виведено `Outputs` з основними параметрами (endpoint EKS, URL ECR, endpoint RDS тощо).

---

## 6. Налаштування доступу до EKS

Оновити `kubeconfig` для EKS-кластера:

```bash
aws eks update-kubeconfig   --region eu-central-1   --name django-app-eks
```

Перевірити, що кластер активний та ноди в статусі `Ready`:

```bash
kubectl get nodes
```

---

## 7. Перевірка компонентів

### 7.1. Jenkins

Перевірити ресурси в namespace `jenkins`:

```bash
kubectl get all -n jenkins
```

Отримати список сервісів:

```bash
kubectl get svc -n jenkins
```

Для локального доступу через port-forward:

```bash
kubectl port-forward svc/jenkins 8080:80 -n jenkins
```

Відкрити в браузері:

```text
http://localhost:8080
```

Облікові дані адміністратора задаються в `modules/jenkins/values.yaml`.  
Також їх можна отримати з секрету (якщо використовується стандартна схема чарта):

```bash
kubectl get secret -n jenkins jenkins   -o jsonpath="{.data.jenkins-admin-password}" | base64 -d ; echo
```

Логін за замовчуванням зазвичай `admin`.

---

### 7.2. Argo CD

Перевірити ресурси в namespace `argocd`:

```bash
kubectl get all -n argocd
kubectl get svc -n argocd
```

Для локального доступу (варіант з port-forward):

```bash
kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd
```

Відкрити в браузері:

```text
https://localhost:8081
```

Отримати пароль адміністратора:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret   -o jsonpath="{.data.password}" | base64 -d ; echo
```

- Логін: `admin`
- Пароль: вивід команди вище.

Список додатків Argo CD:

```bash
kubectl get applications.argoproj.io -n argocd
# або коротко
kubectl get app -n argocd
```

Тут має бути застосунок, який відповідає Helm-чарту `charts/django-app` з цього репозиторію.

---

### 7.3. Prometheus та Grafana

Перевірити ресурси в namespace `monitoring`:

```bash
kubectl get all -n monitoring
kubectl get svc -n monitoring
```

#### Доступ до Grafana

Port-forward:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Відкрити в браузері:

```text
http://localhost:3000
```

**Облікові дані Grafana:**

- Логін: `admin`
- Пароль можна прочитати з секрету:

```bash
kubectl get secret --namespace monitoring kube-prometheus-stack-grafana   -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

У Grafana доступні дашборди для моніторингу:

- стану нод EKS
- подів, namespace-ів
- ресурсів кластера
- метрик застосунку

---

## 8. Розгортання Django-застосунку через Argo CD

Argo CD налаштований на репозиторій:

- `repoURL`: `https://github.com/kivicom/devops.git`
- `targetRevision`: `final-project`
- `path`: `charts/django-app`

Після пушу змін у гілку `final-project` Argo CD:

- оновить Helm-реліз,
- застосує нову версію маніфестів (`deployment`, `service`, `configmap`, `hpa`),
- відобразить стан додатку в UI (Health/Synced).

Основні ресурси Django-застосунку можна подивитись так:

```bash
kubectl get all -n default
```

або, якщо застосунок у окремому namespace – вказати його.

---

## 9. CI/CD пайплайн (Jenkins → ECR → Argo CD)

1. **Jenkins**:
   - зчитує `Jenkinsfile` з директорії `Django/`;
   - будує Docker-образ із `Django/Dockerfile`;
   - пушить образ у `ECR` (`dev-lesson-5-ecr`).

2. **Argo CD**:
   - стежить за Git-репозиторієм (`final-project` гілка);
   - при зміні маніфестів/values оновлює реліз Helm;
   - розгортає нову версію застосунку в EKS.

Таким чином реалізований повний цикл **CI/CD + GitOps**.

---

## 10. Видалення ресурсів (cleanup)

> ⚠️ **Увага:** робота з хмарою може призвести до витрат. Після завершення перевірки обовʼязково видаліть ресурси.

Щоб повністю видалити інфраструктуру, виконайте:

```bash
terraform destroy
# або
terraform destroy -auto-approve
```

> Памʼятайте, що при `terraform destroy` також буде видалено S3-бакет та DynamoDB-таблицю для Terraform state.  
> Якщо потрібен стейт на майбутнє – попередньо збережіть його локально.

---

## 11. Команди для git (перед використанням Argo CD)

Після оновлення проєкту (наприклад, README або Helm-чарту):

```bash
git status
git add README.md
git commit -m "docs: додано README для фінального DevOps-проєкту"
git push origin final-project
```

Після `git push` Argo CD побачить зміни у гілці `final-project` та оновить застосунки згідно GitOps-підходу.
