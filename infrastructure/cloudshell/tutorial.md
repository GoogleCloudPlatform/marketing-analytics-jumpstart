# Marketing Analytics Jumpstart - Installation Guide

## Prerequisites
Make sure you have completed all the steps under the [Prerequisites](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/tree/main/infrastructure#prerequisites) section.

## Choose your primary cloud project for MAJ
<walkthrough-project-setup></walkthrough-project-setup>

Set the default project id for `gcloud`
```sh
export PROJECT_ID="<walkthrough-project-id/>"
gcloud config set project $PROJECT_ID
```

## Install Poetry
```sh
curl -sSL https://install.python-poetry.org | python3 -
```
Add poetry to PATH
```sh
export PATH="$HOME/.local/bin:$PATH"
```
Verify poestry is properly installed, run:
```sh
poetry --version
```

## Set environment variables
Run the set variable script and follow the steps to provide value for every variable:
```sh
. scripts/set-env.sh
```

## Create the Terraform variables file

```sh
envsubst < "${SOURCE_ROOT}/infrastructure/cloudshell/terraform-template.tfvars" > "${TERRAFORM_RUN_DIR}/terraform.tfvars"
```
Provide value for the `dataform_github_token` variable in the generated 
<walkthrough-editor-open-file filePath="infrastructure/terraform/terraform.tfvars">terraform.tfvars file</walkthrough-editor-open-file>

## Authenticate with additional OAuth 2.0 scopes
```sh
. scripts/common.sh;set_application_default_credentials $(pwd);set +o nounset;set +o errexit
```

## Create Terraform remote backend
```sh
SOURCE_ROOT=$(pwd)
scripts/generate-tf-backend.sh
```
<walkthrough-editor-open-file filePath="infrastructure/terraform/backend.tf">Check the generated Terraform backend config file</walkthrough-editor-open-file>

## Run Terraform to install MAJ
terraform init:
```sh
terraform -chdir="${TERRAFORM_RUN_DIR}" init
```

terraform apply:
```sh
terraform -chdir="${TERRAFORM_RUN_DIR}" apply
```
