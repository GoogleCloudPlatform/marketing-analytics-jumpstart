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

# This local block is used to declare two local variables: `dataform_available_locations` and `dataform_derived_region`.
# dataform_available_locations: This variable is a list of all the available regions for Google Dataform. It is used to validate the value of the dataform_region variable.
# dataform_derived_region: This variable derives the region to be used for the Dataform repository. It uses the value of the dataform_region variable if it is not empty, 
# otherwise it uses the value of the google_default_region variable.
locals {
  dataform_available_locations = [
    "africa-south1",
    "asia-east1",
    "asia-east2",
    "asia-northeast1",
    "asia-northeast3",
    "asia-south1",
    "asia-southeast1",
    "asia-southeast2",
    "australia-southeast1",
    "europe-west1",
    "europe-west2",
    "europe-west3",
    "europe-west4",
    "europe-west6",
    "europe-west12",
    "europe-southwest1",
    "southamerica-east1",
    "northamerica-northeast1",
    "us-east1",
    "us-east4",
    "us-east5",
    "us-central1",
    "us-south1",
    "us-west1",
    "us-west4",
    "us-west2",
    "me-central2",
    "me-central1"
  ]
  dataform_derived_region = var.dataform_region != "" ? var.dataform_region : var.google_default_region
}

# This resource creates a Dataform repository.
resource "google_dataform_repository" "marketing-analytics" {
  provider = google-beta
  # This is the name of the Dataform Repository created in your project
  name     = "marketing-analytics"
  project  = null_resource.check_dataform_api.id != "" ?  module.data_processing_project_services.project_id : data.google_project.data_processing.project_id
  region   = local.dataform_derived_region

  lifecycle {
    precondition {
      condition     = contains(local.dataform_available_locations, local.dataform_derived_region)
      error_message = "Dataform is not available in your default region: ${var.google_default_region}.\nSet 'dataform_region' variable to a valid Dataform location, see https://cloud.google.com/dataform/docs/locations"
    }
  }

  git_remote_settings {
    url                                 = var.dataform_github_repo
    default_branch                      = "main"
    authentication_token_secret_version = google_secret_manager_secret_version.secret-version-github.id
  }

  depends_on = [
    module.data_processing_project_services
  ]
}