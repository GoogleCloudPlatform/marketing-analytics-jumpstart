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

resource "google_dataform_repository" "marketing-analytics" {
  provider = google-beta
  name     = "marketing-analytics"
  project  = data.google_project.data_processing.project_id
  region   = var.google_default_region

  git_remote_settings {
    url                                 = var.dataform_github_repo
    default_branch                      = "main"
    authentication_token_secret_version = google_secret_manager_secret_version.secret-version-github.id
  }

  depends_on = [
    module.data-processing-project-services
  ]
}