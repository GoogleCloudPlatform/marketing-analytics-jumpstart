# Copyright 2023 Google LLC
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

# This resource creates a BigQuery dataset called `feature_store`.
resource "google_bigquery_dataset" "feature_store" {
  dataset_id                 = local.config_bigquery.dataset.feature_store.name
  friendly_name              = local.config_bigquery.dataset.feature_store.friendly_name
  project                    = local.feature_store_project_id
  description                = local.config_bigquery.dataset.feature_store.description
  location                   = local.config_bigquery.dataset.feature_store.location
  # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries. 
  # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.feature_store.max_time_travel_hours configuration.
  max_time_travel_hours      = local.config_bigquery.dataset.feature_store.max_time_travel_hours
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to false, which means that the contents of the dataset will not be deleted when the dataset is destroyed.
  delete_contents_on_destroy = false

  labels = {
    version = "prod"
  }

  # The lifecycle block allows you to configure the lifecycle of the dataset. 
  # In this case, the ignore_changes attribute is set to all, which means that 
  # Terraform will ignore any changes to the dataset and will not attempt to update the dataset.
  lifecycle {
    ignore_changes = all
  }
}

# This resource creates a BigQuery dataset called `purchase_propensity`.
resource "google_bigquery_dataset" "purchase_propensity" {
  dataset_id                 = local.config_bigquery.dataset.purchase_propensity.name
  friendly_name              = local.config_bigquery.dataset.purchase_propensity.friendly_name
  project                    = local.purchase_propensity_project_id
  description                = local.config_bigquery.dataset.purchase_propensity.description
  location                   = local.config_bigquery.dataset.purchase_propensity.location
  # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries. 
  # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.feature_store.max_time_travel_hours configuration.
  max_time_travel_hours      = local.config_bigquery.dataset.purchase_propensity.max_time_travel_hours
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to false, which means that the contents of the dataset will not be deleted when the dataset is destroyed.
  delete_contents_on_destroy = false

  labels = {
    version = "prod"
  }

  # The lifecycle block allows you to configure the lifecycle of the dataset. 
  # In this case, the ignore_changes attribute is set to all, which means that 
  # Terraform will ignore any changes to the dataset and will not attempt to update the dataset.
  lifecycle {
    ignore_changes = all
  }
}

# This resource creates a BigQuery dataset called `customer_lifetime_value`.
resource "google_bigquery_dataset" "customer_lifetime_value" {
  dataset_id                 = local.config_bigquery.dataset.customer_lifetime_value.name
  friendly_name              = local.config_bigquery.dataset.customer_lifetime_value.friendly_name
  project                    = local.customer_lifetime_value_project_id
  description                = local.config_bigquery.dataset.customer_lifetime_value.description
  location                   = local.config_bigquery.dataset.customer_lifetime_value.location
  # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries. 
  # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.customer_lifetime_value.max_time_travel_hours configuration.
  max_time_travel_hours      = local.config_bigquery.dataset.customer_lifetime_value.max_time_travel_hours
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to false, which means that the contents of the dataset will not be deleted when the dataset is destroyed.
  delete_contents_on_destroy = false

  labels = {
    version = "prod"
  }

  # The lifecycle block allows you to configure the lifecycle of the dataset. 
  # In this case, the ignore_changes attribute is set to all, which means that 
  # Terraform will ignore any changes to the dataset and will not attempt to update the dataset.
  lifecycle {
    ignore_changes = all
  }
}

# This resource creates a BigQuery dataset called `audience_segmentation`.
resource "google_bigquery_dataset" "audience_segmentation" {
  dataset_id                 = local.config_bigquery.dataset.audience_segmentation.name
  friendly_name              = local.config_bigquery.dataset.audience_segmentation.friendly_name
  project                    = local.audience_segmentation_project_id
  description                = local.config_bigquery.dataset.audience_segmentation.description
  location                   = local.config_bigquery.dataset.audience_segmentation.location
  # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries. 
  # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.audience_segmentation.max_time_travel_hours configuration.
  max_time_travel_hours      = local.config_bigquery.dataset.audience_segmentation.max_time_travel_hours
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to false, which means that the contents of the dataset will not be deleted when the dataset is destroyed.
  delete_contents_on_destroy = false

  labels = {
    version = "prod"
  }

  # The lifecycle block allows you to configure the lifecycle of the dataset. 
  # In this case, the ignore_changes attribute is set to all, which means that 
  # Terraform will ignore any changes to the dataset and will not attempt to update the dataset.
  lifecycle {
    ignore_changes = all
  }
}

# This resource creates a BigQuery dataset called `auto_audience_segmentation`.
resource "google_bigquery_dataset" "auto_audience_segmentation" {
  dataset_id                 = local.config_bigquery.dataset.auto_audience_segmentation.name
  friendly_name              = local.config_bigquery.dataset.auto_audience_segmentation.friendly_name
  project                    = local.auto_audience_segmentation_project_id
  description                = local.config_bigquery.dataset.auto_audience_segmentation.description
  location                   = local.config_bigquery.dataset.auto_audience_segmentation.location
  # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries. 
  # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.auto_audience_segmentation.max_time_travel_hours configuration.
  max_time_travel_hours      = local.config_bigquery.dataset.auto_audience_segmentation.max_time_travel_hours
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to false, which means that the contents of the dataset will not be deleted when the dataset is destroyed.
  delete_contents_on_destroy = false

  labels = {
    version = "prod"
  }

  # The lifecycle block allows you to configure the lifecycle of the dataset. 
  # In this case, the ignore_changes attribute is set to all, which means that 
  # Terraform will ignore any changes to the dataset and will not attempt to update the dataset.
  lifecycle {
    ignore_changes = all
  }
}

