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

create_dev_environment     = false
create_staging_environment = false
create_prod_environment    = true

deploy_activation    = true
deploy_feature_store = true
deploy_pipelines     = true

####################  DATA VARIABLES  #################################

data_project_id              = "Project id where the MDS datasets will be created"
data_processing_project_id   = "Project id where the Dataform will be installed and run"
source_ga4_export_project_id = "Project id which contains the GA4 export dataset"
source_ga4_export_dataset    = "GA4 export dataset name. Do not include the project id, just the name."
source_ads_export_data       = [
  { project = "abc", dataset = "dataset1", table_suffix = "_123456" },
  { project = "xyz", dataset = "dataset2", table_suffix = "_567890" }
]

####################  ACTIVATION VARIABLES  #################################

activation_project_id  = "Project ID where activation resources will be created"
# Required. A MEASUREMENT ID and API SECRET generated in the Google Analytics UI. To create a new secret, navigate to:
#   Admin > Data Streams > choose your stream > Measurement Protocol > Create
ga4_measurement_id     = "Measurement ID in GA4"
ga4_measurement_secret = "Client secret for authentication to GA4 API"

####################  GITHUB VARIABLES  #################################

project_owner_email   = "Project owner email"
dataform_github_repo  = "URL of the GitHub or GitLab repo which contains the Dataform scripts. Should start with https://"
dataform_github_token = "GitHub token generated for that repo"
