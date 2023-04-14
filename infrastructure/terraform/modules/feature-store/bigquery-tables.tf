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

resource "google_bigquery_table" "audience_segmentation_inference_preparation" {
  dataset_id          = google_bigquery_dataset.audience_segmentation.dataset_id
  table_id            = "audience_segmentation_inference_preparation"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/audience_segmentation_inference_preparation.json")
}


resource "google_bigquery_table" "customer_lifetime_value_inference_preparation" {
  dataset_id          = google_bigquery_dataset.customer_lifetime_value.dataset_id
  table_id            = "customer_lifetime_value_inference_preparation"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/customer_lifetime_value_inference_preparation.json")
}

resource "google_bigquery_table" "customer_lifetime_value_label" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "customer_lifetime_value_label"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/customer_lifetime_value_label.json")
}

resource "google_bigquery_table" "purchase_propensity_inference_preparation" {
  dataset_id          = google_bigquery_dataset.purchase_propensity.dataset_id
  table_id            = "purchase_propensity_inference_preparation"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_inference_preparation.json")
}

resource "google_bigquery_table" "purchase_propensity_label" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "purchase_propensity_label"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/purchase_propensity_label.json")
}

resource "google_bigquery_table" "user_dimensions" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_dimensions"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_dimensions.json")
}

resource "google_bigquery_table" "user_lifetime_dimensions" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_lifetime_dimensions"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_lifetime_dimensions.json")
}


resource "google_bigquery_table" "user_lookback_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_lookback_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_lookback_metrics.json")
}


resource "google_bigquery_table" "invoke_user_rolling_window_lifetime_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_rolling_window_lifetime_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_rolling_window_lifetime_metrics.json")
}

resource "google_bigquery_table" "user_rolling_window_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_rolling_window_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_rolling_window_metrics.json")
}

resource "google_bigquery_table" "user_scoped_lifetime_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_scoped_lifetime_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_scoped_lifetime_metrics.json")
}

resource "google_bigquery_table" "user_scoped_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_scoped_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_scoped_metrics.json")
}

resource "google_bigquery_table" "user_scoped_segmentation_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_scoped_segmentation_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_scoped_segmentation_metrics.json")
}

resource "google_bigquery_table" "user_segmentation_dimensions" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_segmentation_dimensions"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_segmentation_dimensions.json")
}
resource "google_bigquery_table" "user_session_event_aggregated_metrics" {
  dataset_id          = google_bigquery_dataset.feature_store.dataset_id
  table_id            = "user_session_event_aggregated_metrics"
  deletion_protection = false
  labels = {
    env = "dev"
  }
  schema = file("${local.sql_dir}/schema/table/user_session_event_aggregated_metrics.json")
}


