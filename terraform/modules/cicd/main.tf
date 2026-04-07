# ECR: 서비스별 이미지 저장소
resource "aws_ecr_repository" "event_svc" {
  name                 = "ticketing/event-svc"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "ecr-event-svc", Environment = var.env }
}

resource "aws_ecr_repository" "reserv_svc" {
  name                 = "ticketing/reserv-svc"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "ecr-reserv-svc", Environment = var.env }
}

resource "aws_ecr_repository" "worker_svc" {
  name                 = "ticketing/worker-svc"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "ecr-worker-svc", Environment = var.env }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "ticketing/frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "ecr-frontend", Environment = var.env }
}

# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 현재 AWS 계정 정보
data "aws_caller_identity" "current" {}

# GitHub Actions IAM Role
resource "aws_iam_role" "github_actions" {
  name = "ticketing-${var.env}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# GitHub Actions 정책 (CI 전용)
resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}