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
  description = "Google Cloud project where the terraform state file is stored"
  type        = string
}

variable "data_project_id" {
  description = "Default project to contain the MDS BigQuery datasets"
  type        = string
}

variable "destination_data_location" {
  description = "Default location for the MDS BigQuery datasets"
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

variable "dataform_region" {
  description = "Specify dataform region when dataform is not available in the default cloud region of choice"
  type        = string
  default     = ""
}

variable "dataform_workspace" {
  description = "Dataform workspace name"
  type        = string
  default     = "demo"
}

variable "project_owner_email" {
  description = "Email address of the project owner."
  type        = string
}

variable "dataform_github_repo" {
  description = "Private GitHub repo for Dataform."
  type        = string
  validation {
    condition     = substr(var.dataform_github_repo, 0, 8) == "https://"
    error_message = "The URL should be an existing GitHub or GitLab repo."
  }
}

variable "dataform_github_token" {
  description = "GitHub token for Dataform repo."
  type        = string
}

variable "pipelines_github_repo" {
  description = "Cloud Build github repository for pipelines"
  type        = string
  default     = "temporarily unused"
}

variable "pipelines_github_owner" {
  description = "Cloud Build github repository owner"
  type        = string
  default     = "temporarily unused"
}

variable "dev_data_project_id" {
  description = "Project ID of where the dev datasets will created. If not provided, data_project_id will be used."
  type        = string
  default     = ""
}

variable "dev_destination_data_location" {
  description = "Location for the MDS BigQuery dev datasets. If not provided destination_data_location will be used."
  type        = string
  default     = ""
}

variable "staging_data_project_id" {
  description = "Project ID of where the staging datasets will created. If not provided, data_project_id will be used."
  type        = string
  default     = ""
}

variable "staging_destination_data_location" {
  description = "Location for the MDS BigQuery dev datasets. If not provided staging_data_location will be used."
  type        = string
  default     = ""
}

variable "property_id" {
  description = "Google Analytics 4 Property ID to install the MDS"
  type        = string
  default     = ""
}

variable "prod_data_project_id" {
  description = "Project ID of where the prod datasets will created. If not provided, data_project_id will be used."
  type        = string
  default     = ""
}

variable "prod_destination_data_location" {
  description = "Location for the MDS BigQuery prod datasets. If not provided destination_data_location will be used."
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

variable "ga4_incremental_processing_days_back" {
  description = "Past number of days to process GA4 exported data"
  type        = string
  default     = "3"
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

variable "ga4_property_id" {
  description = "Google Analytics property id"
  type        = string
}

variable "ga4_stream_id" {
  description = "Google Analytics data stream id"
  type        = string
}

variable "ga4_measurement_id" {
  description = "Measurement ID in GA4"
  type        = string
  default     = null
  sensitive   = true
}

variable "ga4_measurement_secret" {
  description = "Client secret for authenticating to GA4 API"
  type        = string
  default     = null
  sensitive   = true
}

variable "deploy_dataform" {
  description = "Toggler for activation module"
  type        = bool
  default     = false
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

variable "deploy_monitoring" {
  description = "Toggler for monitoring module"
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

variable "uv_cmd" {
  description = "alias for uv run command on the current system"
  type        = string
  default     = "uv"
}

variable "feature_store_project_id" {
  type        = string
  description = "Project ID where feature store resources are created"
}

variable "website_url" {
  description = "Website url to be provided to the auto segmentation model"
  type        = string
  default     = null
}

variable "time_zone" {
  description = "Timezone for scheduled jobs"
  type        = string
  default     = "America/New_York"
}

variable "pipeline_configuration" {
  description = "Pipeline configuration that will alternate certain settings in the config.yaml.tftpl"
  type = map(
    map(
      object({
        schedule        = object({
          # The `state` defines the state of the pipeline.
          # In case you don't want to schedule the pipeline, set the state to `PAUSED`.
          state                    = string
        })
      })
    )
  )

  default = {
    feature-creation-auto-audience-segmentation = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    feature-creation-audience-segmentation = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    feature-creation-purchase-propensity = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    feature-creation-churn-propensity = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    feature-creation-customer-ltv = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    feature-creation-aggregated-value-based-bidding = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    value_based_bidding = {
      training = {
        schedule = {
          state                    = "PAUSED"
        }
      }
      explanation = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    purchase_propensity = {
      training = {
        schedule = {
          state                    = "PAUSED"
        }
      }
      prediction = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    churn_propensity = {
      training = {
        schedule = {
          state                    = "PAUSED"
        }
      }
      prediction = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
  }
  validation {
    condition = alltrue([
      for p in keys(var.pipeline_configuration) : alltrue([
        for c in keys(var.pipeline_configuration[p]) : (
          try(var.pipeline_configuration[p][c].schedule.state, "") == "ACTIVE" ||
          try(var.pipeline_configuration[p][c].schedule.state, "") == "PAUSED"
        )
      ])
    ])
    error_message = "The 'state' field must be either 'PAUSED' or 'ACTIVE' for all pipeline configurations."
  }
}
