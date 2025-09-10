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

tf_state_project_id   = "${MAJ_DEFAULT_PROJECT_ID}"
main_project_id   = "${MAJ_DEFAULT_PROJECT_ID}"
google_default_region = "${MAJ_DEFAULT_REGION}"

deploy_dataform      = true
deploy_activation    = true
deploy_feature_store = true
deploy_pipelines     = true
deploy_monitoring    = false

####################  DATA VARIABLES  #################################

data_project_id              = "${MAJ_MDS_PROJECT_ID}"
destination_data_location    = "${MAJ_MDS_DATA_LOCATION}"
property_id                  = "${MAJ_GA4_PROPERTY_ID}"
data_processing_project_id   = "${MAJ_MDS_DATAFORM_PROJECT_ID}"
source_ga4_export_project_id = "${MAJ_GA4_EXPORT_PROJECT_ID}"
source_ga4_export_dataset    = "${MAJ_GA4_EXPORT_DATASET}"
source_ads_export_data = [
  { project = "${MAJ_ADS_EXPORT_PROJECT_ID}", dataset = "${MAJ_ADS_EXPORT_DATASET}", table_suffix = "${MAJ_ADS_EXPORT_TABLE_SUFFIX}" }]

####################  FEATURE STORE VARIABLES  #################################

feature_store_project_id = "${MAJ_FEATURE_STORE_PROJECT_ID}"
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
          state                    = "ACTIVE"
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
          state                    = "ACTIVE"
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
          state                    = "ACTIVE"
        }
      }
      prediction = {
        schedule = {
          state                    = "ACTIVE"
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
          state                    = "ACTIVE"
        }
      }
      prediction = {
        schedule = {
          state                    = "ACTIVE"
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

website_url = "${MAJ_WEBSITE_URL}"

####################  ACTIVATION VARIABLES  #################################

activation_project_id = "${MAJ_ACTIVATION_PROJECT_ID}"
ga4_property_id       = "${MAJ_GA4_PROPERTY_ID}"
ga4_stream_id         = "${MAJ_GA4_STREAM_ID}"

####################  GITHUB VARIABLES  #################################

project_owner_email   = "${MAJ_DATAFORM_REPO_OWNER_EMAIL}"
dataform_github_repo  = "${MAJ_DATAFORM_GITHUB_REPO_URL}"
dataform_github_token = "${MAJ_DATAFORM_GITHUB_TOKEN}"
