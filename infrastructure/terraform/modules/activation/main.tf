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

locals {
  app_prefix                                 = "activation"
  source_root_dir                            = "../.."
  sql_dir                                    = "${local.source_root_dir}/sql/query"
  template_dir                               = "${local.source_root_dir}/templates"
  pipeline_source_dir                        = "${local.source_root_dir}/python/activation"
  trigger_function_dir                       = "${local.source_root_dir}/python/function"
  configuration_folder                       = "configuration"
  audience_segmentation_query_template_file  = "audience_segmentation_query_template.sqlx"
  cltv_query_template_file                   = "cltv_query_template.sqlx"
  purchase_propensity_query_template_file    = "purchase_propensity_query_template.sqlx"
  measurement_protocol_payload_template_file = "app_payload_template.jinja2"
  activation_container_image_id              = "activation-pipeline"
  docker_repo_prefix                         = "${var.location}-docker.pkg.dev/${var.project_id}"
  activation_container_name                  = "dataflow/${local.activation_container_image_id}"
  source_archive_file                        = "activation_trigger_source.zip"

  pipeline_service_account_name  = "dataflow-worker"
  pipeline_service_account_email = "${local.app_prefix}-${local.pipeline_service_account_name}@${var.project_id}.iam.gserviceaccount.com"

  trigger_function_account_name  = "trigger-function"
  trigger_function_account_email = "${local.app_prefix}-${local.trigger_function_account_name}@${var.project_id}.iam.gserviceaccount.com"

}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.1.0"

  disable_dependent_services  = false
  disable_services_on_destroy = false

  project_id = var.project_id

  activate_apis = [
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "logging.googleapis.com",
    "aiplatform.googleapis.com",
    "bigquerystorage.googleapis.com",
    "storage.googleapis.com",
    "datapipelines.googleapis.com",
  ]
}

module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 5.4"

  dataset_id                  = local.app_prefix
  dataset_name                = local.app_prefix
  description                 = "activation appliction logs"
  project_id                  = var.project_id
  location                    = "US"
  default_table_expiration_ms = 360000000
}

resource "null_resource" "check_artifactregistry_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list | grep -i "artifactregistry.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 3
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "artifict registry is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

resource "google_artifact_registry_repository" "activation_repository" {
  project       = var.project_id
  location      = var.location
  repository_id = var.artifact_repository_id
  description   = "Pipeline container repository"
  format        = "DOCKER"
  depends_on = [
    null_resource.check_artifactregistry_api
  ]
}


module "pipeline_service_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = var.project_id
  prefix     = local.app_prefix
  names      = [local.pipeline_service_account_name]
  project_roles = ["${var.project_id}=>roles/dataflow.admin",
    "${var.project_id}=>roles/dataflow.worker",
    "${var.project_id}=>roles/bigquery.dataEditor",
    "${var.project_id}=>roles/bigquery.jobUser",
  "${var.project_id}=>roles/artifactregistry.writer", ]
  display_name = "Dataflow worker"
  description  = "Activation Pipeline Account"
}

module "trigger_function_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 3.0"
  project_id = var.project_id
  prefix     = local.app_prefix
  names      = [local.trigger_function_account_name]
  project_roles = [
    "${var.project_id}=>roles/secretmanager.secretAccessor",
    "${var.project_id}=>roles/dataflow.admin",
    "${var.project_id}=>roles/dataflow.worker",
    "${var.project_id}=>roles/bigquery.dataEditor",
    "${var.project_id}=>roles/pubsub.editor",
    "${var.project_id}=>roles/storage.admin",
    "${var.project_id}=>roles/artifactregistry.reader",
    "${var.project_id}=>roles/iam.serviceAccountUser",
  ]
  display_name = "Activation Trigger Account"
  description  = "Account used to run the activation trigger function"
}

data "external" "ga4_measurement_properties" {
  program = ["bash", "-c", "python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt >&2 && python setup.py --ga4_resource=measurement_properties && deactivate"]
  working_dir = "../../python/ga4_setup"
}

module "secret_manager" {
  source     = "GoogleCloudPlatform/secret-manager/google"
  version    = "~> 0.1"
  project_id = var.project_id
  secrets = [
    {
      name                  = "ga4-measurement-id"
      secret_data           = data.external.ga4_measurement_properties.result["measurement_id"]
      automatic_replication = true
    },
    {
      name                  = "ga4-measurement-secret"
      secret_data           = data.external.ga4_measurement_properties.result["measurement_secret"]
      automatic_replication = true
    },
  ]

  depends_on = [
    module.project_services
  ]
}

module "pipeline_bucket" {
  source        = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version       = "~> 3.4.1"
  project_id    = var.project_id
  name          = "${local.app_prefix}-app-${var.project_id}"
  location      = var.location
  force_destroy = true

  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age            = 365
      with_state     = "ANY"
      matches_prefix = var.project_id
    }
  }]

  iam_members = [{
    role   = "roles/storage.admin"
    member = "serviceAccount:${local.pipeline_service_account_email}"
  }]

  depends_on = [
    module.pipeline_service_account.email
  ]
}

resource "google_storage_bucket_object" "measurement_protocol_payload_template_file" {
  name   = "${local.configuration_folder}/${local.measurement_protocol_payload_template_file}"
  source = "${local.template_dir}/${local.measurement_protocol_payload_template_file}"
  bucket = module.pipeline_bucket.name
}

