provider "aws" {
  region = var.aws_region
}

# --- ECR Repository ---
resource "aws_ecr_repository" "flask_lambda_repo" {
  name = var.ecr_repo_name
}

# lifecycle policy to retain 10 untagged images and 30 tagged images by count
resource "aws_ecr_lifecycle_policy" "retain_recent" {
  repository = aws_ecr_repository.flask_lambda_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep 30 most recent tagged images"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = [""]
          countType = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep 10 most recent untagged images"
        selection = {
          tagStatus = "untagged"
          countType = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "ecr_repo_url" {
  value = aws_ecr_repository.flask_lambda_repo.repository_url
}

# --- IAM Role for Lambda ---
resource "aws_iam_role" "lambda_role" {
  name = "flask_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Lambda Function ---
resource "aws_lambda_function" "flask_lambda" {
  function_name = "flask-web-adapter-app"
  package_type  = "Image"

  # Use a pinned tag passed via var.docker_tag (avoid :latest)
  image_uri     = "${aws_ecr_repository.flask_lambda_repo.repository_url}:${var.docker_tag}"

  role          = aws_iam_role.lambda_role.arn
  timeout       = 10
  memory_size   = 512

  environment {
    variables = {
      ADAPTER_PORT      = tostring(var.adapter_port)
      ADAPTER_LOG_LEVEL = var.adapter_log_level
      APP_ENV           = var.app_env
    }
  }
}

# --- Optional Function URL ---
resource "aws_lambda_function_url" "flask_url" {
  function_name      = aws_lambda_function.flask_lambda.function_name
  authorization_type = "NONE"
}

output "lambda_function_url" {
  value = aws_lambda_function_url.flask_url.function_url
}

# Convenience output: computed ECR repo URL from variables if user provided ecr_account
# If ecr_account is set in tfvars, CI can construct a full repo URI using this pattern (uses var.aws_region).
output "ecr_repo_url_from_vars" {
  value = var.ecr_account != "" ? "${var.ecr_account}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}" : aws_ecr_repository.flask_lambda_repo.repository_url
}
