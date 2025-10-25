# tagger-tf-aws

This repository contains Terraform configuration to deploy a Python Flask application (packaged as a Docker image hosted on Docker Hub) to AWS Lambda using the container image packaging.

## Terraform variables (local workflow)

This repository uses local Terraform state by default. To provide variable values for local development, copy `terraform.tfvars.example` to `terraform.tfvars` and edit the values for your environment. Do not commit `terraform.tfvars` if it contains secrets.

Example:

```sh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set docker_image/docker_tag
```

## CI: build and push wrapper image to ECR

When deploying the wrapper image to Lambda we recommend building the wrapper (adapter + app image) in CI, tagging it with an immutable tag (for example a release number or commit SHA), and pushing to ECR. Replace ACCOUNT and REGION with your AWS account/region.

```sh
export ACCOUNT=123456789012
export REGION=us-east-1
export ECR_REPO=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/flask-api-lambda

# login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

# build with BuildKit so ARG can be used in FROM
DOCKER_BUILDKIT=1 docker build \
	--build-arg ADAPTER_TAG=0.7.1 \
	--build-arg APP_IMAGE=docker.io/yourname/flask-app \
	--build-arg APP_TAG=1.2.3 \
	-t ${ECR_REPO}:1.2.3 .

docker push ${ECR_REPO}:1.2.3
```

Notes:
- Use an immutable tag (not `:latest`) in Terraform when referencing the image (see examples/ecr-deploy.tf).
- If the app image on Docker Hub is private, ensure CI can pull it (or mirror it to ECR before building the wrapper).

Recommended CI workflow (create repo → push image → deploy)
----------------------------------------------------------
For a smooth, automated deployment where Terraform owns the ECR repository, follow a three-step CI flow so CI can push the wrapper image into the repo Terraform creates:

1) Create the ECR repository (only the repo):

```sh
terraform init
terraform apply -target=aws_ecr_repository.flask_lambda_repo -auto-approve
```

2) Build and push the wrapper image to the created repo (use the pushed tag in step 3):

```sh
# (same build/push snippet above, make sure ECR_REPO matches the created repo)
DOCKER_BUILDKIT=1 docker build \
	--build-arg ADAPTER_TAG=0.7.1 \
	--build-arg APP_IMAGE=docker.io/yourname/flask-app \
	--build-arg APP_TAG=1.2.3 \
	-t ${ECR_REPO}:1.2.3 .
docker push ${ECR_REPO}:1.2.3
```

3) Deploy the Lambda using the pushed, immutable tag:

```sh
terraform apply -var="docker_tag=1.2.3" -auto-approve
```

This ensures the repo exists before CI attempts to push an image and that Terraform deploys a pinned wrapper image tag.

# Optional: ECR configuration (use when building/pushing wrapper image to ECR)
# If you centralize ECR config in terraform variables, CI can construct the full ECR repo URL from these values.
# ecr_account   = "123456789012"
# ecr_region    = "us-east-1"  # removed: examples now use var.aws_region by default
# ecr_repo_name = "flask-api-lambda"

