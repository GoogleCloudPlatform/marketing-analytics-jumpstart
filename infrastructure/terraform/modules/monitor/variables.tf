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

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "location" {
  description = "Monitoring dataset location."
  type        = string
}

variable "mds_project_id" {
  type        = string
  description = "MDS Project ID"
}

variable "mds_dataset_suffix" {
  type        = string
  description = "dataset suffix for MDS"
}

variable "mds_location" {
  description = "MDS Dataset location"
  type        = string
}

variable "mds_dataform_workspace" {
  description = "Dataform workspace name"
  type        = string
}

variable "feature_store_project_id" {
  description = "Feature Store Project ID"
  type        = string
}

variable "activation_project_id" {
  description = "Activation Project ID"
  type        = string
}

