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

# This resource creates a service account to run the Vertex AI pipelines
resource "google_service_account" "service_account" {
  project      = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  account_id   = local.pipeline_vars.service_account_id
  display_name = local.pipeline_vars.service_account_id
  description  = "Service Account to run Vertex AI Pipelines"
}

# Wait for the pipelines service account to be created
resource "null_resource" "wait_for_vertex_pipelines_sa_creation" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud iam service-accounts list --project=${module.project_services.project_id} --filter="EMAIL:${local.pipeline_vars.service_account} AND DISABLED:False" --format="table(EMAIL, DISABLED)" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 3
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "pipelines service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services,
    null_resource.check_aiplatform_api
  ]
}


# This resource binds the service account to the required roles
resource "google_project_iam_member" "pipelines_sa_roles" {
  depends_on = [
    module.project_services,
    null_resource.check_aiplatform_api,
    null_resource.wait_for_vertex_pipelines_sa_creation
    ]
  
  project = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
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
    "roles/dataflow.developer",
    "roles/bigquery.connectionUser"
  ])
  role = each.key
}

# This resource binds the service account to the required roles in the mds project
resource "google_project_iam_member" "pipelines_sa_mds_project_roles" {
  depends_on = [
    module.project_services,
    null_resource.check_aiplatform_api,
    null_resource.wait_for_vertex_pipelines_sa_creation
    ]
  
  project = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  member  = "serviceAccount:${google_service_account.service_account.email}"

  for_each = toset([
    "roles/bigquery.dataViewer"
  ])
  role = each.key
}

# This resource creates a service account to run the dataflow jobs
resource "google_service_account" "dataflow_worker_service_account" {
  project      = null_resource.check_dataflow_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  account_id   = local.dataflow_vars.worker_service_account_id
  display_name = local.dataflow_vars.worker_service_account_id
  description  = "Service Account to run Dataflow jobs"
}

# Wait for the dataflow worker service account to be created
resource "null_resource" "wait_for_dataflow_worker_sa_creation" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud iam service-accounts list --project=${module.project_services.project_id} --filter="EMAIL:${local.dataflow_vars.worker_service_account} AND DISABLED:False" --format="table(EMAIL, DISABLED)" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 3
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "dataflow worker service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services,
    null_resource.check_dataflow_api
  ]
}

# This resource binds the service account to the required roles
resource "google_project_iam_member" "dataflow_worker_sa_roles" {
  depends_on = [
    module.project_services,
    null_resource.check_dataflow_api,
    null_resource.wait_for_dataflow_worker_sa_creation
    ]
  
  project = null_resource.check_dataflow_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  member  = "serviceAccount:${google_service_account.dataflow_worker_service_account.email}"

  for_each = toset([
    "roles/dataflow.worker",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin",
  ])
  role = each.key
}

# This resource binds the service account to the required roles
# Allow pipelines SA service account use dataflow worker SA
resource "google_service_account_iam_member" "dataflow_sa_iam" {
  depends_on = [
    module.project_services,
    null_resource.check_dataflow_api,
    null_resource.wait_for_dataflow_worker_sa_creation
    ]
  
  service_account_id = "projects/${module.project_services.project_id}/serviceAccounts/${google_service_account.dataflow_worker_service_account.email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.service_account.email}"
}

# This resource creates a Cloud Storage Bucket for the pipeline artifacts
resource "google_storage_bucket" "pipelines_bucket" {
  project                     = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  name                        = local.pipeline_vars.bucket_name
  storage_class               = "REGIONAL"
  location                    = local.pipeline_vars.region
  uniform_bucket_level_access = true
  # The force_destroy attribute specifies whether the bucket should be forcibly destroyed 
  # even if it contains objects. In this case, it's set to false, which means that the bucket will not be destroyed if it contains objects.
  force_destroy               = false

  # The lifecycle block allows you to configure the lifecycle of the bucket. 
  # In this case, the ignore_changes attribute is set to all, which means that Terraform 
  # will ignore any changes to the bucket's lifecycle configuration. The prevent_destroy attribute is set to false, which means that the bucket can be destroyed.
  lifecycle {
    ignore_changes  = all
    prevent_destroy = false ##true
  }
}

