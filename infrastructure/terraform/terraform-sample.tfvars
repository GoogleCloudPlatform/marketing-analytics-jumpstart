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

####################  INFRA VARIABLES  #################################

tf_state_project_id = "Google Cloud project where the terraform state file is stored"

deploy_dataform      = true
deploy_activation    = true
deploy_feature_store = true
deploy_pipelines     = true
deploy_monitoring    = true

####################  DATA VARIABLES  #################################

data_project_id              = "Project id where the MDS datasets will be created"
property_id                  = "Google Analytics 4 property id to identify an unique MDS deployment"
destination_data_location    = "BigQuery location (either regional or multi-regional) for the MDS BigQuery datasets."
data_processing_project_id   = "Project id where the Dataform will be installed and run"
source_ga4_export_project_id = "Project id which contains the GA4 export dataset"
source_ga4_export_dataset    = "GA4 export dataset name. Do not include the project id, just the name."
source_ads_export_data = [
  { project = "abc", dataset = "dataset1", table_suffix = "_123456" },
  { project = "xyz", dataset = "dataset2", table_suffix = "_567890" }
]

####################  FEATURE STORE VARIABLES  #################################

feature_store_project_id = "Project ID where feature store resources will be created"
# These variables are going to become optional with future deployment
# List of comma separated events used in the lead score feature engineering e.g. (["scroll_50", "scroll_90", "view_search_results", ..])
non_ecomm_events_list = ["scroll_50", "view_search_results"]
# A target event for the lead score propensity feature engineering e.g. "login"
non_ecomm_target_event = "login"

###################  PIPELINE CONFIGURATIONS  ##################################

pipeline_configuration = {
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
    feature-creation-lead-score-propensity = {
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
    segmentation = {
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
    auto_segmentation = {
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
    propensity_clv = {
      training = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    clv = {
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
    lead_score_propensity = {
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

    gemini_insights = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
    reporting_preparation = {
      execution = {
        schedule = {
          state                    = "PAUSED"
        }
      }
    }
}

####################     ML MODEL VARIABLES    #################################

website_url = "Customer Website URL" # i.e. "https://shop.googlemerchandisestore.com/"

####################  ACTIVATION VARIABLES  #################################

activation_project_id = "Project ID where activation resources will be created"

####################  GA4 VARIABLES  #################################

ga4_property_id        = "Google Analytics property id"
ga4_stream_id          = "Google Analytics data stream id"
ga4_measurement_id     = "Google Analytics measurement id"
ga4_measurement_secret = "Google Analytics measurement secret"

####################  GITHUB VARIABLES  #################################

project_owner_email  = "Project owner email"
dataform_github_repo = "URL of the GitHub or GitLab repo which contains the Dataform scripts. Should start with https://"
# Personal access tokens are intended to access GitHub resources on behalf of yourself.
# Generate a github developer token for the repo above following this link:
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic
# If you github token key is invalid the following error will show up in the [Dataform Setting page](../docs/images/dataform_github_token_error.png)
dataform_github_token = "GitHub Developer token generated for the repo above"
