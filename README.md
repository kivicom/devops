# DevOps Lesson 8–9 — CI/CD with Jenkins, Terraform, Helm & Argo CD

Цей репозиторій містить інфраструктуру та Helm-чарти для побудови повного CI/CD-конвеєра:

- **Terraform** — створює VPC, EKS, ECR, S3 backend, DynamoDB, Jenkins, Argo CD.
- **Helm** — деплой Django‑застосунку та Argo CD Application.
- **Jenkins** — збірка Docker‑образу Django, пуш в ECR, оновлення Helm‑чарту.
- **Argo CD** — GitOps, автоматична синхронізація застосунку в кластері після змін у Git.

Гілка для цього домашнього завдання: **`lesson-8-9`**.

---

## 1. Як застосувати Terraform

### 1.1. Передумови

1. **AWS облікові дані** в оточенні (наприклад, через `aws configure`):
   - користувацький профіль з правами на S3, DynamoDB, VPC, EKS, ECR, IAM, ELB.
2. Встановлені:
   - `terraform` (версія 1.6+),
   - `awscli`,
   - `kubectl`,
   - `helm`.

Регіон використовується: **`eu-central-1`**.

### 1.2. Ініціалізація та план

```bash
git clone https://github.com/kivicom/devops.git
cd devops
git checkout lesson-8-9

terraform init
terraform plan
```

Terraform:

- створить **S3‑bucket** та **DynamoDB** для бекенду стейтів (`modules/s3-backend`),
- підніме **VPC** з публічними та приватними підмережами (`modules/vpc`),
- створить **ECR‑репозиторій** (`modules/ecr`),
- підніме **EKS‑кластер** та node group (`modules/eks`),
- встановить **Jenkins** через Helm (`modules/jenkins`),
- встановить **Argo CD** через Helm і налаштує GitOps‑додаток (`modules/argo_cd`).

### 1.3. Застосування

```bash
terraform apply
```

Після завершення ви отримаєте outputs, зокрема:

- `cluster_name` — ім'я EKS‑кластера (`lesson-7-eks`),
- `cluster_endpoint` — URL API сервера Kubernetes,
- `ecr_repository_url` — URL ECR‑репозиторію.

### 1.4. Налаштування `kubectl`

Після `terraform apply`:

```bash
aws eks update-kubeconfig   --name lesson-7-eks   --region eu-central-1

kubectl get nodes
```

Якщо ноди в статусі `Ready` — кластер працює.

---

## 2. Як перевірити Jenkins job

### 2.1. Доступ до Jenkins

Jenkins встановлено в неймспейсі **`jenkins`** через Helm‑реліз `jenkins`.

Перевірити сервіс:

```bash
kubectl get svc -n jenkins
```

Шукайте сервіс типу **`LoadBalancer`**, наприклад:

```text
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
jenkins   LoadBalancer   10.0.x.x        a.b.c.d         8080:xxxx/TCP
```

Відкрийте в браузері:

```text
http://<EXTERNAL-IP>:8080
```

За замовчуванням (див. `modules/jenkins/values.yaml`):

- **login**: `admin`
- **password**: `admin123`

### 2.2. Підготовка Jenkins до роботи з репозиторіями

У Jenkins потрібно:

1. Додати **SSH‑ключ** до GitHub:
   - `Manage Jenkins` → `Credentials` → `System` → `Global credentials` → `Add Credentials`,
   - тип: *SSH Username with private key*,
   - ID, наприклад: `git-ssh-key`.

2. (Опційно) Додати AWS‑креденшели, якщо вони потрібні всередині джоби.

### 2.3. Pipeline / Jenkinsfile

**Jenkinsfile** знаходиться в репозиторії з Django‑застосунком (окремий репозиторій).  
Pipeline виконує:

1. Checkout коду Django.
2. Збірку Docker‑образу з `Dockerfile`.
3. Пуш образу в **ECR**:
   - репозиторій: `dev-lesson-5-ecr` у регіоні `eu-central-1`,
   - повний URL використовує `ecr_repository_url` з outputs Terraform.
