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
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "daily_schedule" {
  type    = string
  default = "2 5 * * *"
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

variable "gitCommitish" {
  type    = string
  default = "main"
}

variable "includedTags" {
  type    = list(string)
  default = []
}