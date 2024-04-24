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

# https://registry.terraform.io/modules/terraform-google-modules/project-factory/google/latest/submodules/project_services
module "data-processing-project-services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.5.0"

  disable_dependent_services  = false
  disable_services_on_destroy = false

  project_id = var.project_id

  activate_apis = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "workflows.googleapis.com",
    "cloudscheduler.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "storage.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "secretmanager.googleapis.com",
    "sourcerepo.googleapis.com",
    "dataform.googleapis.com",
  ]
}
