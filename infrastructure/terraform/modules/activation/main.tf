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
  app_prefix                                     = "activation"
  source_root_dir                                = "../.."
  poetry_run_alias                               = "${var.poetry_cmd} run"
  template_dir                                   = "${local.source_root_dir}/templates"
  pipeline_source_dir                            = "${local.source_root_dir}/python/activation"
  trigger_function_dir                           = "${local.source_root_dir}/python/function"
  configuration_folder                           = "configuration"
  audience_segmentation_query_template_file      = "audience_segmentation_query_template.sqlx"
  auto_audience_segmentation_query_template_file = "auto_audience_segmentation_query_template.sqlx"
  cltv_query_template_file                       = "cltv_query_template.sqlx"
  purchase_propensity_query_template_file        = "purchase_propensity_query_template.sqlx"
  purchase_propensity_vbb_query_template_file    = "purchase_propensity_vbb_query_template.sqlx"
  churn_propensity_query_template_file           = "churn_propensity_query_template.sqlx"
  activation_container_image_id                  = "activation-pipeline"
  docker_repo_prefix                             = "${var.location}-docker.pkg.dev/${var.project_id}"
  activation_container_name                      = "dataflow/${local.activation_container_image_id}"
  source_archive_file                            = "activation_trigger_source.zip"

  pipeline_service_account_name  = "dataflow-worker"
  pipeline_service_account_email = "${local.app_prefix}-${local.pipeline_service_account_name}@${var.project_id}.iam.gserviceaccount.com"

  trigger_function_account_name  = "trigger-function"
  trigger_function_account_email = "${local.app_prefix}-${local.trigger_function_account_name}@${var.project_id}.iam.gserviceaccount.com"

  builder_service_account_name  = "build-job"
  builder_service_account_email = "${local.app_prefix}-${local.builder_service_account_name}@${var.project_id}.iam.gserviceaccount.com"

  activation_type_configuration_file = "${local.source_root_dir}/templates/activation_type_configuration_template.tpl"
  # This is calculating a hash number on the file content to keep track of changes and trigger redeployment of resources 
  # in case the file content changes.
  activation_type_configuration_file_content_hash = filesha512(local.activation_type_configuration_file)

  activation_application_dir = "${local.source_root_dir}/python/activation"
  activation_application_fileset = [
    "${local.activation_application_dir}/main.py",
    "${local.activation_application_dir}/Dockerfile",
    "${local.activation_application_dir}/metadata.json",
    "${local.activation_application_dir}/requirements.txt",
    "${local.activation_application_dir}/pipeline_test.py",
  ]
  # This is calculating a hash number on the files contents to keep track of changes and trigger redeployment of resources 
  # in case any of these files contents changes.
  activation_application_content_hash = sha512(join("", [for f in local.activation_application_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))

  ga4_setup_source_file              = "${local.source_root_dir}/python/ga4_setup/setup.py"
  ga4_setup_source_file_content_hash = filesha512(local.ga4_setup_source_file)
  ga4_stream_id_set = toset(var.ga4_stream_id)
}

data "google_project" "activation_project" {
  project_id = var.project_id
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "17.0.0"

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
    "analyticsadmin.googleapis.com",
    "eventarc.googleapis.com",
    "run.googleapis.com",
    "cloudkms.googleapis.com"
  ]
}

# This resource executes gcloud commands to check whether the BigQuery API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_bigquery_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "bigquery.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "bigquery api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the artifact registry API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_artifactregistry_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "artifactregistry.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "pubsub api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the PubSub API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_pubsub_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "pubsub.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "artifact registry api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the analyticsadmin API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_analyticsadmin_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "analyticsadmin.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "analyticsadmin api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the dataflow API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_dataflow_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "dataflow.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "dataflow api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the secretmanager API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_secretmanager_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "secretmanager.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "secretmanager api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the cloudfunctions API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_cloudfunctions_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "cloudfunctions.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "cloudfunctions api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the cloudbuild API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_cloudbuild_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "cloudbuild.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "cloudbuild api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

# This resource executes gcloud commands to check whether the IAM API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_cloudkms_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "cloudkms.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "cloud kms api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.project_services
  ]
}

