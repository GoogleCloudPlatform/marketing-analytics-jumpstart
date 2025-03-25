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

data "local_file" "config_vars" {
  filename = var.config_file_path
}

locals {
  config_vars                           = yamldecode(data.local_file.config_vars.content)
  config_bigquery                       = local.config_vars.bigquery
  feature_store_project_id              = local.config_vars.bigquery.dataset.feature_store.project_id
  sql_dir                               = var.sql_dir_input
  builder_repository_id                 = "marketing-analytics-jumpstart-base-repo"
  purchase_propensity_project_id        = local.config_vars.bigquery.dataset.purchase_propensity.project_id
}

