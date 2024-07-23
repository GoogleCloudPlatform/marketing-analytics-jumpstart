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

locals {
  datasets = tomap({
    feature_store = {
      name                  = "feature_store"
      friendly_name         = "Feature Store"
      description           = "Feature Store dataset for Marketing behavioural modeling"
      max_time_travel_hours = 168
    },
    purchase_propensity = {
      name                  = "purchase_propensity"
      friendly_name         = "Purchase Propensity Dataset"
      description           = "Purchase Propensity Use Case dataset for Marketing behavioural modeling"
      max_time_travel_hours = 168
    },
    churn_propensity = {
      name                  = "churn_propensity"
      friendly_name         = "Churn Propensity Dataset"
      description           = "Churn Propensity Use Case dataset for Marketing behavioural modeling"
      max_time_travel_hours = 168
    },
    customer_lifetime_value = {
      name                  = "customer_lifetime_value"
      friendly_name         = "Customer Lifetime Value Dataset"
      description           = "Customer Lifetime Value Use Case dataset for Marketing behavioural modeling"
      max_time_travel_hours = 168
    },
    audience_segmentation = {
      name                  = "audience_segmentation"
      friendly_name         = "Audience Segmentation Dataset"
      description           = "Audience Segmentation Use Case dataset for Marketing behavioural modeling"
      max_time_travel_hours = 168
    },
    auto_audience_segmentation = {
      name                  = "auto_audience_segmentation"
      friendly_name         = "Auto Audience Segmentation Dataset"
      description           = "Auto Audience Segmentation Use Case dataset for Marketing behavioural modeling"
      max_time_travel_hours = 168
    },
    aggregated_vbb = {
      name                  = "aggregated_vbb"
      friendly_name         = "Aggregated VBB Dataset"
      description           = "Aggregated VBB Use Case dataset for Marketing behavioural modeling"
      max_time_travel_hours = 48
    },
    aggregated_predictions = {
      name                  = "aggregated_predictions"
      friendly_name         = "Aggregated Predictions Dataset"
      description           = "Dataset with aggregated prediction results from multiple use cases"
      max_time_travel_hours = 48
    },
    gemini_insights = {
      name                  = "gemini_insights"
      friendly_name         = "Gemini Insights Dataset"
      description           = "Dataset with gemini_insights results from multiple use cases"
      max_time_travel_hours = 48
    },
  })
}

resource "google_bigquery_dataset" "datasets" {
  for_each                   = local.datasets
  dataset_id                 = each.value.name
  friendly_name              = each.value.friendly_name
  project                    = var.project_id
  description                = each.value.description
  location                   = var.data_location
  max_time_travel_hours      = each.value.max_time_travel_hours
  delete_contents_on_destroy = false
  labels = {
    version = "prod"
  }
  depends_on = [null_resource.check_bigquery_api]
}