4. Клонування цього GitOps‑репозиторію (**`kivicom/devops`**, гілка `lesson-8-9`).
5. Оновлення тегу образу в `charts/django-app/values.yaml`:
   - поле `image.tag` змінюється на новий тег (наприклад, номер білда Jenkins).
6. Коміт з повідомленням на кшталт:
   - `chore: bump django image tag to <TAG>`
7. Пуш змін у Git (`lesson-8-9` або `main` — залежно від налаштування GitOps).

### 2.4. Створення pipeline в Jenkins

1. Відкрити Jenkins → `New Item`.
2. Обрати тип **Pipeline**, назвати наприклад `django-app-ci`.
3. У розділі **Pipeline**:
   - обрати `Pipeline script from SCM`,
   - `SCM: Git`,
   - вказати URL репозиторію Django‑застосунку,
   - вибрати гілку з `Jenkinsfile`.
4. Зберегти й запустити `Build Now`.

Якщо все налаштовано коректно, білд має:

- зібрати та запушити Docker‑образ у ECR,
- оновити `charts/django-app/values.yaml` у цьому репозиторії,
- запушити коміт у Git.

---

## 3. Як побачити результат в Argo CD

### 3.1. Доступ до Argo CD

Argo CD встановлено в неймспейсі **`argocd`**.

Перевірка сервісу:

```bash
kubectl get svc -n argocd
```

Шукаємо сервіс `argocd-server` типу `LoadBalancer`. Відкриваємо:

```text
http://<EXTERNAL-IP>
```

### 3.2. Початковий пароль admin

Початковий пароль зберігається в secret `argocd-initial-admin-secret`:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo
```

Login: `admin`  
Password: значення з команди вище.

(Пароль можна змінити через UI або CLI Argo CD.)

### 3.3. Argo CD Application

Модуль `modules/argo_cd`:

- ставить Argo CD через Helm‑реліз `argo-cd`,
- деплоїть Helm‑чарт `argo-apps` (локальний в `modules/argo_cd/charts`), який створює:
  - **Repository** — посилання на Git‑репозиторій `https://github.com/kivicom/devops.git`,
  - **Application** — для Helm‑чарту `charts/django-app`.

Application налаштовано на:

- `repoURL`: `https://github.com/kivicom/devops.git`,
- `path`: `charts/django-app`,
- `targetRevision`: **`lesson-8-9`** (або `main`, залежно від змінної `apps_target_rev`),
- `destination.namespace`: `default`,
- `syncPolicy.automated` з `prune: true`, `selfHeal: true`.

### 3.4. Перевірка синхронізації

1. Залогінитись в Argo CD UI.
2. В розділі **Applications** знайти застосунок `django-app`.
3. Перевірити:
   - статус **`Synced`** / **`Healthy`**,
   - посилання на репозиторій та гілку (`targetRevision`),
   - історію ревізій (коміти з оновленням `image.tag`).

### 3.5. Повний потік CI/CD

1. Розробник пушить зміни в репозиторій Django‑застосунку.
2. **Jenkins**:
   - тригериться по вебхуку/налаштуванню,
   - збирає Docker‑образ, пушить у **ECR**,
   - оновлює `image.tag` в `charts/django-app/values.yaml` у цьому репозиторії,
   - пушить новий коміт у гілку `lesson-8-9`.
3. **Argo CD**:
   - виявляє новий коміт,
   - автоматично оновлює реліз Helm‑чарту `django-app` в кластері,
   - деплой нового образу з оновленим тегом.

Результат:

- Новий код Django → новий Docker‑образ в ECR → оновлений Helm‑чарт → автоматичний деплой у кластер без ручного втручання.

---

## 4. Структура проєкту (скорочено)

```text
.
├── backend.tf
├── main.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   ├── eks/
│   ├── jenkins/
│   │   ├── jenkins.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── values.yaml
│   │   └── outputs.tf
│   └── argo_cd/
│       ├── argo_cd.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── values.yaml
│       ├── outputs.tf
│       └── charts/
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

Цей README описує всі кроки, необхідні для перевірки ДЗ:

- як застосувати Terraform,
- як перевірити Jenkins job,
- як побачити результат в Argo CD та повний потік CI/CD.