resource "google_storage_bucket_object" "audience_segmentation_query_template_file" {
  name   = "${local.configuration_folder}/${local.audience_segmentation_query_template_file}"
  source = "${local.sql_dir}/${local.audience_segmentation_query_template_file}"
  bucket = module.pipeline_bucket.name
}

resource "google_storage_bucket_object" "cltv_query_template_file" {
  name   = "${local.configuration_folder}/${local.cltv_query_template_file}"
  source = "${local.sql_dir}/${local.cltv_query_template_file}"
  bucket = module.pipeline_bucket.name
}

resource "google_storage_bucket_object" "purchase_propensity_query_template_file" {
  name   = "${local.configuration_folder}/${local.purchase_propensity_query_template_file}"
  source = "${local.sql_dir}/${local.purchase_propensity_query_template_file}"
  bucket = module.pipeline_bucket.name
}

data "template_file" "activation_type_configuration" {
  template = file("${local.template_dir}/activation_type_configuration_template.tpl")
  vars = {
    audience_segmentation_query_template_gcs_path  = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.audience_segmentation_query_template_file.output_name}"
    cltv_query_template_gcs_path                   = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.cltv_query_template_file.output_name}"
    purchase_propensity_query_template_gcs_path    = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.purchase_propensity_query_template_file.output_name}"
    measurement_protocol_payload_template_gcs_path = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.measurement_protocol_payload_template_file.output_name}"
  }
}

resource "google_storage_bucket_object" "activation_type_configuration_file" {
  name    = "${local.configuration_folder}/activation_type_configuration.json"
  content = data.template_file.activation_type_configuration.rendered
  bucket  = module.pipeline_bucket.name
}

module "activation_pipeline_container" {
  source  = "terraform-google-modules/gcloud/google"
  version = "3.1.2"

  platform = "linux"

  create_cmd_body  = "builds submit --tag ${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name}:latest ${local.pipeline_source_dir}"
  destroy_cmd_body = "artifacts docker images delete ${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name} --delete-tags"
}

module "activation_pipeline_template" {
  source                = "terraform-google-modules/gcloud/google"
  version               = "3.1.2"
  additional_components = ["gsutil"]

  platform               = "linux"
  create_cmd_body        = "dataflow flex-template build \"gs://${module.pipeline_bucket.name}/dataflow/templates/${local.activation_container_image_id}.json\" --image \"${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name}:latest\" --sdk-language \"PYTHON\" --metadata-file \"${local.pipeline_source_dir}/metadata.json\""
  destroy_cmd_entrypoint = "gsutil"
  destroy_cmd_body       = "rm \"gs://${module.pipeline_bucket.name}/dataflow/templates/${local.activation_container_image_id}.json\""

  module_depends_on = [
    module.activation_pipeline_container.wait
  ]
}

resource "google_pubsub_topic" "activation_trigger" {
  name    = "activation-trigger"
  project = var.project_id
}

data "archive_file" "activation_trigger_source" {
  type        = "zip"
  output_path = "${local.trigger_function_dir}/${local.source_archive_file}"
  source_dir  = "${local.trigger_function_dir}/trigger_activation"
}

module "function_bucket" {
  source        = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version       = "~> 3.4.1"
  project_id    = var.project_id
  name          = "activation-trigger-${var.project_id}"
  location      = var.location
  force_destroy = true

  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age            = 365
      with_state     = "ANY"
      matches_prefix = var.project_id
    }
  }]

  iam_members = [{
    role   = "roles/storage.admin"
    member = "serviceAccount:${local.trigger_function_account_email}"
  }]

  depends_on = [
    module.trigger_function_account.email
  ]
}

resource "google_storage_bucket_object" "activation_trigger_archive" {
  name   = local.source_archive_file
  source = data.archive_file.activation_trigger_source.output_path
  bucket = module.function_bucket.name
}

resource "google_cloudfunctions_function" "activation_trigger_cf" {
  name    = "activation-trigger"
  project = var.project_id
  region  = var.trigger_function_location
  runtime = "python311"

  available_memory_mb   = 256
  max_instances         = 3
  source_archive_bucket = module.function_bucket.name
  source_archive_object = google_storage_bucket_object.activation_trigger_archive.name
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.activation_trigger.name
  }
  timeout               = 60
  entry_point           = "subscribe"
  service_account_email = module.trigger_function_account.email

  environment_variables = {
    ACTIVATION_PROJECT            = var.project_id
    ACTIVATION_REGION             = var.location
    ACTIVATION_TYPE_CONFIGURATION = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.activation_type_configuration_file.output_name}"
    TEMPLATE_FILE_GCS_LOCATION    = "gs://${module.pipeline_bucket.name}/dataflow/templates/${local.activation_container_image_id}.json"
    PIPELINE_TEMP_LOCATION        = "gs://${module.pipeline_bucket.name}/tmp/"
    LOG_DATA_SET                  = module.bigquery.bigquery_dataset.dataset_id
    PIPELINE_WORKER_EMAIL         = module.pipeline_service_account.email
  }
  secret_environment_variables {
    key     = "GA4_MEASUREMENT_ID"
    secret  = split("/", module.secret_manager.secret_names[0])[3]
    version = split("/", module.secret_manager.secret_versions[0])[5]
  }

  secret_environment_variables {
    key     = "GA4_MEASUREMENT_SECRET"
    secret  = split("/", module.secret_manager.secret_names[1])[3]
    version = split("/", module.secret_manager.secret_versions[1])[5]
  }

  depends_on = [
    module.project_services
  ]
}