locals {
  aggregated_vbb_tables = [
    "vbb_weights",
    "aggregated_value_based_bidding_correlation",
    "aggregated_value_based_bidding_volume_daily",
    "aggregated_value_based_bidding_volume_weekly"
  ]
}

# This resource creates a BigQuery dataset called `aggregated_vbb`.
# For existing users that has pulled this change will result in that 
# terraform try to created the `aggregated_vbb` dataset along with 
# the underlying tables. terraform apply will result in an error saying 
# it failed to create resources that are already exist. To resolve you 
# need to import the the existing dataset and tables to terraform using 
# the following commands:
# > `terraform import module.feature_store[0].module.aggregated_vbb.google_bigquery_dataset.main 'projects/${MAJ_FEATURE_STORE_PROJECT_ID}/datasets/aggregated_vbb'`
#
# > `terraform import 'module.feature_store[0].module.aggregated_vbb.google_bigquery_table.main["vbb_weights"]' 'projects/${MAJ_FEATURE_STORE_PROJECT_ID}/datasets/aggregated_vbb/tables/vbb_weights`
#
# > `terraform import 'module.feature_store[0].module.aggregated_vbb.google_bigquery_table.main["aggregated_value_based_bidding_volume_weekly"]' 'projects/${MAJ_FEATURE_STORE_PROJECT_ID}/datasets/aggregated_vbb/tables/aggregated_value_based_bidding_volume_weekly'`
#
# > `terraform import 'module.feature_store[0].module.aggregated_vbb.google_bigquery_table.main["aggregated_value_based_bidding_correlation"]' 'projects/${MAJ_FEATURE_STORE_PROJECT_ID}/datasets/aggregated_vbb/tables/aggregated_value_based_bidding_correlation'`
#
# > `terraform import 'module.feature_store[0].module.aggregated_vbb.google_bigquery_table.main["aggregated_value_based_bidding_volume_daily"]' 'projects/${MAJ_FEATURE_STORE_PROJECT_ID}/datasets/aggregated_vbb/tables/aggregated_value_based_bidding_volume_daily'`
#
# You also need to remove the information of the existing aggregated_vbb 
# dataset from the terraform state by running following command:
# > `terraform state rm 'module.feature_store[0].google_bigquery_dataset.aggregated_vbb'`
module "aggregated_vbb" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 5.4"

  dataset_id   = local.config_bigquery.dataset.aggregated_vbb.name
  dataset_name = local.config_bigquery.dataset.aggregated_vbb.friendly_name
  description  = local.config_bigquery.dataset.aggregated_vbb.description
  project_id   = local.aggregated_vbb_project_id
  location     = local.config_bigquery.dataset.aggregated_vbb.location
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to false, which means that the contents of the dataset will not be deleted when the dataset is destroyed.
  delete_contents_on_destroy = false

  dataset_labels = {
    version = "prod"
  }

  tables = [for table_id in local.aggregated_vbb_tables :
  {
    table_id           = table_id
    schema             = file("../../sql/schema/table/${table_id}.json")
    # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries.
    # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.auto_audience_segmentation.max_time_travel_hours configuration.
    max_time_travel_hours = local.config_bigquery.dataset.aggregated_vbb.max_time_travel_hours
    deletion_protection = true
    time_partitioning  = null,
    range_partitioning = null,
    expiration_time    = null,
    clustering         = [],
    labels             = {},
  }]
}

# This module creates a BigQuery dataset called `aggregated_predictions` and a table called "latest".
# The aggregated_predictions module is used to create a BigQuery dataset and table that will be used to store 
# the aggregated predictions generated by the predictions pipelines.
module "aggregated_predictions" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 5.4"

  dataset_id                 = local.config_bigquery.dataset.aggregated_predictions.name
  dataset_name               = local.config_bigquery.dataset.aggregated_predictions.friendly_name
  description                = local.config_bigquery.dataset.aggregated_predictions.description
  project_id                 = local.config_bigquery.dataset.aggregated_predictions.project_id
  location                   = local.config_bigquery.dataset.aggregated_predictions.location
  # The delete_contents_on_destroy attribute specifies whether the contents of the dataset should be deleted when the dataset is destroyed. 
  # In this case, the delete_contents_on_destroy attribute is set to true, which means that the contents of the dataset will be deleted when the dataset is destroyed.
  delete_contents_on_destroy = true

  # The tables attribute is used to configure the BigQuery table within the dataset
  tables = [
    {
      table_id           = "latest"
      # The schema of the table, defined in a JSON file.
      schema             = file("../../sql/schema/table/aggregated_predictions_latest.json")
      time_partitioning  = null,
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels             = {},
    }
  ]
}