# terraform {
#   backend "s3" {
#     # Назва S3-бакета для збереження Terraform стейту
#     bucket         = "tfstate-final-igor-kurochkin-20251130-euc1"
#
#     # Ключ (шлях) всередині бакета для файлу стейту
#     key            = "final-project/terraform.tfstate"
#
#     # Регіон, де створено S3-бакет
#     region         = "eu-central-1"
#
#     # DynamoDB-таблиця для блокування стейту (lock)
#     dynamodb_table = "terraform-locks-final"
#
#     # Увімкнене шифрування стейту на S3
#     encrypt        = true
#   }
# }
