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

resource "google_bigquery_dataset" "feature_store" {
  dataset_id            = local.config_bigquery.dataset.feature_store.name
  friendly_name         = local.config_bigquery.dataset.feature_store.friendly_name
  project               = local.feature_store_project_id
  description           = local.config_bigquery.dataset.feature_store.description
  location              = local.config_bigquery.dataset.feature_store.location
  max_time_travel_hours = local.config_bigquery.dataset.feature_store.max_time_travel_hours

  labels = {
    version = "pilot"
  }
}

resource "google_bigquery_dataset" "purchase_propensity" {
  dataset_id            = local.config_bigquery.dataset.purchase_propensity.name
  friendly_name         = local.config_bigquery.dataset.purchase_propensity.friendly_name
  project               = local.purchase_propensity_project_id
  description           = local.config_bigquery.dataset.purchase_propensity.description
  location              = local.config_bigquery.dataset.purchase_propensity.location
  max_time_travel_hours = local.config_bigquery.dataset.purchase_propensity.max_time_travel_hours

  labels = {
    version = "pilot"
  }
}

resource "google_bigquery_dataset" "customer_lifetime_value" {
  dataset_id            = local.config_bigquery.dataset.customer_lifetime_value.name
  friendly_name         = local.config_bigquery.dataset.customer_lifetime_value.friendly_name
  project               = local.customer_lifetime_value_project_id
  description           = local.config_bigquery.dataset.customer_lifetime_value.description
  location              = local.config_bigquery.dataset.customer_lifetime_value.location
  max_time_travel_hours = local.config_bigquery.dataset.customer_lifetime_value.max_time_travel_hours

  labels = {
    version = "pilot"
  }
}

resource "google_bigquery_dataset" "audience_segmentation" {
  dataset_id            = local.config_bigquery.dataset.audience_segmentation.name
  friendly_name         = local.config_bigquery.dataset.audience_segmentation.friendly_name
  project               = local.audience_segmentation_project_id
  description           = local.config_bigquery.dataset.audience_segmentation.description
  location              = local.config_bigquery.dataset.audience_segmentation.location
  max_time_travel_hours = local.config_bigquery.dataset.audience_segmentation.max_time_travel_hours

  labels = {
    version = "pilot"
  }
}

resource "google_bigquery_dataset" "auto_audience_segmentation" {
  dataset_id            = local.config_bigquery.dataset.auto_audience_segmentation.name
  friendly_name         = local.config_bigquery.dataset.auto_audience_segmentation.friendly_name
  project               = local.auto_audience_segmentation_project_id
  description           = local.config_bigquery.dataset.auto_audience_segmentation.description
  location              = local.config_bigquery.dataset.auto_audience_segmentation.location
  max_time_travel_hours = local.config_bigquery.dataset.auto_audience_segmentation.max_time_travel_hours

  labels = {
    version = "pilot"
  }
}