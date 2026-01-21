
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


# This resource creates a BigQuery dataset called `purchase_propensity`.
resource "google_bigquery_dataset" "purchase_propensity" {
  dataset_id    = local.config_bigquery.dataset.purchase_propensity.name
  friendly_name = local.config_bigquery.dataset.purchase_propensity.friendly_name
  project       = local.purchase_propensity_project_id
  description   = local.config_bigquery.dataset.purchase_propensity.description
  location      = local.config_bigquery.dataset.purchase_propensity.location
  # The max_time_travel_hours attribute specifies the maximum number of hours that data in the dataset can be accessed using time travel queries. 
  # In this case, the maximum time travel hours is set to the value of the local file config.yaml section bigquery.dataset.feature_store.max_time_travel_hours configuration.
  max_time_travel_hours = local.config_bigquery.dataset.purchase_propensity.max_time_travel_hours
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
