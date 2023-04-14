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
  dataset_id    = "feature_store"
  friendly_name = "feature_store"
  project       = local.feature_store_project_id
  description   = "Feature Store"
  location      = "US"
  labels = {
    env = "dev"
  }
}

resource "google_bigquery_dataset" "purchase_propensity" {
  dataset_id    = "purchase_propensity"
  friendly_name = "purchase_propensity"
  project       = local.purchase_propensity_project_id
  description   = "Purchase Propensity Use Case"
  location      = "US"
  labels = {
    env = "dev"
  }
}

resource "google_bigquery_dataset" "audience_segmentation" {
  dataset_id    = "audience_segmentation"
  friendly_name = "audience_segmentation"
  project       = local.audience_segmentation_project_id
  description   = "Audience Segmentation Use Case"
  location      = "US"
  labels = {
    env = "dev"
  }
}

resource "google_bigquery_dataset" "customer_lifetime_value" {
  dataset_id    = "customer_lifetime_value"
  friendly_name = "customer_lifetime_value"
  project       = local.customer_lifetime_value_project_id
  description   = "Customer Lifetime Value Use Case"
  location      = "US"
  labels = {
    env = "dev"
  }
}

