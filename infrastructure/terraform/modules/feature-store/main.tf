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
  purchase_propensity_project_id        = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.purchase_propensity.project_id : local.feature_store_project_id
  churn_propensity_project_id           = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.churn_propensity.project_id : local.feature_store_project_id
  audience_segmentation_project_id      = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.audience_segmentation.project_id : local.feature_store_project_id
  auto_audience_segmentation_project_id = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.auto_audience_segmentation.project_id : local.feature_store_project_id
  aggregated_vbb_project_id             = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.aggregated_vbb.project_id : local.feature_store_project_id
  customer_lifetime_value_project_id    = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.customer_lifetime_value.project_id : local.feature_store_project_id
  aggregate_predictions_project_id      = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.aggregated_predictions.project_id : local.feature_store_project_id
  gemini_insights_project_id            = null_resource.check_bigquery_api.id != "" ? local.config_vars.bigquery.dataset.gemini_insights.project_id : local.feature_store_project_id
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "17.0.0"

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

  depends_on = [
    module.project_services
  ]
}


# This resource executes gcloud commands to check whether the aiplatform API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_aiplatform_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "aiplatform.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "aiplatform api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}


## This creates a cloud resource connection.
## Note: The cloud resource nested object has only one output only field - serviceAccountId.
resource "google_bigquery_connection" "vertex_ai_connection" {
  connection_id = "vertex_ai"
  project       = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.feature_store_project_id
  location      = local.config_bigquery.region
  cloud_resource {}
}


# This resource binds the service account to the required roles
resource "google_project_iam_member" "vertex_ai_connection_sa_roles" {
  depends_on = [
    module.project_services,
    null_resource.check_aiplatform_api,
    google_bigquery_connection.vertex_ai_connection
  ]

  project = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.feature_store_project_id
  member  = "serviceAccount:${google_bigquery_connection.vertex_ai_connection.cloud_resource[0].service_account_id}"

  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/storage.admin",
    "roles/storage.objectViewer",
    "roles/aiplatform.user",
    "roles/bigquery.connectionUser",
    "roles/bigquery.connectionAdmin"
  ])
  role = each.key

  # The lifecycle block is used to configure the lifecycle of the table. In this case, the ignore_changes attribute is set to all, which means that Terraform will ignore 
  # any changes to the table and will not attempt to update the table. The prevent_destroy attribute is set to true, which means that Terraform will prevent the table from being destroyed.
  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_vertex_ai_connection_sa_role_propagation" {
  create_duration = "120s"
  depends_on = [
    google_project_iam_member.vertex_ai_connection_sa_roles
  ]
}


#module "vertex_ai_connection_sa_roles" {
#  source  = "terraform-google-modules/iam/google//modules/member_iam"
#  version = "~> 8.0"
#
#  service_account_address = google_bigquery_connection.vertex_ai_connection.cloud_resource[0].service_account_id
#  project_id              = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.feature_store_project_id
#  project_roles           = [
#    "roles/bigquery.jobUser",
#    "roles/bigquery.dataEditor",
#    "roles/storage.admin",
#    "roles/storage.objectViewer",
#    "roles/aiplatform.user",
#    "roles/bigquery.connectionUser",
#    "roles/bigquery.connectionAdmin"
#    ]
#  prefix                  = "serviceAccount"
#  
#  depends_on = [
#    module.project_services,
#    null_resource.check_aiplatform_api,
#    google_bigquery_connection.vertex_ai_connection
#  ]
#  
#}

