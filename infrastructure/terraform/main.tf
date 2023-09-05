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

provider "google" {
  region = var.google_default_region
}

data "google_project" "feature_store_project" {
  project_id = var.feature_store_project_id
}

module "data_store" {
  source = "./modules/data-store"

  source_ga4_export_project_id = var.source_ga4_export_project_id
  source_ga4_export_dataset    = var.source_ga4_export_dataset
  source_ads_export_data       = var.source_ads_export_data

  data_processing_project_id = var.data_processing_project_id
  data_project_id            = var.data_project_id
  destination_data_location  = var.destination_data_location

  dataform_github_repo  = var.dataform_github_repo
  dataform_github_token = var.dataform_github_token

  create_dev_environment     = var.create_dev_environment
  create_staging_environment = var.create_staging_environment
  create_prod_environment    = var.create_prod_environment

  dev_data_project_id           = var.dev_data_project_id
  dev_destination_data_location = var.dev_destination_data_location

  staging_data_project_id           = var.staging_data_project_id
  staging_destination_data_location = var.staging_destination_data_location

  prod_data_project_id           = var.prod_data_project_id
  prod_destination_data_location = var.prod_destination_data_location

  project_owner_email = var.project_owner_email
}

locals {
  source_root_dir    = "../.."
  config_file_name   = "config"
  poetry_run_alias   = "${var.poetry_cmd} run"
  mds_dataset_suffix = var.create_prod_environment ? "prod" : var.create_dev_environment ? "dev" : "staging"
}

resource "local_file" "feature_store_configuration" {
  filename = "${local.source_root_dir}/config/${local.config_file_name}.yaml"
  content = templatefile("${local.source_root_dir}/config/${var.feature_store_config_env}.yaml.tftpl", {
    project_id             = var.feature_store_project_id
    project_name           = data.google_project.feature_store_project.name
    project_number         = data.google_project.feature_store_project.number
    mds_dataset            = "${var.mds_dataset_prefix}_${local.mds_dataset_suffix}"
    pipelines_github_owner = var.pipelines_github_owner
    pipelines_github_repo  = var.pipelines_github_repo
    #    TODO: this needs to be specific to environment.
    location = var.destination_data_location
  })
}

resource "null_resource" "poetry_install" {
  provisioner "local-exec" {
    command     = "${var.poetry_cmd} install"
    working_dir = local.source_root_dir
  }
}

resource "null_resource" "generate_sql_queries" {

  triggers = {
    working_dir = local.source_root_dir
  }

  provisioner "local-exec" {
    command     = <<-EOT
    ${local.poetry_run_alias} inv apply-env-variables-queries --env-name=${local.config_file_name}
    ${local.poetry_run_alias} inv apply-env-variables-procedures --env-name=${local.config_file_name}
    EOT
    working_dir = self.triggers.working_dir
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<-EOT
    rm sql/query/*.sql
    rm sql/procedure/*.sql
    EOT
    working_dir = self.triggers.working_dir
  }

  depends_on = [
    local_file.feature_store_configuration,
    null_resource.poetry_install
  ]
}

module "feature_store" {
  source           = "./modules/feature-store"
  config_file_path = local_file.feature_store_configuration.filename
  enabled          = var.deploy_feature_store
  count            = var.deploy_feature_store ? 1 : 0
  project_id       = var.feature_store_project_id

  depends_on = [
    null_resource.generate_sql_queries
  ]
}

module "pipelines" {
  source           = "./modules/pipelines"
  config_file_path = local_file.feature_store_configuration.filename
  poetry_run_alias = local.poetry_run_alias
  count            = var.deploy_pipelines ? 1 : 0
  depends_on = [
    null_resource.poetry_install
  ]
}

module "activation" {
  source                    = "./modules/activation"
  project_id                = var.activation_project_id
  location                  = var.google_default_region
  trigger_function_location = var.google_default_region
  poetry_cmd                = var.poetry_cmd
  ga4_measurement_id        = var.ga4_measurement_id
  ga4_measurement_secret    = var.ga4_measurement_secret
  ga4_property_id           = var.ga4_property_id
  ga4_stream_id             = var.ga4_stream_id
  count                     = var.deploy_activation ? 1 : 0
}
