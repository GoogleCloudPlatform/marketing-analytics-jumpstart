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
    git clone https://github.com/GoogleCloudPlatform/marketing-analytics-platform.git
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
    cd $HOME/marketing-analytics-platform/
    scripts/generate-tf-backend.sh
    ```

4. Create the terraform variable file by making a copy from the template and set the terraform variables.

    ```bash
    cp $HOME/marketing-analytics-platform/terraform/terraform.tfvars.template $HOME/marketing-analytics-platform/terraform/terraform.tfvars
    ```

    Edit the `terraform.tfvars` file by setting the following variable values:
    * `project_id`, your Google Cloud project that Terraform will provision the resources in
    * `location`, the Google Cloud region that Terraform will provision the resources in
    * `ga4_measurement_id`, used to call GA4 Measurement Protocol API
    * `ga4_measurement_secret`, used to call GA4 Measurement Protocol API

### Preparation Step for Feature Store

1. Install developer libraries.

```bash
pip install poetry
poetry install -v --no-interaction --no-ansi --with dev
```

2. Change the values in the `config/[ENV].yaml` file.

Create or open the environment file, `config/[ENV].yaml` you want to use and change the values under the `bigquery` section.

Before applying the configuration values, the developer could prepare multiple configurations to deploy the Feature Store in a single environment or in multiple environments (dev, uat and prod) in case customer’s policies require. Just yet, the customer is not able to customize the solution and have an automated CI/CD process for promoting changes through those environments.

3. Apply configuration values from [ENV].yaml on .sqlx files to generate the .sql files to be deployed.

```bash
poetry run inv apply-env-variables-tables --env-name=[ENV]
poetry run inv apply-env-variables-queries --env-name=[ENV]
poetry run inv apply-env-variables-datasets --env-name=[ENV]
poetry run inv apply-env-variables-procedures --env-name=[ENV] 
```

Finally, you're ready to deploy the Feature Store using terraform.

### Preparation Step for ml pipelines

1. Change the values in the `config/[ENV].yaml` file.

Create or open the environment file, `config/[ENV].yaml` you want to use and change the values under `cloud_build`, `artifact_registry`, `dataflow` and `vertex_ai` sections.

2. Build the vertex ai pipeline base component image

```bash
pip install poetry
poetry install
cd python && poetry run python -m base_component_image.build-push -c ../config/[ENV].yaml
```

3. Compile, Upload and schedule the Vertex AI Pipelines

```bash
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.feature-creation.execution -o feature_engineering.yaml
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.propensity.training -o propensity_training.yaml
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.propensity.prediction -o propensity_prediction.yaml
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.clv.training -o clv_training.yaml
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.clv.prediction -o clv_prediction.yaml
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.segmentation.training -o segmentation_training.yaml
poetry run python -m pipelines.compiler -c ../config/[ENV].yaml -p vertex_ai.pipelines.segmentation.prediction -o segmentation_prediction.yaml
```

### Final Step

Deploy all assets to the Google Cloud project as per the template values and configuration values.

```bash
terraform init -input=false
terraform plan -input=false
terraform apply -auto-approve -input=false
```

## OSS Developer Guide

### Fork this repo.

Follow the typical Github guide on how to [fork a repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

**Note**: 
1. To keep track of the new releases, configure git to [sync your fork with this upstream repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo#configuring-git-to-sync-your-fork-with-the-upstream-repository).
2. Don't submit a Pull Request to this upstream Github repo if you don't want to expose your environment configuration. You're at your own risk at exposing your company data.
3. Observe your fork is also public, you cannot make your own fork a private repo.

### Complete the installation guide

Complete the installation guide in a Google Cloud project in which you're developer and/or owner.

### Configure Continuous Integration recipes

Connect your Github repository by following this [guide](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github).

In your Google Cloud project, configure Cloud Build triggers to be executed when you push code into your branch. Update the Clould build recipes in the `cloudbuild` folder and deploy them.

### Update GCloud and Install Beta

```bash
gcloud components update
gcloud components install beta
```

### Install packages to define components, run locally and compile pipeline

```bash
pip install poetry
poetry install -v --with dev
```

### Modify the code and configurations as you prefer

Do all the code changes you wish. 
If you're implementing new use cases, add these resources to the existing terraform module components.
Otherwise, in case you're implementing a new component, implement your own terraform module for it.

### Manual Re-Deployment

Change the values in the terraform templates located in the `infrastructure/terraform` folder and deploy the code your google cloud project.

```bash
terraform init
terraform plan
terraform apply
```

## Contributing

We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how to publish your contributions.
