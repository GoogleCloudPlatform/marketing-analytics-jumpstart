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
  config_vars                           = yamldecode(data.local_file.config_vars.content)
  config_bigquery                       = local.config_vars.bigquery
  feature_store_project_id              = local.config_vars.bigquery.dataset.feature_store.project_id
  sql_dir                               = var.sql_dir_input
  builder_repository_id                 = "marketing-analytics-jumpstart-base-repo"
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.1.0"

  disable_dependent_services  = true
  disable_services_on_destroy = false

  project_id = local.feature_store_project_id

  activate_apis = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "aiplatform.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "storage.googleapis.com",
    "sourcerepo.googleapis.com",
    "storage-api.googleapis.com",
  ]
}

# This resource executes gcloud commands to check whether the BigQuery API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_bigquery_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "bigquery.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "bigquery api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }
}

