# Copyright 2025 Google LLC
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


# This resource creates a BigQuery table named predictions_placeholder
# in the dataset specified by google_bigquery_dataset.purchase_propensity
resource "google_bigquery_table" "purchase_propurchase_propensity_predictions_placeholder" {
  project     = google_bigquery_dataset.purchase_propensity.project
  dataset_id  = google_bigquery_dataset.purchase_propensity.dataset_id
  table_id    = "predictions_placeholder"
  description = "Dummy table to facilitate the creation of down stream dependent views"

  # The deletion_protection attribute specifies whether the table should be protected from deletion. In this case, it's set to false, which means that the table can be deleted.
  deletion_protection = false
  labels = {
    version = "prod"
  }

  # The schema attribute specifies the schema of the table. In this case, the schema is defined in the JSON file.
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_predictions_placeholder.json")

  # The lifecycle block is used to configure the lifecycle of the table. In this case, the ignore_changes attribute is set to all, which means that Terraform will ignore
  # any changes to the table and will not attempt to update the table.
  lifecycle {
    ignore_changes  = all
  }
}

# This resource creates a BigQuery table named user_rolling_window_metrics 
# in the dataset specified by google_bigquery_dataset.feature_store.dataset_id.
resource "google_bigquery_table" "user_rolling_window_metrics" {
  project     = var.feature_store_project_id
  dataset_id  = var.feature_store_dataset_id
  table_id    = local.config_bigquery.table.user_rolling_window_metrics.table_name
  description = local.config_bigquery.table.user_rolling_window_metrics.table_description

  # The deletion_protection attribute specifies whether the table should be protected from deletion. In this case, it's set to false, which means that the table can be deleted.
  deletion_protection = false
  labels = {
    version = "prod"
  }

  # The schema attribute specifies the schema of the table. In this case, the schema is defined in the JSON file.
  schema = file("${local.sql_dir}/schema/table/user_rolling_window_metrics.json")

  # The lifecycle block is used to configure the lifecycle of the table. In this case, the ignore_changes attribute is set to all, which means that Terraform will ignore 
  # any changes to the table and will not attempt to update the table. The prevent_destroy attribute is set to true, which means that Terraform will prevent the table from being destroyed.
  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# This resource creates a BigQuery table named user_dimensions 
# in the dataset specified by google_bigquery_dataset.feature_store.dataset_id.
resource "google_bigquery_table" "user_dimensions" {
  project     = var.feature_store_project_id
  dataset_id  = var.feature_store_dataset_id
  table_id    = local.config_bigquery.table.user_dimensions.table_name
  description = local.config_bigquery.table.user_dimensions.table_description

  # The deletion_protection attribute specifies whether the table should be protected from deletion. In this case, it's set to false, which means that the table can be deleted.
  deletion_protection = false
  labels = {
    version = "prod"
  }

  # The schema attribute specifies the schema of the table. In this case, the schema is defined in the JSON file.
  schema = file("${local.sql_dir}/schema/table/user_dimensions.json")

  # The lifecycle block is used to configure the lifecycle of the table. In this case, the ignore_changes attribute is set to all, which means that Terraform will ignore 
  # any changes to the table and will not attempt to update the table. The prevent_destroy attribute is set to true, which means that Terraform will prevent the table from being destroyed.
  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}


# This resource creates a BigQuery table named purchase_propensity_label 
# in the dataset specified by google_bigquery_dataset.feature_store.dataset_id.
resource "google_bigquery_table" "purchase_propensity_label" {
  project     = var.feature_store_project_id
  dataset_id  = var.feature_store_dataset_id
  table_id    = local.config_bigquery.table.purchase_propensity_label.table_name
  description = local.config_bigquery.table.purchase_propensity_label.table_description

  # The deletion_protection attribute specifies whether the table should be protected from deletion. In this case, it's set to false, which means that the table can be deleted.
  deletion_protection = false
  labels = {
    version = "prod"
  }

  # The schema attribute specifies the schema of the table. In this case, the schema is defined in the JSON file.
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_label.json")

  # The lifecycle block is used to configure the lifecycle of the table. In this case, the ignore_changes attribute is set to all, which means that Terraform will ignore 
  # any changes to the table and will not attempt to update the table. The prevent_destroy attribute is set to true, which means that Terraform will prevent the table from being destroyed.
  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# This resource creates a BigQuery table named purchase_propensity_inference_preparation 
# in the dataset specified by google_bigquery_dataset.purchase_propensity.dataset_id.
resource "google_bigquery_table" "purchase_propensity_inference_preparation" {
  project     = google_bigquery_dataset.purchase_propensity.project
  dataset_id  = google_bigquery_dataset.purchase_propensity.dataset_id
  table_id    = local.config_bigquery.table.purchase_propensity_inference_preparation.table_name
  description = local.config_bigquery.table.purchase_propensity_inference_preparation.table_description

  # The deletion_protection attribute specifies whether the table should be protected from deletion. In this case, it's set to false, which means that the table can be deleted.
  deletion_protection = false
  labels = {
    version = "prod"
  }

  # The schema attribute specifies the schema of the table. In this case, the schema is defined in the JSON file.
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_inference_preparation.json")
}
