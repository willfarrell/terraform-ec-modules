resource "aws_ecr_repository" "main" {
  name = var.name
  image_tag_mutability = var.mutability

  image_scanning_configuration {
    scan_on_push = var.scanning
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

// In roles module
# This allow a ecs in a sub account to read from ECR
//resource "aws_iam_role" "ecr" {
//  count = length(keys(local.sub_accounts)) : 0
//  name  = "${element(keys(local.sub_accounts), count.index)}-ecr-role"
//
//  assume_role_policy = <<POLICY
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": "sts:AssumeRole",
//      "Principal": {
//        "AWS": "arn:aws:iam::${var.sub_accounts[element(keys(local.sub_accounts), count.index)]}:root"
//      },
//      "Effect": "Allow"
//    }
//  ]
//}
//POLICY
//}
//
//resource "aws_iam_role_policy_attachment" "ecr" {
//  count = length(keys(local.sub_accounts))
//  role = aws_iam_role.ecr.*.name[count.index]
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
//}

# https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicyExamples.html#IAM_allow_other_accounts
# TODO update principal - https://medium.com/miq-tech-and-analytics/cross-account-how-to-access-aws-container-registry-service-from-another-aws-account-using-iam-b372796ede14
resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PullOnly",
            "Effect": "Allow",
            "Principal":{
              "AWS": ${jsonencode(local.allowed_arns)},
              "Service": "lambda.amazonaws.com"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        },
        {
            "Sid": "PushOnly",
            "Effect": "Allow",
            "Principal":{
              "AWS": ${jsonencode(local.allowed_arns)}
            },
            "Action": [
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ]
        },
        {
            "Sid": "Admin",
            "Effect": "Allow",
            "Principal":{
              "AWS": ${jsonencode(local.allowed_arns)}
            },
            "Action": [
                "ecr:*"
            ]
        }
    ]
}
POLICY
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = data.aws_ecr_lifecycle_policy_document.main.json
}

data "aws_ecr_lifecycle_policy_document" "main" {
  rule {
    priority    = 1
    description = "Expire untaggged images older than 1 day"
  
    selection {
      tag_status      = "untagged"
      count_type      = "sinceImagePushed"
      count_unit      = "days"
      count_number    = 1
    }
  }
  rule {
    priority    = 2
    description = "Keep last 25 images"
  
    selection {
      tag_status      = "tagged"
      tag_pattern_list = ["*"]
      count_type      = "imageCountMoreThan"
      count_number    = 25
    }
  }
}

/*
{
    "rulePriority": 2,
    "description": "Keep last 25 images",
    "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 25
    },
    "action": {
        "type": "expire"
    }
}
*/