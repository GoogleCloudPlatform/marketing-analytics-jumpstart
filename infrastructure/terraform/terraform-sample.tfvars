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

create_dev_environment     = false
create_staging_environment = false
create_prod_environment    = true

deploy_activation    = true
deploy_feature_store = true
deploy_pipelines     = true

####################  DATA VARIABLES  #################################

data_project_id              = "Project id where the MDS datasets will be created"
destination_data_location    = "BigQuery location (either regional or multi-regional) for the MDS BigQuery datasets."
data_processing_project_id   = "Project id where the Dataform will be installed and run"
source_ga4_export_project_id = "Project id which contains the GA4 export dataset"
source_ga4_export_dataset    = "GA4 export dataset name. Do not include the project id, just the name."
source_ads_export_data = [
  { project = "abc", dataset = "dataset1", table_suffix = "_123456" },
  { project = "xyz", dataset = "dataset2", table_suffix = "_567890" }
]

####################  FEATEURE STORE VARIABLES  #################################
feature_store_project_id = "Project ID where feature store resources will be created"

####################  ACTIVATION VARIABLES  #################################

activation_project_id = "Project ID where activation resources will be created"
ga4_property_id       = "Google Analytics property id"
ga4_stream_id         = "Google Analytics data stream id"

####################  GITHUB VARIABLES  #################################

project_owner_email   = "Project owner email"
dataform_github_repo  = "URL of the GitHub or GitLab repo which contains the Dataform scripts. Should start with https://"
dataform_github_token = "GitHub token generated for that repo"
