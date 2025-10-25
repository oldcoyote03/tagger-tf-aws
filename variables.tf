variable "docker_image" {
  type        = string
  description = "Docker image repository (including registry and repo, without tag) e.g. docker.io/user/repo"
}

variable "docker_tag" {
  type        = string
  description = "Docker image tag"
  default     = "latest"
}

variable "adapter_port" {
  type        = number
  description = "Port the Lambda Web Adapter will forward to the app (common default: 8080)"
  default     = 8080
}

variable "adapter_log_level" {
  type        = string
  description = "Log level for the adapter/app (example: info, debug)"
  default     = "info"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "app_env" {
  type        = string
  description = "Application environment (for example: production, staging)"
  default     = "production"
}

variable "ecr_account" {
  type        = string
  description = "(Optional) AWS account ID where the ECR repo will live. If empty, use the AWS credentials/account in use. Example: 123456789012"
  default     = ""
}

variable "ecr_repo_name" {
  type        = string
  description = "The name of the ECR repository to create/use for the wrapper image. Example: flask-api-lambda"
  default     = "flask-api-lambda"
}