# This resource creates a Cloud Storage Bucket for the model assets
resource "google_storage_bucket" "custom_model_bucket" {
  project                     = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  name                        = local.pipeline_vars.model_bucket_name
  storage_class               = "REGIONAL"
  location                    = local.pipeline_vars.region
  uniform_bucket_level_access = true
  # The force_destroy attribute specifies whether the bucket should be forcibly destroyed 
  # even if it contains objects. In this case, it's set to false, which means that the bucket will not be destroyed if it contains objects.
  force_destroy               = false

  # The lifecycle block allows you to configure the lifecycle of the bucket. 
  # In this case, the ignore_changes attribute is set to all, which means that Terraform 
  # will ignore any changes to the bucket's lifecycle configuration. The prevent_destroy attribute is set to false, which means that the bucket can be destroyed.
  lifecycle {
    ignore_changes  = all
    prevent_destroy = false ##true
  }
}

# The locals block defines a local variable named vertex_pipelines_available_locations that contains a list of 
# all the available regions for Vertex AI Pipelines. 
# This variable is used to validate the value of the location attribute of the google_artifact_registry_repository resource.
locals {
  vertex_pipelines_available_locations = [
    "asia-east1",
    "asia-east2",
    "asia-northeast1",
    "asia-northeast2",
    "asia-northeast3",
    "asia-south1",
    "asia-southeast1",
    "asia-southeast2",
    "europe-central2",
    "europe-north1",
    "europe-west1",
    "europe-west2",
    "europe-west3",
    "europe-west4",
    "europe-west6",
    "europe-west8",
    "europe-west9",
    "europe-southwest1",
    "me-west1",
    "northamerica-northeast1",
    "northamerica-northeast2",
    "southamerica-east1",
    "southamerica-west1",
    "us-central1",
    "us-east1",
    "us-east4",
    "us-south1",
    "us-west1",
    "us-west2",
    "us-west3",
    "us-west4",
    "australia-southeast1",
    "australia-southeast2",
  ]
}

# This resource creates an Artifact Registry repository for the pipeline artifacts
resource "google_artifact_registry_repository" "pipelines-repo" {
  project       = null_resource.check_aiplatform_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  location      = local.artifact_registry_vars.pipelines_repo.region
  repository_id = local.artifact_registry_vars.pipelines_repo.name
  description   = "Pipelines Repository"
  # The format is kubeflow pipelines YAML files.
  format        = "KFP"

  # The lifecycle block of the google_artifact_registry_repository resource defines a precondition that 
  # checks if the specified region is included in the vertex_pipelines_available_locations list. 
  # If the condition is not met, an error message is displayed and the Terraform configuration will fail.
  lifecycle {
    precondition {
      condition     = contains(local.vertex_pipelines_available_locations, local.artifact_registry_vars.pipelines_repo.region)
      error_message = "Vertex AI Pipelines is not available in your default region: ${local.artifact_registry_vars.pipelines_repo.region}.\nSet 'google_default_region' variable to a valid Vertex AI Pipelines location, see https://cloud.google.com/vertex-ai/docs/general/locations."
    }
  }
}

# This resource creates an Artifact Registry repository for the pipeline docker images
resource "google_artifact_registry_repository" "pipelines_docker_repo" {
  project       = null_resource.check_artifactregistry_api.id != "" ? module.project_services.project_id : local.pipeline_vars.project_id
  location      = local.artifact_registry_vars.pipelines_docker_repo.region
  repository_id = local.artifact_registry_vars.pipelines_docker_repo.name
  description   = "Docker Images Repository"
  # The format is Docker images.
  format        = "DOCKER"
}