module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "8.1.0"

  dataset_id                 = local.app_prefix
  dataset_name               = local.app_prefix
  description                = "activation application logs"
  project_id                 = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : var.project_id
  location                   = var.data_location
  delete_contents_on_destroy = false
}

# This resouce calls a python command defined inside the module ga4_setup that is responsible for creating
# all required custom events in the Google Analytics 4 property.
# Check the python file ga4-setup/setup.py for more information.
resource "null_resource" "create_custom_events" {
  for_each = local.ga4_stream_id_set
  triggers = {
    services_enabled_project = null_resource.check_analyticsadmin_api.id != "" ? module.project_services.project_id : var.project_id
    source_contents_hash     = local.activation_type_configuration_file_content_hash
    source_file_content_hash = local.ga4_setup_source_file_content_hash
  }
  provisioner "local-exec" {
    command     = <<-EOT
    ${local.poetry_run_alias} ga4-setup --ga4_resource=custom_events --ga4_property_id=${var.ga4_property_id} --ga4_stream_id=${each.value}
    EOT
    working_dir = local.source_root_dir
  }
}

# This resource calls a python command defines inside the module ga4_setup that is responsible for creating
# all required custom events in the Google Analytics 4 property.
# Check the python file ga4_setup/setup.py for more information.
resource "null_resource" "create_custom_dimensions" {
  for_each = local.ga4_stream_id_set
  triggers = {
    services_enabled_project = null_resource.check_analyticsadmin_api.id != "" ? module.project_services.project_id : var.project_id
    source_file_content_hash = local.ga4_setup_source_file_content_hash
    #source_activation_type_configuration_hash = local.activation_type_configuration_file_content_hash 
    #source_activation_application_python_hash = local.activation_application_content_hash
  }
  provisioner "local-exec" {
    command     = <<-EOT
    ${local.poetry_run_alias} ga4-setup --ga4_resource=custom_dimensions --ga4_property_id=${var.ga4_property_id} --ga4_stream_id=${each.value}
    EOT
    working_dir = local.source_root_dir
  }
}

# This resource creates an Artifact Registry repository for the docker images used by the Activation Application.
resource "google_artifact_registry_repository" "activation_repository" {
  project       = null_resource.check_artifactregistry_api.id != "" ? module.project_services.project_id : var.project_id
  location      = var.location
  repository_id = var.artifact_repository_id
  description   = "Docker image repository for the activation application dataflow job base image"
  format        = "DOCKER"
}

module "pipeline_service_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.0"
  project_id = null_resource.check_dataflow_api.id != "" ? module.project_services.project_id : var.project_id
  prefix     = local.app_prefix
  names      = [local.pipeline_service_account_name]
  project_roles = [
    "${module.project_services.project_id}=>roles/dataflow.admin",
    "${module.project_services.project_id}=>roles/dataflow.worker",
    "${module.project_services.project_id}=>roles/bigquery.dataEditor",
    "${module.project_services.project_id}=>roles/bigquery.jobUser",
    "${module.project_services.project_id}=>roles/artifactregistry.writer",
  ]
  display_name = "Dataflow worker Service Account"
  description  = "Activation Dataflow worker Service Account"
}

module "trigger_function_account" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.4.0"
  project_id = null_resource.check_pubsub_api.id != "" ? module.project_services.project_id : var.project_id
  prefix     = local.app_prefix
  names      = [local.trigger_function_account_name]
  project_roles = [
    "${module.project_services.project_id}=>roles/secretmanager.secretAccessor",
    "${module.project_services.project_id}=>roles/dataflow.admin",
    "${module.project_services.project_id}=>roles/dataflow.worker",
    "${module.project_services.project_id}=>roles/bigquery.dataEditor",
    "${module.project_services.project_id}=>roles/pubsub.editor",
    "${module.project_services.project_id}=>roles/storage.admin",
    "${module.project_services.project_id}=>roles/artifactregistry.reader",
    "${module.project_services.project_id}=>roles/iam.serviceAccountUser",
  ]
  display_name = "Cloud Build Job Service Account"
  description  = "Service Account used to submit job the cloud build job"
}

