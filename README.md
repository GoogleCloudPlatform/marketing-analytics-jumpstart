# Click-to-deploy Propensity Modeling Solution

This solution consists of an easy, flexible and automated blueprint implementation that enables Marketing Technologist teams to manage and develop consistent predictive use cases to Marketing teams leveraging the best of Google Cloud products and practices.

## Introduction

Marketing Predictive Analytics commonly involves leveraging ML models and building ML pipelines providing audience management platforms with predictive audiences to help the Marketing team to come up with more effective marketing campaigns that drive better performance.

It includes the following components: a petabyte-scale feature store, robust ml pipelines (feature engineering, training and inference pipelines), and a activation pipeline that programatically sends predictive conversion events estimates to Google Analytics 4 and Google Ads.

The pipelines manipulate Google Analytics 4 data. The following Google Cloud Products are used: BigQuery, Vertex AI Pipelines, Vertex AI Tabular Workflows, DataFlow, Cloud Function, Cloud Pub/Sub.

## Installation Guide

### Initial Environment Setup

In the Google Cloud Console, on the project selector page, [select or create a Google Cloud project](https://console.cloud.google.com/projectselector2/home/dashboard). You need to be a project owner in order to set up the environment.

From [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shelld.google.com/shell/docs/using-cloud-shell), run the following commands:
1. Clone the source code repository:

    ```bash
    cd "$HOME"
    git clone https://github.com/chmstimoteo/propensity-modeling.git
    ```

2. Export environment variables and set default project:

    ```bash
    export PROJECT_ID="[your Google Cloud project id]"
    export GOOGLE_APPLICATION_CREDENTIALS="[the Google Cloud application credentials]"
    gcloud config set project $PROJECT_ID
    ```

3. Run the following script to generate Terraform backend configurations. The script also creates a Google Cloud Storage bucket where Terraform stores its state data file. This bucket is not managed by Terraform. To run the script you use an account to authenticate against Google Cloud  which have following permissions in your Google Cloud project:
    * `roles/iam.serviceAccountCreator` for creating service account used by terraform.
    * `roles/storage.admin` for creating terraform backend-config storage bucket.

    ```bash
    cd $HOME/propensity-modeling/
    scripts/generate-tf-backend.sh
    ```

4. Create the terraform variable file by making a copy from the template and set the terraform variables.

    ```bash
    cp $HOME/propensity-modeling/terraform/terraform.tfvars.template $HOME/activation-processing-pipeline/terraform/terraform.tfvars
    ```

    Edit the `terraform.tfvars` file by setting the following variable values:
    * `project_id`, your Google Cloud project that Terraform will provision the resources in
    * `location`, the Google Cloud region that Terraform will provision the resources in
    * `ga4_measurement_id`, used to call GA4 Measurement Protocol API
    * `ga4_measurement_secret`, used to call GA4 Measurement Protocol API

### feature-store



### ml-pipelines



### activation-pipeline

The activation processing pipeline is the component that reads the result data from ML pipelines and use it as activation signals in external platforms.
Currently activation processing pipeline supports integration with GA4 through the Measurement Protocol API.

#### Prerequisites
* You har a GA4 account with the [query parameters](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?client_type=gtag#payload_query_parameters)
* You have a Google Cloud project with billing enabled.

#### Specific Component Installation
1. Run terraform to provision all the resources for the activation processing pipeline.

    ```bash
    cd $HOME/propensity-modeling/terraform
    terraform init
    terraform apply
    ```

## Developer Guide

### Enable APIS

```bash
export PROJECT_ID=lifetime-value-361020
gcloud config set project $PROJECT_ID
gcloud services enable \
  cloudbuild.googleapis.com \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  container.googleapis.com \
  cloudapis.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudtrace.googleapis.com \
  containerregistry.googleapis.com \
  iamcredentials.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  notebooks.googleapis.com \
  aiplatform.googleapis.com \
  storage.googleapis.com
```

### Update GCloud and Install Beta

```bash
gcloud components update
gcloud components install beta
```

### Environment Configuration

```bash
terraform init -input=false
terraform plan -input=false
terraform apply -auto-approve -input=false
```

### Create Bucket to store pipeline artifacts

```bash
REGION=us-central1
BUCKET_NAME=lifetime-value-assets
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
gsutil mb -l $REGION -p $PROJECT_ID gs://$BUCKET_NAME
```

### Create service account to deploy assets using Cloud Build

```bash
BUILDER_SERVICE_ACCOUNT_ID=sa-builder
gcloud iam service-accounts create $BUILDER_SERVICE_ACCOUNT_ID  \
    --description="$SERVICE_ACCOUNT_ID" \
    --display-name="$SERVICE_ACCOUNT_ID" \
    --project=$PROJECT_ID
```

#### Grant IAM roles for Builder Service Account

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${BUILDER_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${BUILDER_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"
```

### Create service account to Run the SQL code 

```bash
RUN_SERVICE_ACCOUNT_ID=sa-customer-lifetime-value
gcloud iam service-accounts create $RUN_SERVICE_ACCOUNT_ID  \
    --description="$SERVICE_ACCOUNT_ID" \
    --display-name="$SERVICE_ACCOUNT_ID" \
    --project=$PROJECT_ID
```

#### Grant IAM roles for Vertex AI

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${RUN_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${RUN_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/aiplatform.serviceAgent"
```

#### Grant IAM roles for BigQuery

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${RUN_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataEditor"
```

### Grant Control Policy to Read and Write from Cloud Storage Bucket

```bash
gsutil iam ch \
serviceAccount:${RUN_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com:legacyBucketWriter \
gs://$BUCKET_NAME

gsutil iam ch \
serviceAccount:${RUN_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com:roles/storage.objectCreator \
gs://$BUCKET_NAME

gsutil iam ch \
serviceAccount:${RUN_SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com:roles/storage.objectViewer \
gs://$BUCKET_NAME
```

### Install packages to define components, run locally and compile pipeline

```bash
pip3 install kfp --upgrade # You may need to install kfp
pip3 install google-cloud-aiplatform[pipelines] google-cloud-bigquery google-cloud-storage --upgrade
pip3 install google_cloud_pipeline_components --upgrade
pip3 install pandas db-dtypes matplotlib
```