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
  config_vars                              = yamldecode(data.local_file.config_vars.content)
  cloud_build_vars                         = local.config_vars.cloud_build
  artifact_registry_vars                   = local.config_vars.artifact_registry
  pipeline_vars                            = local.config_vars.vertex_ai.pipelines
  dataflow_vars                            = local.config_vars.dataflow
  source_root_dir                          = "../.."
  config_file_path_relative_python_run_dir = substr(var.config_file_path, 3, length(var.config_file_path))
  compile_pipelines_tag                    = "v1"
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.1.0"

  disable_dependent_services  = true
  disable_services_on_destroy = false

  project_id = local.pipeline_vars.project_id

  activate_apis = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "storage.googleapis.com",
    "sourcerepo.googleapis.com",
    "storage-api.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "dataflow.googleapis.com",
  ]
}