# This an external data that retrieves information about the Google Analytics 4 property using 
# a python command defined in the module ga4_setup.
# This informatoin can then be used in other parts of the Terraform configuration to access the retrieved information.
data "external" "ga4_measurement_properties" {
  for_each    = local.ga4_stream_id_set
  program     = ["bash", "-c", "${local.poetry_run_alias} ga4-setup --ga4_resource=measurement_properties --ga4_property_id=${var.ga4_property_id} --ga4_stream_id=${each.value}"]
  working_dir = local.source_root_dir

  depends_on = [
    module.project_services
  ]
}


# It's used to create unique names for resources like KMS key rings or crypto keys, 
# ensuring they don't clash with existing resources.
resource "random_id" "random_suffix" {
  byte_length = 2
}

# This ensures that Secret Manager has a service identity within your project. 
# This identity is crucial for securely managing secrets and allowing Secret Manager 
# to interact with other Google Cloud services on your behalf.
resource "google_project_service_identity" "secretmanager_sa" {
  provider = google-beta
  project = null_resource.check_cloudkms_api.id != "" ? module.project_services.project_id : var.project_id
  service = "secretmanager.googleapis.com"
}
 # This Key Ring can then be used to store and manage encryption keys for various purposes, 
 # such as encrypting data at rest or protecting secrets.
resource "google_kms_key_ring" "key_ring_regional" {
  name     = "key_ring_regional-${random_id.random_suffix.hex}"
  # If you want your replicas in other locations, change the location in the var.location variable passed as a parameter to this submodule.
  # if you your replicas stored global, set the location = "global".
  location = var.location
  project  = null_resource.check_cloudkms_api.id != "" ? module.project_services.project_id : var.project_id
}

# This key can then be used for various encryption operations, 
# such as encrypting data before storing it in Google Cloud Storage 
# or protecting secrets within your application.
resource "google_kms_crypto_key" "crypto_key_regional" {
  name     = "crypto-key-${random_id.random_suffix.hex}"
  key_ring = google_kms_key_ring.key_ring_regional.id
}

# Defines an IAM policy that explicitly grants the Secret Manager service account 
# the ability to encrypt and decrypt data using a specific CryptoKey. This is a 
# common pattern for securely managing secrets, allowing Secret Manager to encrypt 
# or decrypt data without requiring direct access to the underlying encryption key material.
data "google_iam_policy" "crypto_key_encrypter_decrypter" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    members = [
      "serviceAccount:${google_project_service_identity.secretmanager_sa.email}"
    ]
  }

  depends_on = [
    google_project_service_identity.secretmanager_sa,
    google_kms_key_ring.key_ring_regional,
    google_kms_crypto_key.crypto_key_regional
  ]
}

# It sets the IAM policy for a KMS CryptoKey, specifically granting permissions defined 
# in another data source.
resource "google_kms_crypto_key_iam_policy" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.crypto_key_regional.id
  policy_data = data.google_iam_policy.crypto_key_encrypter_decrypter.policy_data
}

# It sets the IAM policy for a KMS Key Ring, granting specific permissions defined 
# in a data source.
resource "google_kms_key_ring_iam_policy" "key_ring" {
  key_ring_id = google_kms_key_ring.key_ring_regional.id
  policy_data = data.google_iam_policy.crypto_key_encrypter_decrypter.policy_data
}

# This module stores the values ga4-measurement-id and ga4-measurement-secret for each data stream in Google Cloud Secret Manager.
module "data_stream_secrets" {
  for_each   = local.ga4_stream_id_set
  source     = "GoogleCloudPlatform/secret-manager/google"
  version    = "0.4.0"
  project_id = google_kms_crypto_key_iam_policy.crypto_key.etag != "" && google_kms_key_ring_iam_policy.key_ring.etag != "" ? module.project_services.project_id : var.project_id
  secrets = [
    {
      name = "ga4-data-stream-${each.value}"
      secret_data = jsonencode(
        {
          "measurement-id"     = data.external.ga4_measurement_properties[each.value].result["measurement_id"]
          "measurement-secret" = data.external.ga4_measurement_properties[each.value].result["measurement_secret"]
        }
      )
      automatic_replication = false
    },
  ]

