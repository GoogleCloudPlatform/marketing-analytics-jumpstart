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

# This file contains the main configuration for Marketing Analytics Jumpstart solution.
# This is the main entry point for the Terraform configuration.
# The configuration is divided into multiple modules.
# Each module contains the configuration for a specific component of the solution.
# The modules are:
# - feature_store: The feature store module contains the configuration for the feature store.
# - data_store: The data_store module contains the configuration for the marketing data store.
# - pipelines: The pipelines module contains the configuration for the ML pipelines.
# - activation: The activation module contains the configuration for the activation application.
# - monitoring: The monitoring module contains the configuration for the monitoring dashboards in Looker Studio.
# 
# The configuration is unique for each environment. If you to deploy the solution is a multi-environment scenario,
# you can create a separate Terraform configuration for each environment.
# 
# This solution is designed to be deployed in a Google Cloud project.
# The Terraform backend used is Google Cloud Storage. 
# The Terraform provider used is Google Cloud.
# 
# As a Platform Engineer, you have to keep the terraform.tfvars file and the backend. 
# The terraform.tfvars file contains the configuration values for the solution.
# The backend contains the state file.

# Configure the Google Cloud provider region for this solution. 
# You can set the region in the terraform.tfvars file.
# The default region is us-central1.
# You can deploy and migrate the solution across several regions, check the documentation for more information.
provider "google" {
  region = var.google_default_region
}

data "google_project" "feature_store_project" {
  provider = google
  project_id = var.feature_store_project_id
}

data "google_project" "activation_project" {
  provider = google
  project_id = var.activation_project_id
}

data "google_project" "data_processing_project" {
  provider = google
  project_id = var.data_processing_project_id
}

data "google_project" "data_project" {
  provider = google
  project_id = var.data_project_id
}

