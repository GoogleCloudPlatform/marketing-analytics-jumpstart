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

data "local_file" "config_vars" {
  filename = var.config_file_path
}

locals {
  source_root_dir                       = "../../.."
  config_vars                           = yamldecode(data.local_file.config_vars.content)
  config_bigquery                       = local.config_vars.bigquery
  feature_store_project_id              = local.config_vars.bigquery.dataset.feature_store.project_id
  sql_dir                               = var.sql_dir_input
  builder_repository_id                 = "marketing-analytics-jumpstart-base-repo"
  purchase_propensity_project_id        = local.config_vars.bigquery.dataset.purchase_propensity.project_id
  churn_propensity_project_id           = local.config_vars.bigquery.dataset.churn_propensity.project_id
  lead_score_propensity_project_id      = local.config_vars.bigquery.dataset.lead_score_propensity.project_id
  audience_segmentation_project_id      = local.config_vars.bigquery.dataset.audience_segmentation.project_id
  auto_audience_segmentation_project_id = local.config_vars.bigquery.dataset.auto_audience_segmentation.project_id
  aggregated_vbb_project_id             = local.config_vars.bigquery.dataset.aggregated_vbb.project_id
  customer_lifetime_value_project_id    = local.config_vars.bigquery.dataset.customer_lifetime_value.project_id
  aggregate_predictions_project_id      = local.config_vars.bigquery.dataset.aggregated_predictions.project_id
  gemini_insights_project_id            = local.config_vars.bigquery.dataset.gemini_insights.project_id
}


module "purchase_propensity" {
  # The source is the path to the feature store module.
  source           = "./purchase-propensity"
  config_file_path = var.config_file_path
  enabled          = var.deploy_purchase_propensity
  # the count determines if the feature store is created or not.
  # If the count is 1, the feature store is created.
  # If the count is 0, the feature store is not created.
  # This is done to avoid creating the feature store if the `deploy_purchase_propensity` variable is set to false in the terraform.tfvars file.
  count      = var.deploy_purchase_propensity ? 1 : 0
  project_id = var.project_id
  # The region is the region in which the feature store is created.
  # This is set to the default region in the terraform.tfvars file.
  region = var.region
  # The sql_dir_input is the path to the sql directory.
  # This is set to the path to the sql directory in the feature store module.
  sql_dir_input = var.sql_dir_input
  feature_store_dataset_id = google_bigquery_dataset.feature_store.dataset_id
  feature_store_project_id = google_bigquery_dataset.feature_store.project
}

module "optional" {
  # The source is the path to the feature store module.
  source           = "./optional"
  config_file_path = var.config_file_path
  enabled          = var.deploy_optional
  # the count determines if the feature store is created or not.
  # If the count is 1, the feature store is created.
  # If the count is 0, the feature store is not created.
  # This is done to avoid creating the feature store if the `deploy_optional` variable is set to false in the terraform.tfvars file.
  count      = var.deploy_optional ? 1 : 0
  project_id = var.project_id
  # The region is the region in which the feature store is created.
  # This is set to the default region in the terraform.tfvars file.
  region = var.region
  # The sql_dir_input is the path to the sql directory.
  # This is set to the path to the sql directory in the feature store module.
  sql_dir_input = var.sql_dir_input
  feature_store_dataset_id = google_bigquery_dataset.feature_store.dataset_id
  feature_store_project_id = google_bigquery_dataset.feature_store.project
}