  # By commenting the user_managed_replication block, you will deploy replicas that may store the secret in different locations in the globe.
  # This is not a desired behaviour, make sure you're aware of it before doing it.
  # By default, to respect resources location, we prevent resources from being deployed globally by deploying secrets in the same region of the compute resources.
  user_managed_replication = {
    "ga4-data-stream-${each.value}" = [
      # If you want your replicas in other locations, uncomment the following lines and add them here.
      # Check this example, as reference: https://github.com/GoogleCloudPlatform/terraform-google-secret-manager/blob/main/examples/multiple/main.tf#L91
      {
        location = var.location
        kms_key_name = google_kms_crypto_key.crypto_key_regional.id
      }
    ]
  }

  depends_on = [
    data.external.ga4_measurement_properties,
    google_kms_crypto_key.crypto_key_regional,
    google_kms_key_ring.key_ring_regional,
    google_project_service_identity.secretmanager_sa,
    google_kms_crypto_key_iam_policy.crypto_key,
    google_kms_key_ring_iam_policy.key_ring
  ]
}

# This module creates a Cloud Storage bucket to be used by the Activation Application
module "pipeline_bucket" {
  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "6.1.0"
  project_id = null_resource.check_dataflow_api.id != "" ? module.project_services.project_id : var.project_id
  name       = "${local.app_prefix}-app-${module.project_services.project_id}"
  location   = var.location
  # When deleting a bucket, this boolean option will delete all contained objects. 
  # If false, Terraform will fail to delete buckets which contain objects.
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

# This resource binds the service account to the required roles
resource "google_project_iam_member" "cloud_build_job_service_account" {
  depends_on = [
    module.project_services,
    null_resource.check_artifactregistry_api,
    data.google_project.project,
  ]

  project = null_resource.check_artifactregistry_api.id != "" ? module.project_services.project_id : var.project_id
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"

  for_each = toset([
    "roles/cloudbuild.serviceAgent",
    "roles/cloudbuild.builds.builder",
    "roles/cloudbuild.integrations.owner",
    "roles/logging.logWriter",
    "roles/logging.admin",
    "roles/storage.admin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudfunctions.developer",
    "roles/run.admin",
    "roles/appengine.appAdmin",
    "roles/container.developer",
    "roles/compute.instanceAdmin.v1",
    "roles/firebase.admin",
    "roles/cloudkms.cryptoKeyDecrypter",
    "roles/secretmanager.secretAccessor",
    "roles/cloudbuild.workerPoolUser",
    "roles/cloudbuild.serviceAgent",
    "roles/cloudbuild.builds.editor",
    "roles/cloudbuild.builds.viewer",
    "roles/cloudbuild.builds.approver",
    "roles/cloudbuild.integrations.viewer",
    "roles/cloudbuild.integrations.editor",
    "roles/cloudbuild.connectionViewer",
    "roles/cloudbuild.connectionAdmin",
    "roles/cloudbuild.readTokenAccessor",
    "roles/cloudbuild.tokenAccessor",
    "roles/cloudbuild.workerPoolOwner",
    "roles/cloudbuild.workerPoolEditor",
    "roles/cloudbuild.workerPoolViewer",
    "roles/artifactregistry.admin",
    "roles/viewer",
    "roles/owner",
  ])
  role = each.key
}

data "google_project" "project" {
  project_id = null_resource.check_cloudbuild_api != "" ? module.project_services.project_id : var.project_id
}

# This module creates a Cloud Storage bucket to be used by the Cloud Build Log Bucket
module "build_logs_bucket" {
  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "6.1.0"
  project_id = null_resource.check_cloudbuild_api != "" ? module.project_services.project_id : var.project_id
  name       = "${local.app_prefix}-logs-${module.project_services.project_id}"
  location   = var.location
  # When deleting a bucket, this boolean option will delete all contained objects. 
  # If false, Terraform will fail to delete buckets which contain objects.
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

  iam_members = [
    {
      role   = "roles/storage.admin"
      member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
    }
  ]

