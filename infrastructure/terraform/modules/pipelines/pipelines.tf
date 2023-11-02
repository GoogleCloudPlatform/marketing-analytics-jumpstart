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
  project      = local.pipeline_vars.project_id
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
  member  = "serviceAccount:${google_service_account.service_account.email}"

  for_each = toset([
    "roles/iap.tunnelResourceAccessor",
    "roles/compute.osLogin",
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/storage.admin",
    "roles/aiplatform.user",
    "roles/artifactregistry.reader",
    "roles/pubsub.publisher",
    "roles/dataflow.developer"
  ])
  role = each.key
}

resource "google_project_iam_member" "pipelines_sa_mds_project_roles" {
  project = var.mds_project_id
  member  = "serviceAccount:${google_service_account.service_account.email}"

  for_each = toset([
    "roles/bigquery.dataViewer"
  ])
  role = each.key
}


resource "google_service_account" "dataflow_worker_service_account" {
  project      = local.pipeline_vars.project_id
  account_id   = local.dataflow_vars.worker_service_account_id
  display_name = local.dataflow_vars.worker_service_account_id
  description  = "sa to run dataflow jobs"
}
resource "google_project_iam_member" "dataflow_worker_sa_roles" {
  project = local.pipeline_vars.project_id
  member  = "serviceAccount:${google_service_account.dataflow_worker_service_account.email}"

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
  service_account_id = "projects/${local.pipeline_vars.project_id}/serviceAccounts/${google_service_account.dataflow_worker_service_account.email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_storage_bucket" "pipelines_bucket" {
  project                     = local.pipeline_vars.project_id
  name                        = local.pipeline_vars.bucket_name
  storage_class               = "REGIONAL"
  location                    = local.pipeline_vars.region
  uniform_bucket_level_access = true
  force_destroy               = false
  lifecycle {
    ignore_changes  = all
    prevent_destroy = false ##true
  }
}

locals {
  vertex_pipelines_available_locations = [
    "asia-east1",
    "asia-east2",
    "asia-northeast1",
    "asia-northeast3",
    "asia-south1",
    "asia-southeast1",
    "asia-southeast2",
    "europe-central2",
    "europe-west1",
    "europe-west2",
    "europe-west3",
    "europe-west4",
    "europe-west6",
    "europe-west9",
    "me-west1",
    "northamerica-northeast1",
    "northamerica-northeast2",
    "southamerica-east1",
    "us-central1",
    "us-east1",
    "us-east4",
    "us-south1",
    "us-west1",
    "us-west2",
    "us-west3",
    "us-west4",
  ]
}

resource "google_artifact_registry_repository" "pipelines-repo" {
  project       = module.project_services.project_id
  location      = local.artifact_registry_vars.pipelines_repo.region
  repository_id = local.artifact_registry_vars.pipelines_repo.name
  description   = "Pipelines Repository"
  format        = "KFP"
  lifecycle {
    precondition {
      condition     = contains(local.vertex_pipelines_available_locations, local.artifact_registry_vars.pipelines_repo.region)
      error_message = "Vertex AI Pipelines is not available in your default region: ${local.artifact_registry_vars.pipelines_repo.region}.\nSet 'google_default_region' variable to a valid Vertex AI Pipelines location, see https://cloud.google.com/vertex-ai/docs/general/locations."
    }
  }
}


resource "google_artifact_registry_repository" "pipelines_docker_repo" {
  project       = module.project_services.project_id
  location      = local.artifact_registry_vars.pipelines_docker_repo.region
  repository_id = local.artifact_registry_vars.pipelines_docker_repo.name
  description   = "DOCKER images Repository"
  format        = "DOCKER"
}


#resource "google_cloudbuild_trigger" "cloud-build-trigger" {
#  //Source section
#  location = local.cloud_build_vars.region
#  github {
#    owner = local.cloud_build_vars.github.owner
#    name  = local.cloud_build_vars.github.repo_name
#    //Events section  
#    push {
#      branch = local.cloud_build_vars.github.trigger_branch
#    }
#  }
#  //Configuration section
#  filename = local.cloud_build_vars.build_file
#
#  substitutions = {
#    _CONFIG_YAML = var.config_file_path
#  }
#}

locals {
  base_component_image_dir = "${local.source_root_dir}/python/base_component_image"
  component_image_fileset = [
    "${local.base_component_image_dir}/build-push.py",
    "${local.base_component_image_dir}/Dockerfile",
    "${local.base_component_image_dir}/pyproject.toml",
    "${local.base_component_image_dir}/ma_components/vertex.py",
  ]
  component_image_content_hash = sha512(join("", [for f in local.component_image_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))

  pipelines_dir = "${local.source_root_dir}/python/pipelines"
  pipelines_fileset = [
    "${local.pipelines_dir}/components/bigquery/component.py",
    "${local.pipelines_dir}/components/pubsub/component.py",
    "${local.pipelines_dir}/components/vertex/component.py",
    "${local.pipelines_dir}/compiler.py",
    "${local.pipelines_dir}/feature_engineering_pipelines.py",
    "${local.pipelines_dir}/pipeline_ops.py",
    "${local.pipelines_dir}/scheduler.py",
    "${local.pipelines_dir}/segmentation_pipelines.py",
    "${local.pipelines_dir}/tabular_pipelines.py",
    "${local.pipelines_dir}/uploader.py",
  ]
  pipelines_content_hash = sha512(join("", [for f in local.pipelines_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))
}

resource "null_resource" "build_push_pipelines_components_image" {
  triggers = {
    working_dir             = "${local.source_root_dir}/python"
    docker_repo_id          = google_artifact_registry_repository.pipelines_docker_repo.id
    docker_repo_create_time = google_artifact_registry_repository.pipelines_docker_repo.create_time
    source_content_hash     = local.component_image_content_hash
  }

  provisioner "local-exec" {
    command     = "${var.poetry_run_alias} python -m base_component_image.build-push -c ${local.config_file_path_relative_python_run_dir}"
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_feature_engineering_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.build_push_pipelines_components_image.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation.execution -o feature_engineering.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f feature_engineering.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation.execution
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_propensity_trainings_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_feature_engineering_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.propensity.training -o propensity_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f propensity_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.propensity.training
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_propensity_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_propensity_trainings_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.propensity.prediction -o propensity_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f propensity_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.propensity.prediction
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_clv_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_propensity_prediction_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.training -o clv_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f clv_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.training
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_clv_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_clv_training_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.prediction -o clv_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f clv_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.prediction
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_segmentation_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_clv_prediction_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.training -o segmentation_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f segmentation_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.training
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_segmentation_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_segmentation_training_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.prediction -o segmentation_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f segmentation_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.prediction
    EOT
    working_dir = self.triggers.working_dir
  }
}

resource "null_resource" "compile_auto_segmentation_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_feature_engineering_pipelines.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.auto_segmentation.prediction -o auto_segmentation_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f auto_segmentation_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.auto_segmentation.prediction
    EOT
    working_dir = self.triggers.working_dir
  }
}