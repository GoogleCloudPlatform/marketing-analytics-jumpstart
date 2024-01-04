Configuration for Google Cloud Project and Services

## Overall Configuration

google_cloud_project:

project_id: Placeholder for the actual Google Cloud project ID.
project_name: Placeholder for the project name.
project_number: Placeholder for the project number.
region: Placeholder for the cloud region where resources will be deployed.
cloud_build:

project_id: Placeholder for the project ID, used for Cloud Build configuration.
region: Placeholder for the region where Cloud Build will run.
github:
owner: Placeholder for the GitHub owner of the pipelines repository.
repo_name: Placeholder for the pipelines repository name.
trigger_branch: Specifies the branch that will trigger Cloud Build pipelines (set to "dev").
build_file: Specifies the path to the Cloud Build configuration file (cloudbuild/pipelines.yaml).
_REPOSITORY_GCP_PROJECT, _REPOSITORY_NAME, _REPOSITORY_BRANCH, _GCR_HOSTNAME, _BUILD_REGION: Internal variables likely used by Cloud Build for repository and region information.
container:

builder: Defines configurations for base container images used for building and formatting.
base:
from_image: Specifies the base image for building (python:3.7-alpine3.7).
base_image_name, base_image_prefix: Placeholders for custom image names.
zetasql:
from_image: Specifies the base image for ZetaSQL formatting (wbsouza/zetasql-formatter:latest).
base_image_name, base_image_prefix: Placeholders for custom image names.
container_registry_hostname: Placeholder for the container registry hostname.
container_registry_region: Placeholder for the container registry region.
artifact_registry:

pipelines_repo:
name: Name of the Artifact Registry repository for pipelines artifacts.
region: Region of the repository.
project_id: Project ID associated with the repository.
pipelines_docker_repo:
name: Name of the Artifact Registry repository for Docker images.
region: Region of the repository.
project_id: Project ID associated with the repository.
dataflow:

worker_service_account_id: ID of the service account used by Dataflow workers.
worker_service_account: Full email address of the service account.

## Vertex AI Configuration

1. Components:

Vertex AI: The platform for building and managing machine learning pipelines and models.
Feature Store: A centralized repository for storing and managing features used in model training and prediction.
Pipelines: Automated workflows that orchestrate various tasks, including data preparation, feature engineering, model training, evaluation, and prediction.
Models: Machine learning models trained to make predictions or classifications.
2. Pipelines:

Feature Creation Pipelines:
feature-creation-auto-audience-segmentation
feature-creation-audience-segmentation
feature-creation-purchase-propensity
feature-creation-customer-ltv
Purpose: Prepare data for model training and prediction by generating necessary features.
Training Pipelines:
propensity-training-pl
segmentation-training-pl
propensity_clv-training-pl
Purpose: Train machine learning models using prepared data.
Prediction Pipelines:
propensity-prediction-pl
segmentation-prediction-pl
auto-segmentation-prediction-pl
Purpose: Generate predictions using trained models on new data.
3. Key Parameters:

Project ID: Identifier for the Google Cloud project.
Location: Region where pipelines and resources are located.
Schedules: Cron expressions defining pipeline execution times.
Data Sources: BigQuery tables containing training and prediction data.
Features: Columns used for model training and prediction.
Models: Trained machine learning models.
4. Workflows:

Propensity:
Train a model to predict purchase likelihood for users.
Generate predictions for new users.
Segmentation:
Train a clustering model to group users based on similar characteristics.
Assign new users to their respective segments.
Auto Segmentation:
Generates user segments based on interest using a pre-trained model.
Propensity CLV:
Combines purchase propensity and customer lifetime value (LTV) predictions.
5. Vertex AI Components:

Tabular Workflows: Pre-built components for training and deploying tabular models.
Custom Components: User-defined components for specific tasks.


## BigQuery Configuration

Datasets:

feature_store: Houses various feature tables, serving as the central repository for features used in machine learning models.
purchase_propensity, customer_lifetime_value, audience_segmentation, auto_audience_segmentation: Dedicated datasets for specific use cases, likely containing training data, model artifacts, and inference results.

Tables:

user_dimensions, user_lifetime_dimensions, user_lookback_metrics, user_rolling_window_lifetime_metrics, user_rolling_window_metrics, user_scoped_lifetime_metrics, user_scoped_metrics, user_scoped_segmentation_metrics, user_segmentation_dimensions, user_session_event_aggregated_metrics: Feature tables within the feature_store, each capturing distinct aspects of user behavior and attributes.
purchase_propensity_label, customer_lifetime_value_label: Tables containing labels for supervised learning tasks (purchase propensity and customer lifetime value prediction).
purchase_propensity_inference_preparation, customer_lifetime_value_inference_preparation, audience_segmentation_inference_preparation, auto_audience_segmentation_inference_preparation: Tables likely used for preparing data for model inference.

Stored Procedures:

audience_segmentation_training_preparation, customer_lifetime_value_training_preparation, purchase_propensity_training_preparation, user_dimensions, user_lifetime_dimensions, user_lookback_metrics, user_rolling_window_lifetime_metrics, user_rolling_window_metrics, user_scoped_lifetime_metrics, user_scoped_metrics, user_scoped_segmentation_metrics, user_segmentation_dimensions, customer_lifetime_value_label, purchase_propensity_label: Procedures responsible for populating feature tables, generating labels, and potentially preparing data for training and inference.

Queries:

invoke_purchase_propensity_training_preparation, invoke_audience_segmentation_training_preparation, invoke_customer_lifetime_value_training_preparation, invoke_backfill_...: Queries that call the stored procedures to execute various data preparation and feature engineering tasks.

Key Points:

The YAML file outlines configurations for various Google Cloud services, likely within a pipeline setup.
It extensively uses placeholders to be populated with actual values during deployment.
Cloud Build is set up to trigger on changes in the "dev" branch of a specified GitHub repository.
Base container images are defined for building and ZetaSQL formatting tasks.
Artifact Registry repositories are configured for storing pipelines artifacts and Docker images.
A specific service account is designated for Dataflow workers.
The configuration demonstrates a well-structured BigQuery setup for managing features and supporting different machine learning use cases.
The use of stored procedures and queries suggests a modular and reusable approach to data processing.
The separation of datasets for different use cases aligns with best practices for data organization.