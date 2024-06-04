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

resource "google_secret_manager_secret" "github-secret" {
  secret_id = "Github_token"
  project   = null_resource.check_secretmanager_api.id != "" ?  module.data_processing_project_services.project_id : data.google_project.data_processing.project_id

  replication {
    #automatic = true
    auto {}
  }

  depends_on = [
    null_resource.check_dataform_api,
    null_resource.check_secretmanager_api
  ]
}

resource "google_secret_manager_secret_version" "secret-version-github" {
  secret = google_secret_manager_secret.github-secret.id
  secret_data = var.dataform_github_token

  #deletion_policy = "DISABLE"
  deletion_policy = "DELETE"

  depends_on = [
    null_resource.check_dataform_api,
    null_resource.check_secretmanager_api
  ]
}