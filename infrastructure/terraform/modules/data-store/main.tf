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

provider "google" {
  region = var.google_default_region
}

module "dataform-workflow-dev" {
  count  = var.create_dev_environment ? 1 : 0
  source = "../dataform-workflow"

  project_id             = var.data_processing_project_id
  environment            = "dev"
  region                 = var.google_default_region
  dataform_repository_id = google_dataform_repository.marketing-analytics.id
  includedTags           = ["ga4"]

  source_ga4_export_project_id          = var.source_ga4_export_project_id
  source_ga4_export_dataset             = var.source_ga4_export_dataset
  source_ads_export_data                = var.source_ads_export_data
  destination_bigquery_project_id       = length(var.dev_data_project_id) > 0 ? var.staging_data_project_id : var.data_project_id
  destination_bigquery_dataset_location = length(var.dev_destination_data_location) > 0 ? var.dev_destination_data_location : var.destination_data_location

  daily_schedule = "2 5 * * *"
}

module "dataform-workflow-staging" {
  count  = var.create_staging_environment ? 1 : 0
  source = "../dataform-workflow"

  project_id             = var.data_processing_project_id
  environment            = "staging"
  region                 = var.google_default_region
  dataform_repository_id = google_dataform_repository.marketing-analytics.id
  includedTags           = ["ga4"]

  source_ga4_export_project_id          = var.source_ga4_export_project_id
  source_ga4_export_dataset             = var.source_ga4_export_dataset
  source_ads_export_data                = var.source_ads_export_data
  destination_bigquery_project_id       = length(var.staging_data_project_id) > 0 ? var.staging_data_project_id : var.data_project_id
  destination_bigquery_dataset_location = length(var.staging_destination_data_location) > 0 ? var.staging_destination_data_location : var.destination_data_location

  daily_schedule = "2 6 * * *"
}

module "dataform-workflow-prod" {
  count  = var.create_prod_environment ? 1 : 0
  source = "../dataform-workflow"

  project_id             = var.data_processing_project_id
  environment            = "prod"
  region                 = var.google_default_region
  dataform_repository_id = google_dataform_repository.marketing-analytics.id

  source_ga4_export_project_id          = var.source_ga4_export_project_id
  source_ga4_export_dataset             = var.source_ga4_export_dataset
  source_ads_export_data                = var.source_ads_export_data
  destination_bigquery_project_id       = length(var.prod_data_project_id) > 0 ? var.staging_data_project_id : var.data_project_id
  destination_bigquery_dataset_location = length(var.prod_destination_data_location) > 0 ? var.prod_destination_data_location : var.destination_data_location

  daily_schedule = "2 7 * * *"
}
