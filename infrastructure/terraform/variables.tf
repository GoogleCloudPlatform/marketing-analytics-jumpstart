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

variable "tf_state_project_id" {
  type        = string
  description = "Project ID where terraform backend configuration is stored"
}

variable "data_project_id" {
  description = "Project to contain the MDS BigQuery datasets. "
  type        = string
}

variable "data_processing_project_id" {
  description = "Project to run Dataform jobs"
  type        = string
}

variable "google_default_region" {
  default     = "us-central1"
  description = "The default Google Cloud region."
  type        = string
}

variable "project_owner_email" {
  description = "Email address of the project owner."
  type        = string
}

variable "dataform_github_repo" {
  description = "Private Github repo for Dataform."
  type        = string
}

variable "dataform_github_token" {
  description = "Github token for Dataform repo."
  type        = string
}

variable "create_dev_environment" {
  description = "Indicates that a development environment needs to be created"
  type        = bool
  default     = true
}

variable "dev_data_project_id" {
  description = "Project ID of where the dev datasets will created. If not provided, data_project_id will be used."
  type        = string
  default     = ""
}

variable "create_staging_environment" {
  description = "Indicates that a staging environment needs to be created"
  type        = bool
  default     = true
}

variable "staging_data_project_id" {
  description = "Project ID of where the staging datasets will created. If not provided, data_project_id will be used."
  type        = string
  default     = ""
}

variable "create_prod_environment" {
  description = "Indicates that a production environment needs to be created"
  type        = bool
  default     = true
}

variable "prod_data_project_id" {
  description = "Project ID of where the prod datasets will created. If not provided, data_project_id will be used."
  type        = string
  default     = ""
}

variable "source_ga4_export_project_id" {
  description = "Project containing the GA4 exported data"
  type        = string
}

variable "source_ga4_export_dataset" {
  description = "Dataset containing the GA4 exported data"
  type        = string
}

variable "source_ads_export_data" {
  description = "List of BigQuery's Ads Data Transfer datasets"
  type = list(object({
    project      = string
    dataset      = string
    table_suffix = string
  }))
}

variable "activation_project_id" {
  type        = string
  description = "Project ID where activation resources are created"
}

variable "ga4_measurement_id" {
  description = "Measurement ID in GA4"
  type        = string
}

variable "ga4_measurement_secret" {
  description = "Client secret for authenticatin to GA4 api"
  type        = string
}

variable "deploy_activation" {
  description = "Toggler for activation module"
  type        = bool
  default     = false
}

variable "deploy_feature_store" {
  description = "Toggler for feature store module"
  type        = bool
  default     = false
}

variable "deploy_pipelines" {
  description = "Toggler for pipeliens module"
  type        = bool
  default     = false
}

variable "mds_dataset_prefix" {
  description = "Marketing data store dataset prefix"
  type        = string
  default     = "marketing_ga4_v1"
}

variable "feature_store_config_env" {
  description = "determine which config file is used for feature store deployment"
  type        = string
  default     = "config"
}

variable "pipelines_github_repo" {
  description = "Cloud Build github repository for pipelines"
  type        = string
}

variable "pipelines_github_owner" {
  description = "Cloud Build github repository owner"
  type        = string
}

variable "poetry_cmd" {
  description = "alias for poetry run command on the current system"
  type        = string
  default     = "poetry"
}
