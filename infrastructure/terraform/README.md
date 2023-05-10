# Terraform Scripts

The Terraform scripts in this folder create the infrastructure to start data ingestion
into BigQuery, create feature store, ML pipelines and Dataflow activation pipeline.

## Prerequisites

Make sure the prerequisites listed in the [parent README](../README.md) are met. You can run the script
from [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shelld.google.com/shell/docs/using-cloud-shell)
or a Linux machine or Mac with `gcloud` command installed.

## Installation Guide

### Initial Environment Setup

1. Clone the source code repository:

    ```bash
    REPO="marketing-data-engine"
    cd "$HOME"
    git clone https://github.com/GoogleCloudPlatform/${REPO}.git
    ```

2. Export environment variables and set default project:

    ```bash
    gcloud auth login
    export PROJECT_ID="[your Google Cloud project id]"
    gcloud config set project $PROJECT_ID
    gcloud auth application-default login
    export GOOGLE_APPLICATION_CREDENTIALS="[Credentials file created by the last command]"
    ```

3. Install Python's Poetry

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

3. Run the following script to create Terraform service account. To run the script you use an account to authenticate
   against Google Cloud which have the following permissions in your Google Cloud project:
   * `roles/iam.serviceAccountCreator` for creating service account used by terraform.
   * `roles/storage.admin` for creating terraform backend-config storage bucket.

    ```bash
    SOURCE_ROOT=${HOME}/${REPO}
    cd ${SOURCE_ROOT}
    scripts/generate-tf-backend.sh
    ```

   **Note:** Make sure you provide access to the BigQuery dataset where your GA4 and GAds exported data is located.

5. Create the Terraform variable file by making a copy from the template and set the Terraform variables.

    ```bash
    TERRAFORM_RUN_DIR=${SOURCE_ROOT}/infrastructure/terraform
    cp ${TERRAFORM_RUN_DIR}/terraform-sample.tfvars ${TERRAFORM_RUN_DIR}/terraform.tfvars
    vim ${TERRAFORM_RUN_DIR}/terraform.tfvars
    ```

   Edit the `terraform.tfvars` file by setting the following variable values:

<!--  TODO: We are going to need to keep this list in sync  with the actual file. Perhaps it's not worth doing it. -->

    ```bash
    ####################  INFRA VARIABLES  #################################
    tf_state_project_id          = "Project ID where terraform backend configuration is stored"
    # Choose which Dataform environment you are installing now dev/staging/prod
    create_dev_environment     = false
    create_staging_environment = false
    create_prod_environment    = true
    # If you want full installation, set all these to true
    deploy_activation    = true
    deploy_feature_store = true
    deploy_pipelines     = true

    ####################  DATA VARIABLES  #################################
    data_project_id = "Project id where the MDS datasets will be created"
    data_processing_project_id = "Project id where the Dataform will be installed and run"
    source_ga4_export_project_id = "Project id which contains the GA4 export dataset"
    source_ga4_export_dataset = "GA4 export dataset name"
    # Ads data export dataset details, formatted as the following sample array 
    source_ads_export_data = [{ project = "abc", dataset = "dataset1", table_suffix = "_123456" },
    { project = "xyz", dataset = "dataset2", table_suffix = "_567890" }]
    
    ####################  ACTIVATION VARIABLES  #################################
    activation_project_id  = "Project ID where activation resources are created"
    # MEASUREMENT ID and API SECRET generated in the Google Analytics UI. To create a new secret, navigate to:
    #   Admin > Data Streams > choose your stream > Measurement Protocol > Create
    ga4_measurement_id     = "Measurement ID in GA4"
    ga4_measurement_secret = "Client secret for authentication to GA4 API"

    ####################  GITHUB VARIABLES  #################################
    project_owner_email = "Project owner email"
    dataform_github_repo = "URL of the GitHub or GitLab repo which contains the Dataform scripts"
    dataform_github_token = "GitHub token generated for that repo"
    pipelines_github_owner = "Cloud Build github owner account for pipelines"
    pipelines_github_repo  = "Cloud Build github repository for pipelines"
    ```

6. Run Terraform to create resource for **marketing data store** (the Dataform repository and related workflows):

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" init
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply \
    -var=create_prod_environment=false \
    -var=deploy_feature_store=false \
    -var=deploy_activation=false \
    -var=deploy_pipelines=false
    ```

   **Note:** Wait for a few minutes meanwhile all the resource are deployed to your Google Cloud project. You should
   have to wait on Dataform to be configured.
   If you don't have a successful execution from the beginning, re-run until all is deployed successfully.

7. Run terraform to create resources for **feature store**, **pipelines** and **activation application**:

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply
    ```

## Resources created

At this time, the Terraform scripts in this folder create:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private GitHub repo
- Dataform repository connected to the GitHub repo
