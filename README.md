# terraform-github

## Overview

This repository is for deploying repositories to GitHub using Terraform and GitHub Actions.

## Deployment Flow

1. A GitHub Actions workflow is triggered (e.g., when a pull request is merged).
2. The [`set-matrix`](.github/actions/set-matrix/action.yml) action is executed to create a list of directories for Terraform execution.
3. The [`setup-terraform`](.github/actions/setup-terraform/action.yml) action is executed to set up Terraform.
4. The [`terraform-plan`](.github/actions/terraform-plan/action.yml) action is executed to create a Terraform plan.
5. The [`terraform-apply`](.github/actions/terraform-apply/action.yml) action is executed to apply the Terraform plan.

```mermaid
graph LR
  A[GitHub Actions Trigger] --> B[setup-terraform]
  B --> C[terraform-plan]
  C --> D[terraform-apply]
  D --> E[Infrastructure is deployed]
  E --> F[Changes are reflected in the GitHub repository]
