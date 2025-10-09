variable "docker_image" {
  type        = string
  description = "Docker image repository (including registry and repo, without tag) e.g. docker.io/user/repo"
}

variable "docker_tag" {
  type        = string
  description = "Docker image tag"
  default     = "latest"
}
