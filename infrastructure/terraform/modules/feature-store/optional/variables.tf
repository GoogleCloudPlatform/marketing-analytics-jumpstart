# Copyright 2025 Google LLC
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

variable "config_file_path" {
  type        = string
  description = "feature store config file"
}

variable "enabled" {
  type        = bool
  description = "Toogle all resources in module"
}

variable "region" {
  description = "feature store region"
  type        = string
}

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "sql_dir_input" {
  type        = string
  description = "SQL queries directory"
}

variable "uv_run_alias" {
  description = "alias for uv run command on the current system"
  type        = string
  default     = "uv run"
}

variable "feature_store_dataset_id" {
  description = "feature store dataset id"
  type        = string
  default     = "feature_store"
}

variable "feature_store_project_id" {
  description = "feature store project id"
  type        = string
  default     = ""
}