  depends_on = [
    data.google_project.project,
    google_project_iam_member.cloud_build_job_service_account
  ]
}

# This resource creates a bucket object using as content the audience_segmentation_query_template_file file.
data "template_file" "audience_segmentation_query_template_file" {
  template = file("${local.template_dir}/activation_query/${local.audience_segmentation_query_template_file}")

  vars = {
    mds_project_id     = var.mds_project_id
    mds_dataset_suffix = var.mds_dataset_suffix
  }
}

resource "google_storage_bucket_object" "audience_segmentation_query_template_file" {
  name    = "${local.configuration_folder}/${local.audience_segmentation_query_template_file}"
  content = data.template_file.audience_segmentation_query_template_file.rendered
  bucket  = module.pipeline_bucket.name
}

data "template_file" "auto_audience_segmentation_query_template_file" {
  template = file("${local.template_dir}/activation_query/${local.auto_audience_segmentation_query_template_file}")

  vars = {
    mds_project_id     = var.mds_project_id
    mds_dataset_suffix = var.mds_dataset_suffix
  }
}

# This resource creates a bucket object using as content the auto_audience_segmentation_query_template_file file.
resource "google_storage_bucket_object" "auto_audience_segmentation_query_template_file" {
  name    = "${local.configuration_folder}/${local.auto_audience_segmentation_query_template_file}"
  content = data.template_file.auto_audience_segmentation_query_template_file.rendered
  bucket  = module.pipeline_bucket.name
}

data "template_file" "cltv_query_template_file" {
  template = file("${local.template_dir}/activation_query/${local.cltv_query_template_file}")

  vars = {
    mds_project_id     = var.mds_project_id
    mds_dataset_suffix = var.mds_dataset_suffix
  }
}

# This resource creates a bucket object using as content the cltv_query_template_file file.
resource "google_storage_bucket_object" "cltv_query_template_file" {
  name    = "${local.configuration_folder}/${local.cltv_query_template_file}"
  content = data.template_file.cltv_query_template_file.rendered
  bucket  = module.pipeline_bucket.name
}

data "template_file" "churn_propensity_query_template_file" {
  template = file("${local.template_dir}/activation_query/${local.churn_propensity_query_template_file}")

  vars = {
    mds_project_id     = var.mds_project_id
    mds_dataset_suffix = var.mds_dataset_suffix
  }
}

# This resource creates a bucket object using as content the purchase_propensity_query_template_file file.
resource "google_storage_bucket_object" "churn_propensity_query_template_file" {
  name    = "${local.configuration_folder}/${local.churn_propensity_query_template_file}"
  content = data.template_file.churn_propensity_query_template_file.rendered
  bucket  = module.pipeline_bucket.name
}

data "template_file" "purchase_propensity_query_template_file" {
  template = file("${local.template_dir}/activation_query/${local.purchase_propensity_query_template_file}")

  vars = {
    mds_project_id     = var.mds_project_id
    mds_dataset_suffix = var.mds_dataset_suffix
  }
}

# This resource creates a bucket object using as content the purchase_propensity_query_template_file file.
resource "google_storage_bucket_object" "purchase_propensity_query_template_file" {
  name    = "${local.configuration_folder}/${local.purchase_propensity_query_template_file}"
  content = data.template_file.purchase_propensity_query_template_file.rendered
  bucket  = module.pipeline_bucket.name
}

# This resource creates a bucket object using as content the purchase_propensity_vbb_query_template_file file.
data "template_file" "purchase_propensity_vbb_query_template_file" {
  template = file("${local.template_dir}/activation_query/${local.purchase_propensity_vbb_query_template_file}")

  vars = {
    mds_project_id        = var.mds_project_id
    mds_dataset_suffix    = var.mds_dataset_suffix
    activation_project_id = var.project_id
    dataset               = module.bigquery.bigquery_dataset.dataset_id
  }
}

resource "google_storage_bucket_object" "purchase_propensity_vbb_query_template_file" {
  name    = "${local.configuration_folder}/${local.purchase_propensity_vbb_query_template_file}"
  content = data.template_file.purchase_propensity_vbb_query_template_file.rendered
  bucket  = module.pipeline_bucket.name
}

# This data resources creates a data resource that renders a template file and stores the rendered content in a variable.
data "template_file" "activation_type_configuration" {
  template = file("${local.template_dir}/activation_type_configuration_template.tpl")

  vars = {
    audience_segmentation_query_template_gcs_path      = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.audience_segmentation_query_template_file.output_name}"
    auto_audience_segmentation_query_template_gcs_path = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.auto_audience_segmentation_query_template_file.output_name}"
    cltv_query_template_gcs_path                       = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.cltv_query_template_file.output_name}"
    purchase_propensity_query_template_gcs_path        = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.purchase_propensity_query_template_file.output_name}"
    purchase_propensity_vbb_query_template_gcs_path    = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.purchase_propensity_vbb_query_template_file.output_name}"
    churn_propensity_query_template_gcs_path           = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.churn_propensity_query_template_file.output_name}"
  }
}

