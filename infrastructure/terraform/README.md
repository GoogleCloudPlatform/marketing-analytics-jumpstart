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
    REPO="marketing-analytics-jumpstart"
    cd $HOME
    git clone https://github.com/GoogleCloudPlatform/${REPO}.git
    ```

1. If you don't use Cloud Shell, export environment variables and set the default project.
   Typically, there is a single project to install the solution. If you chose to use multiple projects - use the one
   designated for the data processing.

    ```bash
    export PROJECT_ID="[your Google Cloud project id]"
    gcloud config set project $PROJECT_ID
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

1. Authenticate with additional OAuth 2.0 scopes needed to use the Google Analytics Admin API:
   ```shell
   gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/accounts.reauth"
   ```

    **Note:** You will receive an error message informing the Cloud Resource Manager API has not been used/enabled for your project, similar to the following: 
    
    ERROR: (gcloud.auth.application-default.login) User [<ldap>@<company>.com] does not have permission to access projects instance [<gcp_project_ID>:testIamPermissions] (or it may not exist): Cloud Resource Manager API has not been used in project <gcp_project_id> before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=<gcp_project_id> then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.

    On the next step, the Cloud Resource Manager API will be enabled and, then, your credentials will finally work.

1. Run the following script to create a Terraform remote backend. 

    Terraform stores state about managed infrastructure to map real-world resources to the configuration, keep track of metadata, and improve performance. Terraform stores this state in a local file by default, but you can also use a Terraform remote backend to store state remotely. [Remote state](https://developer.hashicorp.com/terraform/cdktf/concepts/remote-backends) makes it easier for teams to work together because all members have access to the latest state data in the remote store.

    ```bash
    SOURCE_ROOT=${HOME}/${REPO}
    cd ${SOURCE_ROOT}
    scripts/generate-tf-backend.sh
    ```

    **Note:** Make sure you have permissions to query the tables the BigQuery dataset where your GA4 and GAds exported data is located.

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

    **Note:** The variable `google_default_region` determines the region where the resources are hosted. The variable default value is `us-central1`, based on your data residency requirements you should change the variable value by add the following in your `terraform.tfvars` file:
    ```
    google_default_region = "[specific Google Cloud region of choice]"
    ```
    **Note:** The variable `destination_data_location` determines the location for the data store in BigQuery. You have the choice to either store the data in single region by assigning value such as
    * `us-central1`, `europe-west1`, `asia-east1` etc

    or in multi-regions by assigning value such as
    * `US` or `EU`

1. Run Terraform to create resources:

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" init
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply
    ```

   If you don't have a successful execution from the beginning, re-run until all is deployed successfully.

## Post-Installation Instructions

Now that you have deployed all assets successfully for the first time in your Google Cloud Project, the data must flow through all components. You can trigger your Cloud Workflow to execute your Dataform workflow at any time, or you can wait until the next day when the Cloud Workflow is going to be executed according to your schedule.

There are two components in this solution that requires data for proper installation and functioning. One is the Looker Studio Dashboard, you only deploy the dashboard after you have executed the previous step in the Installation Guide successfully. Another is the ML pipeline, the pipelines compilation requires views and tables to be created so that it can read their schema and define the column transformations to run during the pipeline execution.  

To manually start the data flow you must perform the following tasks:

1. Run the Cloud Workflow

    On the Google Cloud console, navigate to Workflows page. You will see a Workflow named `dataform-prod-incremental`, then under Actions, click on the three dots and `Execute` the Workflow.
    
     **Note:** If you have a considerable amount of data (>XXX GBs of data) in your exported GA4 and Ads BigQuery datasets, it can take several minutes or hours to process all the data. Make sure that the processing has completed successfully before you continue to the next step.

1. Invoke the BigQuery stored procedures having the prefix `invoke_backfill_*` to backfill the feature store in case the GA4 Export has been enabled a long time ago before installing MDE.

    On the Google Cloud console, navigate to BigQuery page. On the query composer, run the following queries to invoke the stored procedures.
    ```sql
    ## Backfill customer ltv tables
    CALL `feature_store.invoke_backfill_customer_lifetime_value_label`();
    CALL `feature_store.invoke_backfill_user_lifetime_dimensions`();
    CALL `feature_store.invoke_backfill_user_rolling_window_lifetime_metrics`();
    CALL `feature_store.invoke_backfill_user_scoped_lifetime_metrics`();
    CALL `customer_lifetime_value.invoke_customer_lifetime_value_training_preparation`();
    CALL `customer_lifetime_value.invoke_customer_lifetime_value_inference_preparation`();

    ## Backfill purchase propensity tables
    CALL `feature_store.invoke_backfill_user_dimensions`();
    CALL `feature_store.invoke_backfill_user_rolling_window_metrics`();
    CALL `feature_store.invoke_backfill_user_scoped_metrics`();
    CALL `feature_store.invoke_backfill_user_session_event_aggregated_metrics`();
    CALL `feature_store.invoke_backfill_purchase_propensity_label`();
    CALL `purchase_propensity.invoke_purchase_propensity_training_preparation`();
    CALL `purchase_propensity.invoke_purchase_propensity_inference_preparation`();

    ## Backfill audience segmentation tables
    CALL `feature_store.invoke_backfill_user_segmentation_dimensions`();
    CALL `feature_store.invoke_backfill_user_lookback_metrics`();
    CALL `feature_store.invoke_backfill_user_scoped_segmentation_metrics`();
    CALL `audience_segmentation.invoke_audience_segmentation_training_preparation`();
    CALL `audience_segmentation.invoke_audience_segmentation_inference_preparation`();
    ```

    **Note:** If you have a considerable amount of data (>XXX GBs of data) in your exported GA4 BigQuery datasets over the last six months, it can take several hours to backfill the feature data so that you can train your ML model. Make sure that the backfill procedures starts without errors before you continue to the next step.

1. Redeploy the ML pipelines using Terraform.

    On your code editor, change the variable `deploy_pipelines` from `true` to `false`, on the TF variables file `${TERRAFORM_RUN_DIR}/terraform.tfvars`.
    Next, undeploy the ML pipelines component by applying the terraform configuration.

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply
    ```

    Now, to deploy the ML pipelines component again, revert your changes on the TF variables file `${TERRAFORM_RUN_DIR}/terraform.tfvars` and apply the terraform configuration by running the commad above again.

### Resume terminal session

Because a Cloud Shell session is ephemeral, your Cloud Shell session could terminate for various reasons. When a terminal session ends all the session variables and user authentication are lost. You can run the `session-resume.sh` script to configure a new terminal session with the necessary environmental variables and authentication credentials to continue with the terraform deployment.

 **Note:** The prerequisites for running this script are that you have set all the variable values in the TF variables file `$TERRAFORM_RUN_DIR}/terraform.tfvars` and have applied the terraform configuration once before.

To configure a new terminal session run following commands:

  ```bash
  SOURCE_ROOT="${HOME}/marketing-analytics-jumpstart"
  cd ${SOURCE_ROOT}
  . scripts/session-resume.sh
  ```

Follow the authentication workflow, if prompted.

## Resources created

At this time, the Terraform scripts in this folder perform the following tasks:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private GitHub repo
- Dataform repository connected to the GitHub repo
- Deploys the marketing data store (MDS), feature store, ML pipelines and activation application

The Looker Studio Dashboard deployment is a separate [step](https://github.com/GoogleCloudPlatform/marketing-data-engine/blob/main/python/lookerstudio/README.md).
