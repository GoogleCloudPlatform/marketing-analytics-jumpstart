# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

data "google_project" "data" {
  project_id = var.data_project_id
}

data "google_project" "data_processing" {
  project_id = var.data_processing_project_id
}

data "google_secret_manager_secret" "github_secret_name" {
  secret_id = google_secret_manager_secret.github-secret.name
  project   = var.data_processing_project_id
}

provider "google" {
  region = var.google_default_region
}

# This module sets up a Dataform workflow environment for the "dev" environment. 
module "dataform-workflow-dev" {
  # The count argument specifies how many instances of the module should be created. 
  # In this case, it's set to var.create_dev_environment ? 1 : 0, which means that 
  # the module will be created only if the var.create_dev_environment variable is set to `true`.
  # Check the terraform.tfvars file for more information.
  count  = var.create_dev_environment ? 1 : 0
  # the path to the Terraform module that will be used to create the Dataform workflow environment.
  source = "../dataform-workflow"

  project_id             = null_resource.check_dataform_api.id != "" ?  module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
  # The name of the Dataform workflow environment.
  environment            = "dev"
  region                 = var.google_default_region
  # The ID of the Dataform repository that will be used by the Dataform workflow environment.
  dataform_repository_id = google_dataform_repository.marketing-analytics.id
  # A list of tags that will be used to filter the Dataform files that are included in the Dataform workflow environment.
  includedTags           = ["ga4"]

  source_ga4_export_project_id          = var.source_ga4_export_project_id
  source_ga4_export_dataset             = var.source_ga4_export_dataset
  ga4_incremental_processing_days_back  = var.ga4_incremental_processing_days_back
  source_ads_export_data                = var.source_ads_export_data
  destination_bigquery_project_id       = length(var.dev_data_project_id) > 0 ? var.staging_data_project_id : var.data_project_id
  destination_bigquery_dataset_location = length(var.dev_destination_data_location) > 0 ? var.dev_destination_data_location : var.destination_data_location

  # The daily schedule for running the Dataform workflow.
  # Depending on the hour that your Google Analytics 4 BigQuery Export is set, 
  # you may have to change this to execute at a later time of the day.
  # Observe that the GA4 BigQuery Export Schedule documentation 
  # https://support.google.com/analytics/answer/9358801?hl=en#:~:text=A%20full%20export%20of%20data,(see%20Streaming%20export%20below).
  # Check https://crontab.guru/#0_5-23/4_*_*_* to see next execution times.
  daily_schedule = "0 5-23/4 * * *"
}

# This module sets up a Dataform workflow environment for the "staging" environment. 
module "dataform-workflow-staging" {
  # The count argument specifies how many instances of the module should be created. 
  # In this case, it's set to var.create_staging_environment ? 1 : 0, which means that 
  # the module will be created only if the var.create_staging_environment variable is set to `true`.
  # Check the terraform.tfvars file for more information.
  count  = var.create_staging_environment ? 1 : 0
  # the path to the Terraform module that will be used to create the Dataform workflow environment.
  source = "../dataform-workflow"

  project_id             = null_resource.check_dataform_api.id != "" ?  module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
  # The name of the Dataform workflow environment.
  environment            = "staging"
  region                 = var.google_default_region
  # The ID of the Dataform repository that will be used by the Dataform workflow environment.
  dataform_repository_id = google_dataform_repository.marketing-analytics.id
  # A list of tags that will be used to filter the Dataform files that are included in the Dataform workflow environment.
  includedTags           = ["ga4"]

  source_ga4_export_project_id          = var.source_ga4_export_project_id
  source_ga4_export_dataset             = var.source_ga4_export_dataset
  source_ads_export_data                = var.source_ads_export_data
  destination_bigquery_project_id       = length(var.staging_data_project_id) > 0 ? var.staging_data_project_id : var.data_project_id
  destination_bigquery_dataset_location = length(var.staging_destination_data_location) > 0 ? var.staging_destination_data_location : var.destination_data_location

  # The daily schedule for running the Dataform workflow.
  # Depending on the hour that your Google Analytics 4 BigQuery Export is set, 
  # you may have to change this to execute at a later time of the day.
  # Observe that the GA4 BigQuery Export Schedule documentation 
  # https://support.google.com/analytics/answer/9358801?hl=en#:~:text=A%20full%20export%20of%20data,(see%20Streaming%20export%20below).
  # Check https://crontab.guru/#0_5-23/4_*_*_* to see next execution times.
  daily_schedule = "0 5-23/4 * * *"
}

# This module sets up a Dataform workflow environment for the "prod" environment. 
module "dataform-workflow-prod" {
  # The count argument specifies how many instances of the module should be created. 
  # In this case, it's set to var.create_prod_environment ? 1 : 0, which means that 
  # the module will be created only if the var.create_prod_environment variable is set to `true`.
  # Check the terraform.tfvars file for more information.
  count  = var.create_prod_environment ? 1 : 0
  # the path to the Terraform module that will be used to create the Dataform workflow environment.
  source = "../dataform-workflow"

  project_id             = null_resource.check_dataform_api.id != "" ?  module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
  # The name of the Dataform workflow environment.
  environment            = "prod"
  region                 = var.google_default_region
  dataform_repository_id = google_dataform_repository.marketing-analytics.id

  source_ga4_export_project_id          = var.source_ga4_export_project_id
  source_ga4_export_dataset             = var.source_ga4_export_dataset
  source_ads_export_data                = var.source_ads_export_data
  destination_bigquery_project_id       = length(var.prod_data_project_id) > 0 ? var.staging_data_project_id : var.data_project_id
  destination_bigquery_dataset_location = length(var.prod_destination_data_location) > 0 ? var.prod_destination_data_location : var.destination_data_location

  # The daily schedule for running the Dataform workflow.
  # Depending on the hour that your Google Analytics 4 BigQuery Export is set, 
  # you may have to change this to execute at a later time of the day.
  # Observe that the GA4 BigQuery Export Schedule documentation 
  # https://support.google.com/analytics/answer/9358801?hl=en#:~:text=A%20full%20export%20of%20data,(see%20Streaming%20export%20below).
  # Check https://crontab.guru/#0_5-23/2_*_*_* to see next execution times.
  daily_schedule = "0 5-23/2 * * *"
}