# The locals block contains hardcoded values that are used in the configuration for the solution.
# The locals block is used to define variables that are used in the configuration.
locals {
  # The source_root_dir is the root directory of the project.
  source_root_dir    = "../.."
  # The config_file_name is the name of the config file.
  config_file_name   = "config"
  # The poetry_run_alias is the alias of the poetry command.
  poetry_run_alias   = "${var.poetry_cmd} run"
  # The mds_dataset_suffix is the suffix of the marketing data store dataset.
  mds_dataset_suffix = var.create_staging_environment ? "staging" : var.create_dev_environment ? "dev" : "prod"
  # The project_toml_file_path is the path to the project.toml file.
  project_toml_file_path    = "${local.source_root_dir}/pyproject.toml"
  # The project_toml_content_hash is the hash of the project.toml file.
  # This is used for the triggers of the local-exec provisioner.
  project_toml_content_hash = filesha512(local.project_toml_file_path)
  # The generated_sql_queries_directory_path is the path to the generated sql queries directory.
  generated_sql_queries_directory_path = "${local.source_root_dir}/sql/query"
  # The generated_sql_queries_fileset is the list of files in the generated sql queries directory.
  generated_sql_queries_fileset        = [for f in fileset(local.generated_sql_queries_directory_path, "*.sqlx") : "${local.generated_sql_queries_directory_path}/${f}"]
  # The generated_sql_queries_content_hash is the sha512 hash of file sha512 hashes in the generated sql queries directory.
  generated_sql_queries_content_hash   = sha512(join("", [for f in local.generated_sql_queries_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))
  # The generated_sql_procedures_directory_path is the path to the generated sql procedures directory.
  generated_sql_procedures_directory_path = "${local.source_root_dir}/sql/procedure"
  # The generated_sql_procedures_fileset is the list of files in the generated sql procedures directory.
  generated_sql_procedures_fileset        = [for f in fileset(local.generated_sql_procedures_directory_path, "*.sqlx") : "${local.generated_sql_procedures_directory_path}/${f}"]
  # The generated_sql_procedures_content_hash is the sha512 hash of file sha512 hashes in the generated sql procedures directory.
  generated_sql_procedures_content_hash   = sha512(join("", [for f in local.generated_sql_procedures_fileset : fileexists(f) ? filesha512(f) : sha512("file-not-found")]))
}


# Create a configuration file for the feature store.
# the template file is located at 
# ${local.source_root_dir}/config/${var.feature_store_config_env}.yaml.tftpl.
# This variable can be set in the terraform.tfvars file. Its default value is "config".
#
#The template file contains the configuration for the feature store. 
#The variables that are replaced with values from the Terraform configuration are:
# project_id: The ID of the Google Cloud project that the feature store will be created in.
# project_name: The name of the Google Cloud project that the feature store will be created in.
# project_number: The number of the Google Cloud project that the feature store will be created in.
# cloud_region: The region in which the feature store will be created.
# mds_project_id: The ID of the Google Cloud project that the feature store will be created in.
# mds_dataset: The name of the dataset that the feature store will be created in.
# pipelines_github_owner: The owner of the GitHub repository that contains the pipelines code.
# pipelines_github_repo: The name of the GitHub repository that contains the pipelines code.
# location: The location in which the feature store will be created.
resource "local_file" "feature_store_configuration" {
  filename = "${local.source_root_dir}/config/${local.config_file_name}.yaml"
  content = templatefile("${local.source_root_dir}/config/${var.feature_store_config_env}.yaml.tftpl", {
    project_id             = var.feature_store_project_id
    project_name           = data.google_project.feature_store_project.name
    project_number         = data.google_project.feature_store_project.number
    cloud_region           = var.google_default_region
    mds_project_id         = var.data_project_id
    mds_dataset            = "${var.mds_dataset_prefix}_${local.mds_dataset_suffix}"
    website_url            = var.website_url
    pipelines_github_owner = var.pipelines_github_owner
    pipelines_github_repo  = var.pipelines_github_repo
    #    TODO: this needs to be specific to environment.
    location = var.destination_data_location
  })
}

# Runs the poetry command to install the dependencies.
# The command is: poetry install
resource "null_resource" "poetry_install" {
  triggers = {
    create_command       = "${var.poetry_cmd} lock && ${var.poetry_cmd} install"
    source_contents_hash = local.project_toml_content_hash
  }

  # Only run the command when `terraform apply` executes and the resource doesn't exist.
  provisioner "local-exec" {
    when        = create
    command     = self.triggers.create_command
    working_dir = local.source_root_dir
  }
}

data "external" "check_ga4_property_type" {
  program     = ["bash", "-c", "${local.poetry_run_alias} ga4-setup --ga4_resource=check_property_type --ga4_property_id=${var.ga4_property_id} --ga4_stream_id=${var.ga4_stream_id}"]
  working_dir = local.source_root_dir
  depends_on  = [null_resource.poetry_install]
}

# Runs the poetry invoke command to generate the sql queries and procedures.
# This command is executed before the feature store is created.
resource "null_resource" "generate_sql_queries" {

  triggers = {
    # The create command generates the sql queries and procedures.
    # The command is: poetry inv [function_name] --env-name=${local.config_file_name}
    # The --env-name argument is the name of the configuration file.
    create_command = <<-EOT
    ${local.poetry_run_alias} inv apply-config-parameters-to-all-queries --env-name=${local.config_file_name}
    ${local.poetry_run_alias} inv apply-config-parameters-to-all-procedures --env-name=${local.config_file_name}
    EOT

    # The destroy command removes the generated sql queries and procedures.
    destroy_command = <<-EOT
    rm -f sql/query/*.sql
    rm -f sql/procedure/*.sql
    EOT

    # The working directory is the root of the project.
    working_dir = local.source_root_dir

    # The poetry_installed trigger is the ID of the null_resource.poetry_install resource.
    # This is used to ensure that the poetry command is run before the generate_sql_queries command.
    poetry_installed = null_resource.poetry_install.id

    # The source_contents_hash trigger is the hash of the project.toml file.
    # This is used to ensure that the generate_sql_queries command is run only if the project.toml file has changed.
    # It also ensures that the generate_sql_queries command is run only if the sql queries and procedures have changed.
    source_contents_hash        = local_file.feature_store_configuration.content_sha512
    destination_queries_hash    = local.generated_sql_queries_content_hash
    destination_procedures_hash = local.generated_sql_procedures_content_hash
  }

  # Only run the command when `terraform apply` executes and the resource doesn't exist.
  provisioner "local-exec" {
    when        = create
    command     = self.triggers.create_command
    working_dir = self.triggers.working_dir
  }

  # Only run the command when `terraform destroy` executes and the resource exists.
  #provisioner "local-exec" {
  #  when        = destroy
  #  command     = self.triggers.destroy_command
  #  working_dir = self.triggers.working_dir
  #}

  lifecycle {
    precondition {
      condition     = data.external.check_ga4_property_type.result["supported"] == "True"
      error_message = "The configured GA4 property is not supported"
    }
  }
}


module "initial_project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "14.1.0"

  disable_dependent_services  = false
  disable_services_on_destroy = false

  project_id = var.tf_state_project_id

  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com"
  ]
}

# This resource executes gcloud commands to check whether the Cloud Resource Manager API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_cloudresourcemanager_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.initial_project_services.project_id} | grep -i "cloudresourcemanager.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "cloudresourcemanager api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.initial_project_services
  ]
}


# This resource executes gcloud commands to check whether the service usage API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_serviceusage_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.initial_project_services.project_id} | grep -i "serviceusage.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "serviceusage api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.initial_project_services
  ]
}


# This resource executes gcloud commands to check whether the IAM API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_iam_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.initial_project_services.project_id} | grep -i "iam.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "iam api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.initial_project_services
  ]
}

# Create the data store module.
# The data store module creates the marketing data store in BigQuery, creates the ETL pipeline in Dataform 
# for the marketing data from Google Ads and Google Analytics. 
# The data store is created only if the `create_prod_environment`, `create_staging_environment` 
# or `create_dev_environment` variable is set to true in the terraform.tfvars file.
# The data store is created in the `data_project_id` project.
module "data_store" {
  # The source directory of the data store module.
  source = "./modules/data-store"

  # The google_default_region variable is set in the terraform.tfvars file. Its default value is "us-central1".
  google_default_region = var.google_default_region

  # The dataform_region is set in the terraform.tfvars file. Its default value is "us-central1".
  dataform_region       = var.dataform_region

  # The source_ga4_export_project_id is set in the terraform.tfvars file. 
  # The source_ga4_export_dataset is set in the terraform.tfvars file. 
  # The source_ads_export_data is set in the terraform.tfvars file.
  source_ga4_export_project_id = var.source_ga4_export_project_id
  source_ga4_export_dataset    = var.source_ga4_export_dataset
  source_ads_export_data       = var.source_ads_export_data
  ga4_incremental_processing_days_back = var.ga4_incremental_processing_days_back

  # The data_processing_project_id is set in the terraform.tfvars file.
  # The data_project_id is set in the terraform.tfvars file. 
  # The destination_data_location is set in the terraform.tfvars file.
  data_processing_project_id = var.data_processing_project_id
  data_project_id            = var.data_project_id
  destination_data_location  = var.destination_data_location
 
  # The dataform_github_repo is set in the terraform.tfvars file. 
  # The dataform_github_token is set in the terraform.tfvars file.
  dataform_github_repo  = var.dataform_github_repo
  dataform_github_token = var.dataform_github_token

  # The create_dev_environment is set in the terraform.tfvars file. 
  # The create_dev_environment determines if the dev environment is created. 
  # When the value is true, the dev environment is created.
  # The create_staging_environment is set in the terraform.tfvars file. 
  # The create_staging_environment determines if the staging environment is created. 
  # When the value is true, the staging environment is created.
  # The create_prod_environment is set in the terraform.tfvars file.
  # The create_prod_environment determines if the prod environment is created. 
  # When the value is true, the prod environment is created.
  create_dev_environment     = var.create_dev_environment
  create_staging_environment = var.create_staging_environment
  create_prod_environment    = var.create_prod_environment

  # The dev_data_project_id is the project ID of where the dev datasets will created. 
  #If not provided, data_project_id will be used.
  # The dev_destination_data_location is the location of the dev datasets. 
  # If not provided, destination_data_location will be used.
  dev_data_project_id           = var.dev_data_project_id
  dev_destination_data_location = var.dev_destination_data_location

  # The staging_data_project_id is the project ID of where the staging datasets will created. 
  # If not provided, data_project_id will be used.
  # The staging_destination_data_location is the location of the staging datasets.
  # If not provided, destination_data_location will be used. 
  staging_data_project_id           = var.staging_data_project_id
  staging_destination_data_location = var.staging_destination_data_location

  # The prod_data_project_id is the project id of where the prod datasets will created. 
  # If not provided, data_project_id will be used.
  # The prod_destination_data_location is the location of the staging datasets.
  # If not provided, destination_data_location will be used. 
  prod_data_project_id           = var.prod_data_project_id
  prod_destination_data_location = var.prod_destination_data_location

  # The project_owner_email is set in the terraform.tfvars file. 
  # An example of a valid email address is "william.mckinley@my-own-personal-domain.com".
  project_owner_email = var.project_owner_email
}



# Create the feature store module.
# The feature store module creates the feature store and the sql queries and procedures in BigQuery.
# The feature store is created only if the `deploy_feature_store` variable is set to true in the terraform.tfvars file.
# The feature store is created in the `feature_store_project_id` project.
module "feature_store" {
  # The source is the path to the feature store module.
  source           = "./modules/feature-store"
  config_file_path = local_file.feature_store_configuration.id != "" ? local_file.feature_store_configuration.filename : ""
  enabled          = var.deploy_feature_store
  # the count determines if the feature store is created or not.
  # If the count is 1, the feature store is created.
  # If the count is 0, the feature store is not created.
  # This is done to avoid creating the feature store if the `deploy_feature_store` variable is set to false in the terraform.tfvars file.
  count            = var.deploy_feature_store ? 1 : 0
  project_id       = var.feature_store_project_id
  # The region is the region in which the feature store is created.
  # This is set to the default region in the terraform.tfvars file.
  region           = var.google_default_region
  # The sql_dir_input is the path to the sql directory.
  # This is set to the path to the sql directory in the feature store module.
  sql_dir_input    = null_resource.generate_sql_queries.id != "" ? "${local.source_root_dir}/sql" : ""
}



# Create the pipelines module.
# The pipelines module creates the ML pipelines in Vertex AI Pipelines.
# The pipelines are created only if the `deploy_pipelines` variable is set to true in the terraform.tfvars file.
# The pipelines are created in the `data_project_id` project.
module "pipelines" {
  # The source is the path to the pipelines module.
  source           = "./modules/pipelines"
  config_file_path = local_file.feature_store_configuration.id != "" ? local_file.feature_store_configuration.filename : ""
  poetry_run_alias = local.poetry_run_alias
  # The count determines if the pipelines are created or not.
  # If the count is 1, the pipelines are created.
  # If the count is 0, the pipelines are not created.
  # This is done to avoid creating the pipelines if the `deploy_pipelines` variable is set to false in the terraform.tfvars file.
  count            = var.deploy_pipelines ? 1 : 0
  # The poetry_installed trigger is the ID of the null_resource.poetry_install resource.
    # This is used to ensure that the poetry command is run before the pipelines module is created.
  poetry_installed = null_resource.poetry_install.id
  # The project_id is the project in which the data is stored.
  # This is set to the data project ID in the terraform.tfvars file.
  mds_project_id   = var.data_project_id
}



# Create the activation module.
# The activation module creates the activation function in Cloud Functions.
# The activation function is created only if the `deploy_activation` variable is set to true in the terraform.tfvars file.
# The activation function is created in the `activation_project_id` project.
module "activation" {
  # The source is the path to the activation module.
  source                    = "./modules/activation"
  # The project_id is the project in which the activation function is created.
  # This is set to the activation project ID in the terraform.tfvars file.
  project_id                = var.activation_project_id
  # The project number of where the activation function is created.
  # This is retrieved from the activation project id using the google_project data source. 
  project_number            = data.google_project.activation_project.number
  # The location is the google_default_region variable. 
  # This is set to the default region in the terraform.tfvars file.
  location                  = var.google_default_region
  # The data_location is the destination_data_location variable. 
  # This is set to the destination data location in the terraform.tfvars file.
  data_location             = var.destination_data_location
  # The trigger_function_location is the location of the trigger function.
  # The trigger function is used to trigger the activation function.
  # The trigger function is created in the same region as the activation function.
  trigger_function_location = var.google_default_region
  # The poetry_cmd is the poetry_cmd variable.
  # This can be set on the poetry_cmd in the terraform.tfvars file.
  poetry_cmd                = var.poetry_cmd
  # The ga4_measurement_id is the ga4_measurement_id variable.
  # This can be set on the ga4_measurement_id in the terraform.tfvars file.
  ga4_measurement_id        = var.ga4_measurement_id
  # The ga4_measurement_secret is the ga4_measurement_secret variable.
  # This can be set on the ga4_measurement_secret in the terraform.tfvars file.
  ga4_measurement_secret    = var.ga4_measurement_secret
  # The ga4_property_id is the ga4_property_id variable.
  # This is set on the ga4_property_id in the terraform.tfvars file.
  # The ga4_property_id is the property ID of the GA4 data. 
  # You can find the property ID in the GA4 console.
  ga4_property_id           = var.ga4_property_id
  # The ga4_stream_id is the ga4_stream_id variable.
  # This is set on the ga4_stream_id in the terraform.tfvars file.
  # The ga4_stream_id is the stream ID of the GA4 data.
  # You can find the stream ID in the GA4 console.
  ga4_stream_id             = var.ga4_stream_id
  # The count determines if the activation function is created or not.
  # If the count is 1, the activation function is created.
  # If the count is 0, the activation function is not created.
  # This is done to avoid creating the activation function if the `deploy_activation` variable is set 
  # to false in the terraform.tfvars file.
  count                     = var.deploy_activation ? 1 : 0
  # The poetry_installed is the ID of the null_resource poetry_install
  # This is used to ensure that the poetry command is run before the activation module is created.
  poetry_installed          = null_resource.poetry_install.id
  mds_project_id            = var.data_project_id
  mds_dataset_suffix        = local.mds_dataset_suffix

  # The project_owner_email is set in the terraform.tfvars file. 
  # An example of a valid email address is "william.mckinley@my-own-personal-domain.com".
  project_owner_email = var.project_owner_email
}



# Create the monitoring module.
# The monitoring module creates the monitoring resources in Cloud Monitoring and Looker Studio.
# The monitoring resources are created only if the `deploy_monitoring` variable is set to true in the terraform.tfvars file.
# The monitoring resources are created in the `data_project_id` project.
module "monitoring" {
  source                   = "./modules/monitor"
  count                    = var.deploy_monitoring ? 1 : 0
  project_id               = var.data_project_id
  location                 = var.google_default_region
  mds_project_id           = var.data_project_id
  mds_dataset_suffix       = local.mds_dataset_suffix
  mds_location             = var.google_default_region
  mds_dataform_workspace   = var.dataform_workspace
  feature_store_project_id = var.feature_store_project_id
  activation_project_id    = var.activation_project_id
}
