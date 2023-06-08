# Terraform Scripts

The Terraform scripts in this folder create the infrastructure to start data ingestion
into BigQuery, create feature store, ML pipelines and Dataflow activation pipeline.

## Prerequisites

Make sure the prerequisites listed in the [parent README](../README.md) are met. You can run the script
from [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shelld.google.com/shell/docs/using-cloud-shell)
or a Linux machine or a Mac with `gcloud` command installed. The instructions provided are for the Cloud Shell
installation.

## Installation Guide

### Initial Environment Setup

1. Clone the source code repository:

    ```bash
    REPO="marketing-data-engine"
    cd $HOME
    git clone https://github.com/GoogleCloudPlatform/${REPO}.git
    ```

1. If you don't use Cloud Shell, export environment variables and set the default project.
   Typically, there is a single project to install the solution. If you chose to use multiple projects - use the one
   designated for the data processing.

    ```bash
    export PROJECT_ID="[your Google Cloud project id]"
    gcloud config set project $PROJECT_ID
    gcloud auth application-default login
    ```

1. Install Python's Poetry

   [Poetry](https://python-poetry.org/docs/) is a Python's tool for dependency management and packaging.

   If you are installing on in Cloud Shell use the following commands:
   ```bash
     curl -sSL https://install.python-poetry.org | python3 -
   ```
   Verify that `poetry` is on your $PATH variable:
   ```shell
   poetry --version
   ```
   If it fails - add it to your $PATH variable:
   ```shell
   export PATH="$HOME/.local/bin:$PATH" 
   ```

   If you are installing on a Mac:
   ```shell
   brew install poetry
   ```

1. Google Analytics configurations

   Set environment variables with you Google Analytics account details:
   Follow this [instruction](https://developers.google.com/analytics/devguides/reporting/data/v1/property-id#google_analytics) to determine your Google Analytics 4 property Id, and this [instruction](https://support.google.com/analytics/answer/12332343?hl=en) to determine your Google Analytics 4 data stream Id.
   ```shell
   export GA4_PROPERTY_ID="[your Google Analytics property id]"
   export GA4_STREAM_ID="[your Google Analytics data stream id]"
   ```

   Authenticate with additional OAuth 2.0 scopes needed to call Google Analytics Admin API:
   ```shell
   gcloud auth application-default login --quiet --scopes="https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.manage.users,https://www.googleapis.com/auth/analytics.manage.users.readonly,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/analytics.user.deletion"
   ```

1. Run the following script to create a Terraform backend.

    ```bash
    SOURCE_ROOT=${HOME}/${REPO}
    cd ${SOURCE_ROOT}
    scripts/generate-tf-backend.sh
    ```

   **Note:** Make sure you provide access to the BigQuery dataset where your GA4 and GAds exported data is located.

1. Create the Terraform variables file by making a copy from the template and set the Terraform variables.
   Most of the parameters are based on the pre-requisites described [here](../README.md).
   The [sample file](terraform-sample.tfvars) has all the required variables listed.

    ```bash
    TERRAFORM_RUN_DIR=${SOURCE_ROOT}/infrastructure/terraform
    cp ${TERRAFORM_RUN_DIR}/terraform-sample.tfvars ${TERRAFORM_RUN_DIR}/terraform.tfvars
   ```

   Edit the variables file. If using Vim:
   ```shell
    vim ${TERRAFORM_RUN_DIR}/terraform.tfvars
    ```

1. Run Terraform to create resources:

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" init
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply
    ```

   If you don't have a successful execution from the beginning, re-run until all is deployed successfully.

## Resources created

At this time, the Terraform scripts in this folder create:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private GitHub repo
- Dataform repository connected to the GitHub repo
