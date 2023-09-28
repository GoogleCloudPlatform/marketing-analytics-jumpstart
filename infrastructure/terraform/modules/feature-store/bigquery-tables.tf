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
# WITHOUT WARRANTIES OR CONDITI} OF ANY KIND, either express or implied.
# See the License for the specific language governing permissi} and
# limitati} under the License.

resource "google_bigquery_table" "audience_segmentation_inference_preparation" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.audience_segmentation.dataset_id
  table_id            = local.config_bigquery.table.audience_segmentation_inference_preparation.table_name
  description         = local.config_bigquery.table.audience_segmentation_inference_preparation.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/audience_segmentation_inference_preparation.json")
}


resource "google_bigquery_table" "customer_lifetime_value_inference_preparation" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.customer_lifetime_value.dataset_id
  table_id            = local.config_bigquery.table.customer_lifetime_value_inference_preparation.table_name
  description         = local.config_bigquery.table.customer_lifetime_value_inference_preparation.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/customer_lifetime_value_inference_preparation.json")
}

resource "google_bigquery_table" "customer_lifetime_value_label" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.customer_lifetime_value_label.table_name
  description         = local.config_bigquery.table.customer_lifetime_value_label.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/customer_lifetime_value_label.json")
}

resource "google_bigquery_table" "purchase_propensity_inference_preparation" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.purchase_propensity.dataset_id
  table_id            = local.config_bigquery.table.purchase_propensity_inference_preparation.table_name
  description         = local.config_bigquery.table.purchase_propensity_inference_preparation.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_inference_preparation.json")
}

resource "google_bigquery_table" "purchase_propensity_label" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.purchase_propensity_label.table_name
  description         = local.config_bigquery.table.purchase_propensity_label.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_label.json")
}

resource "google_bigquery_table" "user_dimensions" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_dimensions.table_name
  description         = local.config_bigquery.table.user_dimensions.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_dimensions.json")
}

resource "google_bigquery_table" "user_lifetime_dimensions" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_lifetime_dimensions.table_name
  description         = local.config_bigquery.table.user_lifetime_dimensions.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_lifetime_dimensions.json")
}


resource "google_bigquery_table" "user_lookback_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_lookback_metrics.table_name
  description         = local.config_bigquery.table.user_lookback_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_lookback_metrics.json")
}


resource "google_bigquery_table" "user_rolling_window_lifetime_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_rolling_window_lifetime_metrics.table_name
  description         = local.config_bigquery.table.user_rolling_window_lifetime_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_rolling_window_lifetime_metrics.json")
}

resource "google_bigquery_table" "user_rolling_window_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_rolling_window_metrics.table_name
  description         = local.config_bigquery.table.user_rolling_window_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_rolling_window_metrics.json")
}

resource "google_bigquery_table" "user_scoped_lifetime_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_scoped_lifetime_metrics.table_name
  description         = local.config_bigquery.table.user_scoped_lifetime_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_scoped_lifetime_metrics.json")
}

resource "google_bigquery_table" "user_scoped_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_scoped_metrics.table_name
  description         = local.config_bigquery.table.user_scoped_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_scoped_metrics.json")
}

resource "google_bigquery_table" "user_scoped_segmentation_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_scoped_segmentation_metrics.table_name
  description         = local.config_bigquery.table.user_scoped_segmentation_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_scoped_segmentation_metrics.json")
}

resource "google_bigquery_table" "user_segmentation_dimensions" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_segmentation_dimensions.table_name
  description         = local.config_bigquery.table.user_segmentation_dimensions.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_segmentation_dimensions.json")
}

resource "google_bigquery_table" "user_session_event_aggregated_metrics" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = local.config_bigquery.table.user_session_event_aggregated_metrics.table_name
  description         = local.config_bigquery.table.user_session_event_aggregated_metrics.table_description
  deletion_protection = true
  labels = {
    version = "pilot"
  }
  schema = file("${local.sql_dir}/schema/table/user_session_event_aggregated_metrics.json")
}


