data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = var.ecr_name
  image_tag_mutability = var.mutable

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = var.ecr_name
  }
}

resource "aws_ecr_repository_policy" "allow-account" {
  repository = aws_ecr_repository.this.name
  policy     = jsonencode({
    Version = "2008-10-17",
    Statement = [{
      Sid       = "AllowAccountPullPush",
      Effect    = "Allow",
      Principal = { AWS = data.aws_caller_identity.current.account_id },
      Action    = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ]
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.this.name
  policy     = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Expire untagged images after 30",
      selection = {
        tagStatus   = "untagged",
        countType   = "imageCountMoreThan",
        countNumber = 30
      },
      action = { type = "expire" }
    }]
  })
}
