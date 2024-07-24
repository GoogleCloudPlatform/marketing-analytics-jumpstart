# Terraform Scripts

The Terraform scripts in this folder create the infrastructure to start data ingestion
into BigQuery, create feature store, ML pipelines and Dataflow activation pipeline.

## Prerequisites

Make sure the prerequisites listed in the [parent README](../README.md) are met. You can run the script
from [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shelld.google.com/shell/docs/using-cloud-shell)
or a Linux machine or a Mac with `gcloud` command installed. The instructions provided are for the Cloud Shell
installation.

## Installation Guide
Step by step installation guide with [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart.git&cloudshell_git_branch=main&cloudshell_workspace=&cloudshell_tutorial=infrastructure/cloudshell/tutorial.md)

**Note:** If you are working from a forked repository, be sure to update the `cloudshell_git_repo` parameter to the URL of your forked repository for the button link above.

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
    gcloud auth application-default set-quota-project $PROJECT_ID
    ```

1. Install or update Python3
    Install a compatible version of Python 3.8-3.10 and set the CLOUDSDK_PYTHON environment variable to point to it.

    ```bash
    apt-get install python3.10
    CLOUDSDK_PYTHON=python3.10
    ```
    If you are installing on a Mac:
   ```shell
   brew install python@3.10
   CLOUDSDK_PYTHON=python3.10
   ```

1. Install Python's Poetry and set Poetry to use Python3.8-3.10 version

   [Poetry](https://python-poetry.org/docs/) is a Python's tool for dependency management and packaging.

   If you are installing on in Cloud Shell use the following commands:
   ```shell
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
   Set poetry to use your latest python3
   ```shell
   SOURCE_ROOT=${HOME}/${REPO}
   cd ${SOURCE_ROOT}
   poetry env use python3
   ```

1. Authenticate with additional OAuth 2.0 scopes needed to use the Google Analytics Admin API:
   ```shell
   gcloud auth login
   gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/accounts.reauth"
   ```

    **Note:** You may receive an error message informing the Cloud Resource Manager API has not been used/enabled for your project, similar to the following: 
    
    ERROR: (gcloud.auth.application-default.login) User [<ldap>@<company>.com] does not have permission to access projects instance [<gcp_project_ID>:testIamPermissions] (or it may not exist): Cloud Resource Manager API has not been used in project <gcp_project_id> before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=<gcp_project_id> then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.

    On the next step, the Cloud Resource Manager API will be enabled and, then, your credentials will finally work.

