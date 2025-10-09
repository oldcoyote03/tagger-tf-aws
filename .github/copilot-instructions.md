<!-- .github/copilot-instructions.md - repo-specific instructions for AI coding agents -->
# Repository-specific Copilot instructions — tagger-tf-aws

This repo contains Terraform code and deployment artifacts to package and deploy a Python Flask application to AWS Lambda as a container image (hosted on Docker Hub). The repo is small and may rely on external images and infra state that are not checked in. Use these notes to be productive and avoid guessing.

Key facts (from repo + user):
- The application is a Python Flask app packaged as a Docker image and pushed to Docker Hub.
- Terraform is used to deploy the container image to AWS Lambda (container image support).
- Credentials, Docker image tags, and Terraform state are not present in the repo and must be provided by a human operator.

Clarification: the Docker image is already built and hosted on Docker Hub. This repository's Terraform should reference and pull that remote image (for example, `docker.io/<user>/<repo>:<tag>`). The repo does not need to build the image locally unless the maintainer asks for that flow.

What to do first (high-value steps):
1. Look for Terraform (*.tf) files in the workspace. If no `Dockerfile` exists (likely, because the image is prebuilt), confirm the Terraform module path and the exact Docker Hub image name/tag the Terraform should reference.
2. Ask for the Docker Hub image full name (example: `dockerhub-user/myapp:1.2.3`) and the AWS account/region where resources should be created.
3. Do not attempt to create or use real AWS credentials. Provide reproducible local commands the maintainer can run.

Concrete patterns and file references:
- If a `Dockerfile` exists: expect the image to expose the Flask app on the container port (commonly 8080 or 5000). Confirm the port by scanning the `EXPOSE` instruction or Flask `app.run()` call in the code.
- Terraform: container-based Lambda deployments typically use `aws_lambda_function` with `package_type = "Image"` and `image_uri` pointing to an ECR or Docker image. If the repo uses ECR, expect `aws_ecr_repository` + `aws_ecr_lifecycle_policy` resources; for Docker Hub the `image_uri` will be `docker.io/<user>/<repo>:<tag>`.
-- Note: because the image is prebuilt and hosted on Docker Hub, prefer documenting the image URI in Terraform variables (for example `docker_image = "dockerhub-user/myapp"` and `docker_tag = "TAG"`). Only include local build/push steps if the maintainer asks to switch workflows.

Repository variable names:
- This project declares `variable "docker_image"` and `variable "docker_tag"` in `variables.tf`. Use `${var.docker_image}:${var.docker_tag}` when referencing the full image in Terraform resources (for example `image_uri = "${var.docker_image}:${var.docker_tag}"`).

Testing and debugging tips specific to this repo:
- Run the Flask image locally (optional) to validate behavior before deployment (if you want to pull the image locally first):

```sh
docker pull dockerhub-user/myapp:TAG
docker run -p 8080:8080 dockerhub-user/myapp:TAG
curl http://localhost:8080/health
```

- If Terraform files are present and configured for Lambda container images, use `terraform init` then `terraform plan` (no `apply`) and show the plan output to the maintainer before any changes. Ensure `image_uri` or equivalent Terraform variable points at the Docker Hub image (e.g. `docker.io/user/repo:tag`) so Terraform will pull the prebuilt image rather than attempting to build locally.

Quick terraform examples (explicit):
```sh
terraform init
terraform plan -var-file=terraform.tfvars
# or pass variables directly:
terraform plan -var="docker_image=docker.io/user/repo" -var="docker_tag=1.2.3"
```

Conventions and choices to respect:
- Keep secrets out of the repo. Expect the maintainer to provide AWS credentials, Docker credentials, and the Terraform backend configuration (S3 bucket/key) externally.
- Prefer minimally invasive changes: propose edits and show diffs rather than applying unknown infra changes.

Terraform state and backends:
- By default this repository uses a local Terraform state for testing and development (no S3 backend). If you later want to centralize state, you can configure an S3 backend; ask me and I can show the minimal backend snippet and an example `terraform.tfvars.example`.

AWS credentials and environment variables:
- This project expects AWS credentials to be provided via environment variables instead of storing them in the repo. The three variables used are:
	- `AWS_ACCESS_KEY_ID`
	- `AWS_SECRET_ACCESS_KEY`
	- `AWS_DEFAULT_REGION`

Example (do not commit these values):

```sh
export AWS_ACCESS_KEY_ID=AKIA...REPLACE_ME
export AWS_SECRET_ACCESS_KEY=abcd...REPLACE_ME
export AWS_DEFAULT_REGION=us-west-2
```

Helpful examples to include in PRs or suggestions:
- A `terraform.tfvars.example` showing variables required: `aws_region`, `docker_image`, `docker_tag`, and `state_bucket`.
- A `terraform.tfvars.example` showing variables required: `aws_region`, `docker_image`, `docker_tag`. If using an S3 backend, include `state_bucket` and backend config separately.
- A short `Makefile` with targets: `build`, `push`, `tf-init`, `tf-plan`.

If something is missing, ask these exact questions:
1. What is the Docker Hub image full name (including tag)?
2. Do you use an S3 backend for Terraform state? If yes, provide the backend config or confirm you want a local state for testing.
3. Which AWS region and account should the example Terraform target? (used only for examples; no credentials will be created)

When editing code, prefer small, focused changes with tests or a clear manual test sequence. Avoid adding real secrets or performing any network calls without user approval.

Sensitive variables and secrets:
- Mark secret variables with `sensitive = true` in `variables.tf` and avoid committing their values in `terraform.tfvars`. For production secrets prefer using `TF_VAR_<name>` environment variables or a secrets manager.

How to request persistent edits to this file:
- If you supply new assumptions in chat (for example, a concrete Docker image URI), I'll use them for guidance immediately but I will not persist them to this file without your confirmation. Ask me to "propose edit" to see a diff, then reply "apply" to commit the change.

End of instructions.
