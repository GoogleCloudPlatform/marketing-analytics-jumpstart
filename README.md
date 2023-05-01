# Marketing Data Engine

Marketing Data Engine consists of an easy, flexible and automated implementation of an end-to-end solution that enables Marketing Technologist teams to store, transform, analyze maketing data, and programatically sends predictive events to Google Analytics 4 to support conversion optimization and remarketing campaigns. 

This solution also demonstrates how to implement three common predictive use cases (purchase propensity, customer lifetime value and audience segmentation) and a dashboard to monitor Campaigns Performance leveraging the best of Google Cloud data and ai products and practices.

## Disclaimer

This is not an officially supported Google product. This solution is not finalized or validated with multiple customers. Use it at your own risk. Updates and implementation timeline to be informed soon.

## Introduction

Marketing Analytics commonly involves leveraging ML models and building ML pipelines providing audience management platforms with predictive conversion events or audiences to help the Marketing team to build audiences and come up with more effective marketing campaigns that drive better performance and ROAS.

This solution includes the following components: a petabyte-scale marketing data store (MDS), a reusable feature store, robust and parametrizable ml pipelines (feature engineering, training and inference pipelines), an activation pipeline that programatically sends predictive conversion events estimates to Google Analytics 4 and Google Ads, and a dashboard to monitor campaigns performance.

The MDS builds an easy-to-use logical data model using Google Ads and Google Analytics 4 data exports. The feature store and ml pipelines use Google Analytics 4 behavioural data. The following Google Cloud Products are used: BigQuery, DataForm, Vertex AI Pipelines, Vertex AI Tabular Workflows, DataFlow, Cloud Function, Cloud Pub/Sub.

## Installation Guide

The installation of this solution requires a multi-step process. First, you need to follow the initial environment setup, then you may have specific steps for each component, such as the feature store and ml pipelines. Lastly, the final step involves running terraform.

### Initial Environment Setup

In the Google Cloud Console, on the project selector page, [select or create a Google Cloud project](https://console.cloud.google.com/projectselector2/home/dashboard). You need to be a project owner in order to set up the environment.

From [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shelld.google.com/shell/docs/using-cloud-shell), run the following commands:
1. Clone the source code repository:

    ```bash
    cd "$HOME"
    git clone https://github.com/GoogleCloudPlatform/marketing-data-engine.git
    ```

2. Export environment variables and set default project:

    ```bash
    gcloud auth login
    export PROJECT_ID="[your Google Cloud project id]"
    gcloud config set project $PROJECT_ID
    gcloud auth application-default login
    export GOOGLE_APPLICATION_CREDENTIALS="[Credentials file created by the last command]"
    ```

3. Run the following script to generate Terraform backend configurations. The script also creates a Google Cloud Storage bucket where Terraform stores its state data file. This bucket is not managed by Terraform. To run the script you use an account to authenticate against Google Cloud  which have following permissions in your Google Cloud project:
    * `roles/iam.serviceAccountCreator` for creating service account used by terraform.
    * `roles/storage.admin` for creating terraform backend-config storage bucket.

    ```bash
    cd $HOME/marketing-data-engine/
    scripts/generate-tf-backend.sh
    ```

4. Create the terraform variable file by making a copy from the template and set the terraform variables.

    ```bash
    cp $HOME/marketing-data-engine/infrastructure/terraform/terraform.tfvars.template $HOME/marketing-data-engine/infrastructure/terraform/terraform.tfvars
    ```

    Edit the `terraform.tfvars` file by setting the following variable values:

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
    source_ads_export_data = [{ project = "abc", dataset = "dataset1", table_suffix = "_123456" },
    { project = "xyz", dataset = "dataset2", table_suffix = "_567890" }]
    
    ####################  ACTIVATION VARIABLES  #################################
    activation_project_id  = "Project ID where activation resources are created"
    # MEASUREMENT ID and API SECRET generated in the Google Analytics UI. To create a new secret, navigate to:
    #   Admin > Data Streams > choose your stream > Measurement Protocol > Create
    ga4_measurement_id     = "Measurement ID in GA4"
    ga4_measurement_secret = "Client secret for authenticatin to GA4 API"

    ####################  GITHUB VARIABLES  #################################
    project_owner_email = "Project owner email"
    dataform_github_repo = "URL of the GitHub or GitLab repo which contains the Dataform scripts"
    dataform_github_token = "GitHub token generated for that repo"
    pipelines_github_owner = "Cloud Build github owner account for pipelines"
    pipelines_github_repo  = "Cloud Build github repository for pipelines"
    ```

### Infrastructure Deployment

Deploy all assets to the Google Cloud project as per the template values and configuration values.

```bash
terraform init -input=false
terraform plan -input=false
terraform apply -auto-approve -input=false
```

## Contributing

We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how to publish your contributions.