# This resource creates a bucket object using as content the activation_type_configuration.json file.
resource "google_storage_bucket_object" "activation_type_configuration_file" {
  name    = "${local.configuration_folder}/activation_type_configuration.json"
  content = data.template_file.activation_type_configuration.rendered
  bucket  = module.pipeline_bucket.name
  # Detects md5hash changes to redeploy this file to the GCS bucket.
  detect_md5hash = base64encode("${local.activation_type_configuration_file_content_hash}${local.activation_application_content_hash}")
}

# This module submits a gcloud build to build a docker container image to be used by the Activation Application
module "activation_pipeline_container" {
  source  = "terraform-google-modules/gcloud/google"
  version = "3.5.0"

  platform = "linux"

  #create_cmd_body  = "builds submit --project=${module.project_services.project_id} --tag ${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name}:latest ${local.pipeline_source_dir}"
  create_cmd_body  = "builds submit --project=${module.project_services.project_id} --tag ${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name}:latest --gcs-log-dir=gs://${module.build_logs_bucket.name} ${local.pipeline_source_dir}"
  destroy_cmd_body = "artifacts docker images delete --project=${module.project_services.project_id} ${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name} --delete-tags"

  create_cmd_triggers = {
    source_contents_hash = local.activation_application_content_hash
  }

  module_depends_on = [
    module.build_logs_bucket
  ]
}

# This module executes a gcloud command to build a dataflow flex template and uploads it to Dataflow
module "activation_pipeline_template" {
  source                = "terraform-google-modules/gcloud/google"
  version               = "3.5.0"

  platform         = "linux"
  create_cmd_body  = "dataflow flex-template build --project=${module.project_services.project_id} \"gs://${module.pipeline_bucket.name}/dataflow/templates/${local.activation_container_image_id}.json\" --image \"${local.docker_repo_prefix}/${google_artifact_registry_repository.activation_repository.name}/${local.activation_container_name}:latest\" --sdk-language \"PYTHON\" --metadata-file \"${local.pipeline_source_dir}/metadata.json\""
  destroy_cmd_body = "storage rm --project=${module.project_services.project_id} \"gs://${module.pipeline_bucket.name}/dataflow/templates/${local.activation_container_image_id}.json\""

  create_cmd_triggers = {
    source_contents_hash = local.activation_application_content_hash
  }

  module_depends_on = [
    module.activation_pipeline_container.wait
  ]
}

# This resource creates a Pub Sub topic to be used by the Activation Application
resource "google_pubsub_topic" "activation_trigger" {
  name    = "activation-trigger"
  project = null_resource.check_pubsub_api.id != "" ? module.project_services.project_id : var.project_id
}

# This data resource generates a ZIP archive file containing the contents of the specified source_dir directory
data "archive_file" "activation_trigger_source" {
  type        = "zip"
  output_path = "${local.trigger_function_dir}/${local.source_archive_file}"
  source_dir  = "${local.trigger_function_dir}/trigger_activation"
}

