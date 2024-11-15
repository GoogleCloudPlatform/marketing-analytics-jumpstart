# Marketing Analytics Jumpstart - Installation Guide

## Prerequisites
Make sure you have completed all the steps under the [Prerequisites](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/tree/main/infrastructure#prerequisites) section.

## Choose your primary cloud project for Marketing Analytics Jumpstart
<walkthrough-project-setup></walkthrough-project-setup>

Set the default project id for `gcloud`
```sh
export PROJECT_ID="<walkthrough-project-id/>"
gcloud config set project $PROJECT_ID
```

## Install update uv for running python scripts
Install [uv](https://docs.astral.sh/uv/) that manages the python version and dependecies for the solution.

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH" 
```

Check uv installation
```sh
uv --version
```

## Authenticate with additional OAuth 2.0 scopes
```sh
gcloud auth login
gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/accounts.reauth"
gcloud auth application-default set-quota-project $PROJECT_ID
export GOOGLE_APPLICATION_CREDENTIALS=/Users/<USER_NAME>/.config/gcloud/application_default_credentials.json
```
**Note:** You may receive an error message informing the Cloud Resource Manager API has not been used/enabled for your project, similar to the following: 
ERROR: (gcloud.auth.application-default.login) User [<ldap>@<company>.com] does not have permission to access projects instance [<gcp_project_ID>:testIamPermissions] (or it may not exist): Cloud Resource Manager API has not been used in project <gcp_project_id> before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=<gcp_project_id> then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.
On the next step, the Cloud Resource Manager API will be enabled and, then, your credentials will finally work.

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


## Review your Terraform version
Make sure you have installed terraform version is 1.9.7. We recommend you to use [tfenv](https://github.com/tfutils/tfenv) to manage your terraform version.
`Tfenv` is a version manager inspired by rbenv, a Ruby programming language version manager.
To install `tfenv`, run the following commands:
```sh
# Install via Homebrew or via Arch User Repository (AUR)
# Follow instructions on https://github.com/tfutils/tfenv
# Now, install the recommended terraform version 
tfenv install 1.9.7
tfenv use 1.9.7
terraform --version
```
For instance, the output on MacOS should be like:
```sh
Terraform v1.9.7
on darwin_amd64
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

terraform plan:
```sh
terraform -chdir="${TERRAFORM_RUN_DIR}" plan
```

terraform validate:
```sh
terraform -chdir="${TERRAFORM_RUN_DIR}" validate
```
If you run into errors, review and edit the configurations `${TERRAFORM_RUN_DIR}/terraform.tfvars` file. However, if there are still configurations errors, open a new [github issue](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/issues/).

terraform apply:
```sh
terraform -chdir="${TERRAFORM_RUN_DIR}" apply
```
If you don't have a successful execution of certain resources, re-run `terraform -chdir="${TERRAFORM_RUN_DIR}" apply` a few more times until all is deployed successfully. However, if there are still resources not deployed, open a new [github issue](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/issues/).

## Resources created

At this time, the Terraform scripts in this folder perform the following tasks:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private GitHub repo
- Dataform repository connected to the GitHub repo
- Deploys the marketing data store (MDS), feature store, ML pipelines and activation application

## Next Steps

Follow the [post-installation guide](./POST-INSTALLATION.md) to start you daily operations.

It is recommended to follow the post-installation guide before deploying the Looker Studio Dashboard, because you need the data and predictions tables to exist before consuming insights in your reports.

**The Looker Studio Dashboard deployment is a separate [step](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/python/lookerstudio/README.md).**
