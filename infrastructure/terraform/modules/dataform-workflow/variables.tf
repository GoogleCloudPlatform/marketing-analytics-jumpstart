# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "project_id" {
  description = "Project ID where the workflow will be created"
  type        = string
}

variable "region" {
  description = "Region where the workflow will be created"
  type        = string
}

variable "environment" {
  type = string
}

variable "daily_schedule" {
  type    = string
  # This schedule executes every days, each 2 hours between 5AM and 11PM.
  default = "0 5-23/2 * * *" #"2 5 * * *"
}

variable "dataform_repository_id" {
  type = string
}

variable "source_ga4_export_project_id" {
  type = string
}

variable "source_ga4_export_dataset" {
  type = string
}

variable "ga4_incremental_processing_days_back" {
  type = string
  default = "3"
}

variable "source_ads_export_data" {
  type = list(object({
    project      = string
    dataset      = string
    table_suffix = string
  }))
}


variable "destination_bigquery_project_id" {
  type = string
}

variable "destination_bigquery_dataset_location" {
  type = string
}

variable "gitCommitish" {
  type    = string
  default = "main"
}

variable "includedTags" {
  type    = list(string)
  default = []
}