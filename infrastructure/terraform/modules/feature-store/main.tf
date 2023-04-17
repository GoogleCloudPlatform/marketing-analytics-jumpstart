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

locals {
  config_vars                        = yamldecode(file(var.config_file_path))
  feature_store_project_id           = local.config_vars.bigquery.dataset.feature_store.project_id
  purchase_propensity_project_id     = local.config_vars.bigquery.dataset.purchase_propensity.project_id
  audience_segmentation_project_id   = local.config_vars.bigquery.dataset.audience_segmentation.project_id
  customer_lifetime_value_project_id = local.config_vars.bigquery.dataset.customer_lifetime_value.project_id
  source_root_dir                    = "../.."
  sql_dir                            = "${local.source_root_dir}/sql"
}