locals {
  base_component_image_dir = "${local.source_root_dir}/python/base_component_image"
  component_image_fileset = [
    "${local.base_component_image_dir}/build-push.py",
    "${local.base_component_image_dir}/Dockerfile",
    "${local.base_component_image_dir}/pyproject.toml",
    "${local.base_component_image_dir}/ma_components/vertex.py",
  ]
  # This is the content of the hash of all the files related to the base component image used to run each
  # Vertex AI Pipeline step.
  component_image_content_hash = sha512(join("", [for f in local.component_image_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))

  pipelines_dir = "${local.source_root_dir}/python/pipelines"
  pipelines_fileset = [
    "${local.pipelines_dir}/components/bigquery/component.py",
    "${local.pipelines_dir}/components/pubsub/component.py",
    "${local.pipelines_dir}/components/vertex/component.py",
    "${local.pipelines_dir}/components/python/component.py",
    "${local.pipelines_dir}/compiler.py",
    "${local.pipelines_dir}/feature_engineering_pipelines.py",
    "${local.pipelines_dir}/pipeline_ops.py",
    "${local.pipelines_dir}/scheduler.py",
    "${local.pipelines_dir}/segmentation_pipelines.py",
    "${local.pipelines_dir}/auto_segmentation_pipelines.py",
    "${local.pipelines_dir}/tabular_pipelines.py",
    "${local.pipelines_dir}/uploader.py",
  ]
  # This is the content of the hash of all the files related to the pipelines definitions used to run each
  # Vertex AI Pipeline.
  pipelines_content_hash = sha512(join("", [for f in local.pipelines_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))
}

# This resource is used to build and push the base component image that will be used to run each Vertex AI Pipeline step.
resource "null_resource" "build_push_pipelines_components_image" {
  triggers = {
    working_dir             = "${local.source_root_dir}/python"
    docker_repo_id          = google_artifact_registry_repository.pipelines_docker_repo.id
    docker_repo_create_time = google_artifact_registry_repository.pipelines_docker_repo.create_time
    source_content_hash     = local.component_image_content_hash
    poetry_installed        = var.poetry_installed
  }

  # The provisioner block specifies the command that will be executed to build and push the base component image.
  # This command will execute the build-push function in the base_component_image module, which will build and push the base component image to the specified Docker repository.
  provisioner "local-exec" {
    command     = "${var.poetry_run_alias} python -m base_component_image.build-push -c ${local.config_file_path_relative_python_run_dir}"
    working_dir = self.triggers.working_dir
  }
}


# Wait for the dataflow worker service account to be created
resource "null_resource" "check_pipeline_docker_image_pushed" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud artifacts docker images list --project=${module.project_services.project_id} ${local.artifact_registry_vars.pipelines_docker_repo.region}-docker.pkg.dev/${module.project_services.project_id}/${local.artifact_registry_vars.pipelines_docker_repo.name} --format="table(IMAGE, CREATE_TIME, UPDATE_TIME)" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 5
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "pipeline docker image was not created, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services,
    null_resource.build_push_pipelines_components_image
  ]
}

#######
## Feature Engineering Pipelines
#######

# This resource is used to compile and upload the Vertex AI pipeline for feature engineering - auto audience segmentation use case
resource "null_resource" "compile_feature_engineering_auto_audience_segmentation_pipeline" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.build_push_pipelines_components_image.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-auto-audience-segmentation.execution -o fe_auto_audience_segmentation.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f fe_auto_audience_segmentation.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-auto-audience-segmentation.execution -i fe_auto_audience_segmentation.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for feature engineering - aggregated value based bidding use case
resource "null_resource" "compile_feature_engineering_aggregated_value_based_bidding_pipeline" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.compile_feature_engineering_auto_audience_segmentation_pipeline.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-aggregated-value-based-bidding.execution -o fe_agg_vbb.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f fe_agg_vbb.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-aggregated-value-based-bidding.execution -i fe_agg_vbb.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for feature engineering - audience segmentation use case
resource "null_resource" "compile_feature_engineering_audience_segmentation_pipeline" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.compile_feature_engineering_aggregated_value_based_bidding_pipeline.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-audience-segmentation.execution -o fe_audience_segmentation.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f fe_audience_segmentation.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-audience-segmentation.execution -i fe_audience_segmentation.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for feature engineering - purchase propensity use case
resource "null_resource" "compile_feature_engineering_purchase_propensity_pipeline" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.compile_feature_engineering_audience_segmentation_pipeline.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-purchase-propensity.execution -o fe_purchase_propensity.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f fe_purchase_propensity.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-purchase-propensity.execution -i fe_purchase_propensity.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for feature engineering - churn propensity use case
resource "null_resource" "compile_feature_engineering_churn_propensity_pipeline" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.compile_feature_engineering_purchase_propensity_pipeline.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-churn-propensity.execution -o fe_churn_propensity.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f fe_churn_propensity.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-churn-propensity.execution -i fe_churn_propensity.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for feature engineering - customer lifetime value use case
resource "null_resource" "compile_feature_engineering_customer_lifetime_value_pipeline" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    pipelines_repo_id            = google_artifact_registry_repository.pipelines-repo.id
    pipelines_repo_create_time   = google_artifact_registry_repository.pipelines-repo.create_time
    source_content_hash          = local.pipelines_content_hash
    upstream_resource_dependency = null_resource.compile_feature_engineering_churn_propensity_pipeline.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-customer-ltv.execution -o fe_customer_ltv.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f fe_customer_ltv.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.feature-creation-customer-ltv.execution -i fe_customer_ltv.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

###
## Training and Inference Pipelines
###