# This module creates a Cloud Sorage bucket and sets the trigger_function_account_email as the admin.
module "function_bucket" {
  source     = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version    = "6.1.0"
  project_id = null_resource.check_cloudfunctions_api.id != "" ? module.project_services.project_id : var.project_id
  name       = "${local.app_prefix}-trigger-${module.project_services.project_id}"
  location   = var.location
  # When deleting a bucket, this boolean option will delete all contained objects. 
  # If false, Terraform will fail to delete buckets which contain objects.
  force_destroy = true

  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age            = 365
      with_state     = "ANY"
      matches_prefix = module.project_services.project_id
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

# This resource creates a bucket object using as content the activation_trigger_archive zip file.
resource "google_storage_bucket_object" "activation_trigger_archive" {
  name   = local.source_archive_file
  source = data.archive_file.activation_trigger_source.output_path
  bucket = module.function_bucket.name
}

# This resource creates a Cloud Function version 2, with a python 3.11 runtime using the activation_trigger_archive zip file in the bucket as source code.
resource "google_cloudfunctions2_function" "activation_trigger_cf" {
  name     = "activation-trigger"
  project  = null_resource.check_cloudfunctions_api.id != "" ? module.project_services.project_id : var.project_id
  location = var.trigger_function_location

  # Build config to prepare the code to run on Cloud Functions 2
  build_config {
    runtime = "python311"
    source {
      storage_source {
        bucket = module.function_bucket.name
        object = google_storage_bucket_object.activation_trigger_archive.name
      }
    }
    entry_point       = "subscribe"
    docker_repository = "projects/${module.project_services.project_id}/locations/${var.trigger_function_location}/repositories/gcf-artifacts"
  }

  # Sets the trigger for the Cloud Function using the Pub Sub topic created above
  event_trigger {
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.activation_trigger.id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
    trigger_region = var.trigger_function_location
  }

  # Service endpoint configuration for the Cloud Function
  service_config {
    available_memory      = "256M"
    max_instance_count    = 3
    timeout_seconds       = 60
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = module.trigger_function_account.email
    environment_variables = {
      ACTIVATION_PROJECT            = module.project_services.project_id
      ACTIVATION_REGION             = var.location
      ACTIVATION_TYPE_CONFIGURATION = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.activation_type_configuration_file.output_name}"
      TEMPLATE_FILE_GCS_LOCATION    = "gs://${module.pipeline_bucket.name}/dataflow/templates/${local.activation_container_image_id}.json"
      PIPELINE_TEMP_LOCATION        = "gs://${module.pipeline_bucket.name}/tmp/"
      LOG_DATA_SET                  = module.bigquery.bigquery_dataset.dataset_id
      PIPELINE_WORKER_EMAIL         = module.pipeline_service_account.email
      GA4_DATA_STREAMS              = join(",", local.ga4_stream_id_set)
    }
    # Sets the environment variables from the secrets stored on Secret Manager
    dynamic "secret_environment_variables" {
      for_each = local.ga4_stream_id_set
      content {
        project_id = null_resource.check_cloudfunctions_api.id != "" ? module.project_services.project_id : var.project_id
        key        = "GA4_DATA_STREAM_${secret_environment_variables.value}"
        secret     = split("/", module.data_stream_secrets[secret_environment_variables.value].secret_names[0])[3]
        version    = split("/", module.data_stream_secrets[secret_environment_variables.value].secret_versions[0])[5]
      }
    }
  }
  # lifecycle configuration ignores the changes to the source zip file
  lifecycle {
    ignore_changes = [build_config[0].source[0].storage_source[0].generation]
  }
}

# This modules runs cloud commands that adds an invoker policy binding to a Cloud Function, allowing a specific service account to invoke the function.
module "add_invoker_binding" {
  source  = "terraform-google-modules/gcloud/google"
  version = "3.5.0"

  platform = "linux"

  create_cmd_body  = "functions add-invoker-policy-binding ${google_cloudfunctions2_function.activation_trigger_cf.name} --project=${google_cloudfunctions2_function.activation_trigger_cf.project} --region=${google_cloudfunctions2_function.activation_trigger_cf.location}  --member=\"serviceAccount:${data.google_project.activation_project.number}-compute@developer.gserviceaccount.com\""
  destroy_cmd_body = "functions remove-invoker-policy-binding ${google_cloudfunctions2_function.activation_trigger_cf.name} --project=${google_cloudfunctions2_function.activation_trigger_cf.project} --region=${google_cloudfunctions2_function.activation_trigger_cf.location}  --member=\"serviceAccount:${data.google_project.activation_project.number}-compute@developer.gserviceaccount.com\""
}