1. Review your Terraform version

    Make sure you have installed terraform version is 1.5.7. We recommend you to use [tfenv](https://github.com/tfutils/tfenv) to manage your terraform version.
   `Tfenv` is a version manager inspired by rbenv, a Ruby programming language version manager.

    To install `tfenv`, run the following commands:

    ```shell
    # Install via Homebrew or via Arch User Repository (AUR)
    # Follow instructions on https://github.com/tfutils/tfenv

    # Now, install the recommended terraform version 
    tfenv install 1.5.7
    tfenv use 1.5.7
    terraform --version
    ```

    For instance, the output on MacOS should be like:
    ```shell
    Terraform v1.5.7
    on darwin_amd64
    ```

1. Run the following script to create a Terraform remote backend. 

    Terraform stores state about managed infrastructure to map real-world resources to the configuration, keep track of metadata, and improve performance. Terraform stores this state in a local file by default, but you can also use a Terraform remote backend to store state remotely. [Remote state](https://developer.hashicorp.com/terraform/cdktf/concepts/remote-backends) makes it easier for teams to work together because all members have access to the latest state data in the remote store.

    ```bash
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

### Resume terminal session

Because a Cloud Shell session is ephemeral, your Cloud Shell session could terminate for various reasons. When a terminal session ends all the session variables and user authentication are lost. You can run the `session-resume.sh` script to configure a new terminal session with the necessary environmental variables and authentication credentials to continue with the terraform deployment.

 **Note:** The prerequisites for running this script are that you have set all the variable values in the TF variables file `$TERRAFORM_RUN_DIR}/terraform.tfvars` and have applied the terraform configuration once before.

Follow the authentication workflow, since your credentials expires daily:

   ```bash
   # Authenticate your user to Google Cloud
   gcloud auth login
   # Authenticate your application default login to Google Cloud with the right scopes for Terraform to run
   gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/accounts.reauth"
   ```

To resume working on a new terminal session run the following commands:

  ```bash
  # Change directory to the source code root directory
  SOURCE_ROOT="${HOME}/marketing-analytics-jumpstart"
  cd ${SOURCE_ROOT}
  TERRAFORM_RUN_DIR=${SOURCE_ROOT}/infrastructure/terraform
  # Resume the terminal session using values stored on Terraform outputs
  ./scripts/session-resume.sh
  ```

## Resources created

At this time, the Terraform scripts in this folder perform the following tasks:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private GitHub repo
- Dataform repository connected to the GitHub repo
- Deploys the marketing data store (MDS), feature store, ML pipelines and activation application

The Looker Studio Dashboard deployment is a separate [step](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/python/lookerstudio/README.md).

## Post-Installation Instructions

Now that you have deployed all assets successfully in your Google Cloud Project, you may want to plan for operating the solution to be able to generate the predictions you need to create the audience segments you want for you Ads campaigns.

To accomplish that, you gonna to plan a few things. First, you need to choose what kind of insight you are looking for to define the campaigns. Here are a few insights provided by each one of the use cases already provided to you:

- **Aggregated Value Based Bidding**: Attributes a numerical value to high value conversion events (user action) in relation to a target conversion event (typically purchase) so that Google Ads can improve the bidding strategy for users that reached these conversion events, as of now.
- **Demographic Audience Segmentation**: Attributes a cluster segment to an user using demographics data, including geographic location, device, traffic source and windowed user metrics looking XX days back.
- **Interest based Audience Segmentation**: Attributes a cluster segment to an user using pages navigations data looking XX days back, as of now.
- **Purchase Propensity**: Predicts a propensity decile and a propensity score (likelihood between 0.0 - 0% and 1.0 - 100%) to an user using demographics data, including geographic location, device, traffic source and windowed user metrics looking XX days back to predict XX days ahead, as of now.
- **Customer Lifetime Value**: Predicts a lifetime value gain decile and a lifetime value revenue gain in USD (equal of bigger than 0.0) to an user using demographics data, including geographic location, device, traffic source and windowed user metrics looking XX-XXX days back to predict XX days ahead, as of now.

Second, you need to measure how much data you are going to use to obtain the insights you need. Each one of the use cases above requires data in the following intervals, using as key metrics number of days and unique user events.

- **Aggregated Value Based Bidding**: Minimum 30 days and maximum 1 year. The number of unique user events is not a key limitation. Note that you need at least 1000 training examples for the model to be trained successfully, to accomplish that we typically duplicate the rows until we have a minimum of 1000 rows in the training table for the "TRAIN" subset.
- **Demographic Audience Segmentation**: Minimum 30 days and maximum 1 year. Minimum of 1000 unique user events per day. Note that you don't need more than 1M training examples for the model to perform well, make sure your training table doesn't contain more training examples than you need by applying exclusion clauses (i.e. WHERE, LIMIT clauses). 
- **Interest based Audience Segmentation**: Minimum 30 days and maximum 1 year. Minimum of 1000 unique user events per day. Note that you don't need more than 1M training examples for the model to perform well, make sure your training table doesn't contain more training examples than you need by applying exclusion clauses (i.e. WHERE, LIMIT clauses).
- **Purchase Propensity**: Minimum 90 days and maximum 2 years. Minimum of 1000 unique user events per day, of which a minimum of 1 target event per week. Note that you don't need more than 1M training examples for the model to perform well, make sure your training table doesn't contain more training examples than you need by applying exclusion clauses (i.e. WHERE, LIMIT clauses).
- **Customer Lifetime Value**: Minimum 180 days and maximum 5 years. Minimum of 1000 unique user events per day, of which a minimum of 1 event per week that increases the lifetime value for an user. Note that you don't need more than 1M training examples for the model to perform well, make sure your training table doesn't contain more training examples than you need by applying exclusion clauses (i.e. WHERE, LIMIT clauses).

Finally, the data must be processed by the Marketing Data Store, features must be prepared using the Feature Engineering procedure and the training and inference pipeline must be triggered. For that, open your `config.yaml.tftpl` configuration file and check the `{pipeline-name}.execution.schedule` block to modify the scheduled time for each pipeline you gonna need to orchestrate that enables your use case. Here is a list of pipelines you need for every use case.

- **Aggregated Value Based Bidding**: `feature-creation-aggregated-value-based-bidding`, `value_based_bidding.training`, `value_based_bidding.explanation`
- **Demographic Audience Segmentation**: `feature-creation-audience-segmentation`, `segmentation.training`, `segmentation.prediction`
- **Interest based Audience Segmentation**: feature-creation-auto-audience-segmentation, auto_segmentation.training, auto_segmentation.prediction
- **Purchase Propensity**: `feature-creation-purchase-propensity`, `propensity.training`, `propensity.prediction`
- **Customer Lifetime Value**: `feature-creation-customer-ltv`, `propensity_clv.training`, `clv.training`, `clv.prediction`

After you change these configurations, make sure you apply these changes in your deployed resources by re-running terraform.

```bash
terraform -chdir="${TERRAFORM_RUN_DIR}" apply
```

You can trigger your Cloud Workflow to execute your Dataform workflow at any time, or you can wait until the next day when the Cloud Workflow is going to be executed according to your schedule. There are two components in this solution that requires data for proper installation and functioning. One is the Looker Studio Dashboard, you only deploy the dashboard after you have executed all the steps in this Guide successfully. Another is the ML pipeline, the pipelines compilation requires views and tables to be created so that it can read their schema and define the column transformations to run during the pipeline execution.

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

    ## Backfill purchase propensity tables
    CALL `feature_store.invoke_backfill_user_dimensions`();
    CALL `feature_store.invoke_backfill_user_rolling_window_metrics`();
    CALL `feature_store.invoke_backfill_purchase_propensity_label`();

    ## Backfill audience segmentation tables
    CALL `feature_store.invoke_backfill_user_segmentation_dimensions`();
    CALL `feature_store.invoke_backfill_user_lookback_metrics`()
    ```

    **Note:** If you have a considerable amount of data (>XXX GBs of data) in your exported GA4 BigQuery datasets over the last six months, it can take several hours to backfill the feature data so that you can train your ML model. Make sure that the backfill procedures starts without errors before you continue to the next step.

1. Redeploy the ML pipelines using Terraform.

    On your code editor, change the variable `deploy_pipelines` from `true` to `false`, on the TF variables file `${TERRAFORM_RUN_DIR}/terraform.tfvars`.
    Next, undeploy the ML pipelines component by applying the terraform configuration.

    ```bash
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply
    ```

    Now, to deploy the ML pipelines component again, revert your changes on the TF variables file `${TERRAFORM_RUN_DIR}/terraform.tfvars` and apply the terraform configuration by running the commad above again.

    **Note:** The training pipelines use schemas defined by a `custom_transformations` parameter in your `config.yaml` or by the training table/view schema itself.
              So at first, during the first deployment i.e. `tf apply`, because the views are not created yet, we assume a fixed schema in case no `custom_transformations` parameter is provided.
              Then, you need to redeploy to make sure that since all the table views exist now, redeploy the pipelines to make sure you fetch the right schema to be provided to the training pipelines.

