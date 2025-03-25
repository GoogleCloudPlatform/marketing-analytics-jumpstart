# Copyright 2022 Google LLC
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

# Check the Dataform Service Account Access Requirements for more information
# https://cloud.google.com/dataform/docs/required-access
locals {
  dataform_sa = "service-${data.google_project.data_processing.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# Wait for the dataform service account to be created
resource "null_resource" "wait_for_dataform_sa_creation" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud asset search-all-iam-policies --scope=projects/${module.data_processing_project_services.project_id} --flatten="policy.bindings[].members[]" --filter="policy.bindings.members~\"serviceAccount:\"" --format="value(policy.bindings.members.split(sep=\":\").slice(1))" | grep -i "${local.dataform_sa}" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 10
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "dataform service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 120
    EOT
  }

  depends_on = [
    google_dataform_repository.marketing-analytics,
    null_resource.check_dataform_api
  ]
}

module "email-role" {
  source  = "terraform-google-modules/iam/google//modules/member_iam"
  version = "~> 8.0"

  service_account_address = var.project_owner_email
  project_id              = null_resource.check_dataform_api.id != "" ? module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
  project_roles           = [
    "roles/iam.serviceAccountUser", // TODO: is it really needed?
    "roles/dataform.admin",
    "roles/dataform.editor"
    ]
  prefix                  = "user"
}
#resource "google_project_iam_member" "email-role" {
#  for_each = toset([
#    "roles/iam.serviceAccountUser", // TODO: is it really needed?
#    "roles/dataform.admin",
#    "roles/dataform.editor"
#  ])
#  role    = each.key
#  member  = "user:${var.project_owner_email}"
#  project = null_resource.check_dataform_api.id != "" ? module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
#}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_email_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.email-role
  ]
}

# This resource sets the Dataform service account IAM member roles
module "dataform-serviceaccount" {
  source  = "terraform-google-modules/iam/google//modules/member_iam"
  version = "~> 8.0"
  depends_on = [
    google_dataform_repository.marketing-analytics,
    null_resource.check_dataform_api,
    null_resource.wait_for_dataform_sa_creation,
    time_sleep.wait_for_email_role_propagation
  ]
  service_account_address = local.dataform_sa
  project_id              = null_resource.check_dataform_api.id != "" ? module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
  project_roles           = [
    "roles/secretmanager.secretAccessor",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataOwner",
    ]
  prefix                  = "serviceAccount"
}
# This resource sets the Dataform service account IAM member roles
#resource "google_project_iam_member" "dataform-serviceaccount" {
#  depends_on = [
#    google_dataform_repository.marketing-analytics,
#    null_resource.check_dataform_api,
#    null_resource.wait_for_dataform_sa_creation,
#    time_sleep.wait_for_email_role_propagation
#  ]
#  for_each = toset([
#    "roles/secretmanager.secretAccessor",
#    "roles/bigquery.jobUser",
#    "roles/bigquery.dataOwner",
#  ])
#  role    = each.key
#  member  = "serviceAccount:${local.dataform_sa}"
#  project = null_resource.check_dataform_api.id != "" ? module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
#}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_dataform-serviceaccount_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.dataform-serviceaccount
  ]
}

// Read access to the GA4 exports
module "dataform-ga4-export-reader" {
  source  = "terraform-google-modules/iam/google//modules/bigquery_datasets_iam"
  version = "~> 8.0"
  depends_on = [
    google_dataform_repository.marketing-analytics,
    null_resource.check_dataform_api,
    null_resource.wait_for_dataform_sa_creation,
    time_sleep.wait_for_dataform-serviceaccount_role_propagation
  ]
  project = var.source_ga4_export_project_id
  bigquery_datasets = [
    var.source_ga4_export_dataset,
  ]
  mode = "authoritative"

  bindings = {
    "roles/bigquery.dataViewer" = [
      "serviceAccount:${local.dataform_sa}",
    ]
    "roles/bigquery.dataEditor" = [
      "serviceAccount:${local.dataform_sa}",
    ]
  }
}
#resource "google_bigquery_dataset_iam_member" "dataform-ga4-export-reader" {
#  depends_on = [
#    google_dataform_repository.marketing-analytics,
#    null_resource.check_dataform_api,
#    null_resource.wait_for_dataform_sa_creation,
#    time_sleep.wait_for_dataform-serviceaccount_role_propagation
#  ]
#  role       = "roles/bigquery.dataViewer"
#  member     = "serviceAccount:${local.dataform_sa}"
#  project    = var.source_ga4_export_project_id
#  dataset_id = var.source_ga4_export_dataset
#}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_dataform-ga4-export-reader_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.dataform-ga4-export-reader
  ]
}

// Read access to the Ads datasets
module "dataform-ads-export-reader" {
  source  = "terraform-google-modules/iam/google//modules/bigquery_datasets_iam"
  version = "~> 8.0"
  depends_on = [
    google_dataform_repository.marketing-analytics,
    null_resource.check_dataform_api,
    null_resource.wait_for_dataform_sa_creation,
    time_sleep.wait_for_dataform-ga4-export-reader_role_propagation
  ]
  count   = length(var.source_ads_export_data)
  project = var.source_ads_export_data[count.index].project
  bigquery_datasets = [
    var.source_ads_export_data[count.index].dataset,
  ]
  mode = "authoritative"

  bindings = {
    "roles/bigquery.dataViewer" = [
      "serviceAccount:${local.dataform_sa}",
    ]
    "roles/bigquery.dataEditor" = [
      "serviceAccount:${local.dataform_sa}",
    ]
  }
}
#resource "google_bigquery_dataset_iam_member" "dataform-ads-export-reader" {
#  depends_on = [
#    google_dataform_repository.marketing-analytics,
#    null_resource.check_dataform_api,
#    null_resource.wait_for_dataform_sa_creation,
#    time_sleep.wait_for_dataform-ga4-export-reader_role_propagation
#  ]
#  count      = length(var.source_ads_export_data)
#  role       = "roles/bigquery.dataViewer"
#  member     = "serviceAccount:${local.dataform_sa}"
#  project    = var.source_ads_export_data[count.index].project
#  dataset_id = var.source_ads_export_data[count.index].dataset
#}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_dataform-ads-export-reader_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.dataform-ads-export-reader
  ]
}
