# Terraform Scripts for Marketing Data Store

The Terraform scripts in this folder create the infrastructure to start data ingestion
into BigQuery

## Pre-requirements

* You have a Google Cloud project with billing enabled.
* You har a GA4 account with the [query parameters](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?client_type=gtag#payload_query_parameters)
* In the Google Cloud Console, on the project selector page, [select or create a Google Cloud project](https://console.cloud.google.com/projectselector2/home/dashboard). You need to be a project owner in order to set up the environment.

* You have [python poetry](https://python-poetry.org/docs/) installed in your environment.

  ```bash
  curl -sSL https://install.python-poetry.org | python3 -
  ```

* Link your github repositry with Google Cloud Source Repository that are used by Cloud Build triggers of the ML processing pipelines.

## Installation Guide

### Initial Environment Setup

From [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shelld.google.com/shell/docs/using-cloud-shell), run the following commands:
1. Clone the source code repository:

    ```bash
    REPO="marketing-analytics-platform"
    cd "$HOME"
    git clone https://github.com/GoogleCloudPlatform/${REPO}.git
    ```

2. Export environment variables and set default project:

    ```bash
    export PROJECT_ID="[your Google Cloud project id]"
    export GOOGLE_APPLICATION_CREDENTIALS="[the Google Cloud application credentials]"
    gcloud config set project $PROJECT_ID
    ```

3. Run the following script to create Terraform service account. To run the script you use an account to authenticate against Google Cloud  which have following permissions in your Google Cloud project:
    * `roles/iam.serviceAccountCreator` for creating service account used by terraform.
    * `roles/storage.admin` for creating terraform backend-config storage bucket.

    ```bash
    SOURCE_ROOT=${HOME}/${REPO}
    cd ${SOURCE_ROOT}
    scripts/generate-tf-backend.sh
    ```

4. Create the terraform variable file by making a copy from the template and set the terraform variables.

    ```bash
    TERRAFORM_RUN_DIR=${SOURCE_ROOT}/infrastructure/terraform
    cp ${TERRAFORM_RUN_DIR}/terraform-sample.tfvars ${TERRAFORM_RUN_DIR}/terraform.tfvars
    vim ${TERRAFORM_RUN_DIR}/terraform.tfvars
    ```

    Edit the `terraform.tfvars` file by setting the following variable values:
    * `tf_state_project_id`, Project ID where terraform backend configuration is stored
    * `source_ga4_export_project_id`, Project ID which contains the GA4 export dataset
    * `source_ga4_export_dataset`, GA4 export dataset name
    * `data_project_id`, Project id where the MDS datasets will be created
    * `data_processing_project_id`, Project id where the Dataform will be installed and run
    * `project_owner_email`, Project owner email
    * `dataform_github_repo`, URL of the GitHub or GitLab repo which contains the Dataform scripts
    * `dataform_github_token`, GitHub token generated for that repo

    * `source_ads_export_data`, Ads data export dataset details, formatted as the following array:
    ```json
    [{ project = "abc", dataset = "dataset1", table_suffix = "_123456" },
    { project = "xyz", dataset = "dataset2", table_suffix = "_567890" }]
    ```
    * `activation_project_id`, "Project ID where activation resources are created
    * `ga4_measurement_id`, used to call GA4 Measurement Protocol API
    * `ga4_measurement_secret`, used to call GA4 Measurement Protocol API
    * `pipelines_github_owner`, Cloud Build github owner account for pipelines
    * `pipelines_github_repo`, Cloud Build github repository for pipelines

5. Run terraform to create the configuration yaml file:

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" init
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply \
    -var=create_prod_environment=false \
    -var=deploy_feature_store=false \
    -var=deploy_activation=false \
    -var=deploy_pipelines=false
    ```

6. Run `poetry` to generate the sql files by hydrate the sqlx files:

    ```bash
    POETRY_ENV=prod
    poetry run inv apply-env-variables-datasets --env-name=${POETRY_ENV}
    poetry run inv apply-env-variables-tables --env-name=${POETRY_ENV}
    poetry run inv apply-env-variables-queries --env-name=${POETRY_ENV}
    poetry run inv apply-env-variables-procedures --env-name=${POETRY_ENV}
    ```

7. Run terraform to deploy resources for **marketing data store**, **feature store**, **pipelines** and **activation application**:

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply \
    -var=feature_store_config_env=${POETRY_ENV}
    ```

## Resources created

At this time, the Terraform scripts in this folder create:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private Github repo
- Dataform repository connected to the Github repo
