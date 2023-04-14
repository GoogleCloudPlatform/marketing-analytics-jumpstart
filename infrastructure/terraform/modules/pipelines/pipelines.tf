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

resource "google_service_account" "service_account" {
  account_id   = local.pipeline_vars.service_account_id
  display_name = local.pipeline_vars.service_account_id
  description  = "sa to run pipelines"
}
# TODO - Add Principal to vertex-pipelines-sa resourse: new principals: 65903025497@cloudbuuild.gserviceaccount.com - role: service account user
# review this issue: https://github.com/hashicorp/terraform-provider-google/issues/10903
# TODO - SERVICE ACCOUNT NEEDS ACCESS TO DATASETS
#resource "google_project_iam_binding" "project" {
resource "google_project_iam_member" "pipelines_sa_roles" {
  project = local.pipeline_vars.project_id
  member  = "serviceAccount:${local.pipeline_vars.service_account}"

  for_each = toset([
    "roles/iap.tunnelResourceAccessor",
    "roles/compute.osLogin",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/storage.objectViewer",
    "roles/storage.objectCreator",
    "roles/aiplatform.user",
    "roles/artifactregistry.reader",
    "roles/pubsub.publisher"
  ])
  role = each.key
}


resource "google_service_account" "dataflow_worker_service_account" {
  account_id   = local.dataflow_vars.worker_service_account_id
  display_name = local.dataflow_vars.worker_service_account_id
  description  = "sa to run dataflow jobs"
}
resource "google_project_iam_member" "dataflow_worker_sa_roles" {
  project = local.pipeline_vars.project_id
  member  = "serviceAccount:${local.dataflow_vars.worker_service_account}"

  for_each = toset([
    "roles/dataflow.worker",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin",
  ])
  role = each.key
}

# Allow pipelines SA service account use dataflow worker SA
resource "google_service_account_iam_member" "dataflow_sa_iam" {
  service_account_id = "projects/${local.pipeline_vars.project_id}/serviceAccounts/${local.dataflow_vars.worker_service_account}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.pipeline_vars.service_account}"
}


resource "google_storage_bucket" "pipelines_bucket" {
  name          = local.pipeline_vars.bucket_name
  storage_class = "REGIONAL"
  location      = local.pipeline_vars.region
  force_destroy = true

}


resource "google_artifact_registry_repository" "pipelines-repo" {
  location      = local.artifact_registry_vars.pipelines_repo.region
  repository_id = local.artifact_registry_vars.pipelines_repo.name
  description   = "Pipelines Repository"
  format        = "KFP"
}


resource "google_artifact_registry_repository" "pipelines_docker_repo" {
  location      = local.artifact_registry_vars.pipelines_docker_repo.region
  repository_id = local.artifact_registry_vars.pipelines_docker_repo.name
  description   = "DOCKER images Repository"
  format        = "DOCKER"
}


resource "google_cloudbuild_trigger" "cloud-build-trigger" {
  //Source section
  location = local.cloud_build_vars.region
  github {
    owner = local.cloud_build_vars.github.owner
    name  = local.cloud_build_vars.github.repo_name
    //Events section  
    push {
      branch = local.cloud_build_vars.github.trigger_branch
    }
  }
  //Configuration section
  filename = local.cloud_build_vars.build_file

  substitutions = {
    _CONFIG_YAML = var.config_file_path
  }
}
