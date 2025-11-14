# lesson-5 — Terraform (S3 backend, VPC, ECR) — eu-central-1 (Frankfurt)

## Структура
```
lesson-5/
├── backend.tf
├── main.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ecr/
│       ├── ecr.tf
│       ├── variables.tf
│       └── outputs.tf
```

## Используемые значения
- **Region:** `eu-central-1`
- **S3 bucket (state):** `tfstate-lesson5-igor-kurochkin-20251114-euc1`
- **DynamoDB table (locks):** `terraform-locks`
- **VPC Name (tag):** `dev-lesson-5-vpc`
- **ECR repo name:** `dev-lesson-5-ecr`

## Предусловия
- Terraform ≥ 1.6
- AWS CLI настроен и авторизован
- Права на S3, DynamoDB, VPC, ECR в `eu-central-1`

## Быстрый старт (bootstrap → backend → инфраструктура)
> Все команды выполнять **в папке `lesson-5/`**.

### 1) Bootstrap: создать S3 и DynamoDB локальным стейтом
```bash
mv backend.tf backend.off  # если файла нет — пропусти
terraform init -backend=false -reconfigure
terraform apply -target=module.s3_backend -auto-approve
```

### 2) Подключить S3-backend и мигрировать state
```bash
mv backend.off backend.tf
terraform init -migrate-state   # ответь: yes
```

### 3) Развернуть остальную инфраструктуру (VPC + ECR)
```bash
terraform plan
terraform apply -auto-approve
```

## Проверка (CLI)
```bash
export AWS_REGION=eu-central-1
export AWS_DEFAULT_REGION=eu-central-1

terraform output

aws s3api head-bucket --bucket tfstate-lesson5-igor-kurochkin-20251114-euc1
aws dynamodb describe-table --table-name terraform-locks --region eu-central-1 --query "Table.TableStatus"
aws ec2 describe-vpcs --region eu-central-1 --filters "Name=tag:Name,Values=dev-lesson-5-vpc" --query "Vpcs[0].{VpcId:VpcId,Cidr:CidrBlock}"
aws ecr describe-repositories --region eu-central-1 --repository-names dev-lesson-5-ecr --query "repositories[0].{Name:repositoryName,Url:repositoryUri}"
```

## Тест push образа в ECR (опционально)
```bash
REPO_URI=$(aws ecr describe-repositories --region eu-central-1 --repository-names dev-lesson-5-ecr --query "repositories[0].repositoryUri" --output text)
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin "$(echo "$REPO_URI" | cut -d/ -f1)"
docker pull hello-world
docker tag hello-world:latest "$REPO_URI:hello"
docker push "$REPO_URI:hello"
aws ecr list-images --region eu-central-1 --repository-name dev-lesson-5-ecr --query "imageIds[].imageTag"
```

## Уничтожение ресурсов
```bash
terraform destroy
```
> Бекенд-ресурсы (S3/DynamoDB) защищены `prevent_destroy = true`. Чтобы удалить их, временно снимите флаг в `modules/s3-backend`, примените изменения и затем выполните `destroy`.

## Git
Коммитить:
- `backend.tf`, `main.tf`, `outputs.tf`, папку `modules/`, `README.md`, `.terraform.lock.hcl`

`.gitignore`:
```
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.tfvars
*.tfvars.json
.terraformrc
terraform.rc
.DS_Store
```
