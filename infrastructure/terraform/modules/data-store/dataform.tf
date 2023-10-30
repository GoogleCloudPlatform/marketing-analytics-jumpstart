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

locals {
  dataform_available_locations = [
    "asia-east1",
    "asia-northeast1",
    "asia-south1",
    "asia-southeast1",
    "australia-southeast1",
    "europe-west1",
    "europe-west2",
    "europe-west3",
    "europe-west4",
    "europe-west6",
    "southamerica-east1",
    "us-east1",
    "us-central1",
    "us-west1",
  ]
  dataform_derived_region = var.dataform_region != "" ? var.dataform_region : var.google_default_region
}
resource "google_dataform_repository" "marketing-analytics" {
  provider = google-beta
  name     = "marketing-analytics"
  project  = data.google_project.data_processing.project_id
  region   = local.dataform_derived_region

  lifecycle {
    precondition {
      condition     = contains(local.dataform_available_locations, local.dataform_derived_region)
      error_message = "Dataform is not available in your default region: ${var.google_default_region}.\nSet 'dataform_region' variable to a valid Dataform location, see https://cloud.google.com/dataform/docs/locations."
    }
  }

  git_remote_settings {
    url                                 = var.dataform_github_repo
    default_branch                      = "main"
    authentication_token_secret_version = google_secret_manager_secret_version.secret-version-github.id
  }

  depends_on = [
    module.data-processing-project-services
  ]
}