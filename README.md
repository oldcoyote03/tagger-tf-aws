# tagger-tf-aws

This repository contains Terraform configuration to deploy a Python Flask application (packaged as a Docker image hosted on Docker Hub) to AWS Lambda using the container image packaging.

## Terraform variables (local workflow)

This repository uses local Terraform state by default. To provide variable values for local development, copy `terraform.tfvars.example` to `terraform.tfvars` and edit the values for your environment. Do not commit `terraform.tfvars` if it contains secrets.

Example:

```sh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set docker_image/docker_tag
```

