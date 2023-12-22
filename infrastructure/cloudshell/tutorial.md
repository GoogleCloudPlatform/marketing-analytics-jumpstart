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
Verify poetry is properly installed, run:
```sh
poetry --version
```
Install python dependencies, run:
```sh
poetry install
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

## Create Looker Studio Dashboard
Extract the URL used to create the dashboard from the Terraform output value:
```sh
echo "$(terraform -chdir=${TERRAFORM_RUN_DIR} output -raw lookerstudio_create_dashboard_url)"
```
1. Click on the long URL from the command output. This will take you to the copy dashboard flow in Looker Studio.
1. The copy may take a few moments to execute. If it does not, close the tab and try clicking the link again.
1. Click on the button `Edit and share` to follow through and finish the copy process.