# This resource is used to compile and upload the Vertex AI pipeline for training the propensity model - purchase propensity use case
resource "null_resource" "compile_purchase_propensity_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_feature_engineering_customer_lifetime_value_pipeline.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.purchase_propensity.training -o purchase_propensity_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f purchase_propensity_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.purchase_propensity.training -i purchase_propensity_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for prediction using the propensity model - purchase propensity use case
resource "null_resource" "compile_purchase_propensity_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_purchase_propensity_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.purchase_propensity.prediction -o purchase_propensity_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f purchase_propensity_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.purchase_propensity.prediction -i purchase_propensity_prediction.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for training the Propensity model - Customer lifetime value use case
resource "null_resource" "compile_propensity_clv_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_purchase_propensity_prediction_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.propensity_clv.training -o propensity_clv_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f propensity_clv_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.propensity_clv.training -i propensity_clv_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for training the CLTV model - Customer lifetime value use case
resource "null_resource" "compile_clv_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_propensity_clv_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.training -o clv_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f clv_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.training -i clv_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for prediction using the CLTV model - Customer lifetime value use case
resource "null_resource" "compile_clv_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_clv_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.prediction -o clv_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f clv_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.clv.prediction -i clv_prediction.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for training the segmentation model - Audience segmentation use case
resource "null_resource" "compile_segmentation_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_clv_prediction_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.training -o segmentation_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f segmentation_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.training -i segmentation_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for prediction using the Audience Segmentation model - Audience segmentation use case
resource "null_resource" "compile_segmentation_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_segmentation_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.prediction -o segmentation_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f segmentation_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.segmentation.prediction -i segmentation_prediction.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for training the Auto Audience Segmentation model - Auto audience segmentation use case
resource "null_resource" "compile_auto_segmentation_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_segmentation_prediction_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.auto_segmentation.training -o auto_segmentation_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f auto_segmentation_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.auto_segmentation.training -i auto_segmentation_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for prediction using the CLTV model - Customer lifetime value use case
resource "null_resource" "compile_auto_segmentation_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_auto_segmentation_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.auto_segmentation.prediction -o auto_segmentation_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f auto_segmentation_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.auto_segmentation.prediction -i auto_segmentation_prediction.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for training the Aggregated Values Based Bidding model - Aggregated Value Based Bidding use case
resource "null_resource" "compile_value_based_bidding_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_auto_segmentation_prediction_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.value_based_bidding.training -o vbb_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f vbb_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.value_based_bidding.training -i vbb_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for explaining features using the Aggregated Value Based Bidding model - Aggregated Value Based Bidding use case
resource "null_resource" "compile_value_based_bidding_explanation_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_value_based_bidding_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.value_based_bidding.explanation -o vbb_explanation.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f vbb_explanation.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.value_based_bidding.explanation -i vbb_explanation.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for training the churn propensity model - churn propensity use case
resource "null_resource" "compile_churn_propensity_training_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_reporting_preparation_aggregate_predictions_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.churn_propensity.training -o churn_propensity_training.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f churn_propensity_training.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.churn_propensity.training -i churn_propensity_training.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for prediction using the churn propensity model - churn propensity use case
resource "null_resource" "compile_churn_propensity_prediction_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_churn_propensity_training_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.churn_propensity.prediction -o churn_propensity_prediction.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f churn_propensity_prediction.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.churn_propensity.prediction -i churn_propensity_prediction.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for preparing data for the reports
resource "null_resource" "compile_reporting_preparation_aggregate_predictions_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_value_based_bidding_explanation_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.reporting_preparation.execution -o reporting_preparation.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f reporting_preparation.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.reporting_preparation.execution -i reporting_preparation.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}

# This resource is used to compile and upload the Vertex AI pipeline for generating gemini insights
resource "null_resource" "compile_gemini_insights_pipelines" {
  triggers = {
    working_dir                  = "${local.source_root_dir}/python"
    tag                          = local.compile_pipelines_tag
    upstream_resource_dependency = null_resource.compile_churn_propensity_prediction_pipelines.id
  }

  # The provisioner block specifies the command that will be executed to compile and upload the pipeline.
  # This command will execute the compiler function in the pipelines module, which will compile the pipeline YAML file, and the uploader function, 
  # which will upload the pipeline YAML file to the specified Artifact Registry repository. The scheduler function will then schedule the pipeline to run on a regular basis.
  provisioner "local-exec" {
    command     = <<-EOT
    ${var.poetry_run_alias} python -m pipelines.compiler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.gemini_insights.execution -o gemini_insights.yaml
    ${var.poetry_run_alias} python -m pipelines.uploader -c ${local.config_file_path_relative_python_run_dir} -f gemini_insights.yaml -t ${self.triggers.tag} -t latest
    ${var.poetry_run_alias} python -m pipelines.scheduler -c ${local.config_file_path_relative_python_run_dir} -p vertex_ai.pipelines.gemini_insights.execution -i gemini_insights.yaml
    EOT
    working_dir = self.triggers.working_dir
  }
}