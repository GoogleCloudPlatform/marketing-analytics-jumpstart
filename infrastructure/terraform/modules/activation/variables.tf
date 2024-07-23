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

variable "project_number" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "location" {
  description = "Pipeline location."
  type        = string
}

variable "data_location" {
  description = "Data storage region for activation data"
  type        = string
}

variable "artifact_repository_id" {
  description = "Container repository id"
  type        = string
  default     = "activation-docker-repo"
}

variable "trigger_function_location" {
  description = "Location of the trigger cloud function"
  type        = string
}

variable "poetry_cmd" {
  description = "alias for poetry command on the current system"
  type        = string
}

variable "ga4_measurement_id" {
  description = "Measurement ID in GA4"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ga4_measurement_secret" {
  description = "Client secret for authenticating to GA4 API"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ga4_property_id" {
  description = "Google Analytics property id"
  type        = string
}

variable "ga4_stream_id" {
  description = "Google Analytics data stream id"
  type        = string
}

variable "poetry_installed" {
  description = "Construct to specify dependency to poetry installed"
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

variable "project_owner_email" {
  description = "Email address of the project owner."
  type        = string
}