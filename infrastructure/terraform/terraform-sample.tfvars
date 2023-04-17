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

tf_state_project_id          = "Project ID where terraform backend configuration is stored"
source_ga4_export_project_id = "Project id which contains the GA4 export dataset"

source_ga4_export_dataset = "GA4 export dataset name"

data_project_id = "Project id where the MDS datasets will be created"

create_dev_environment     = false
create_staging_environment = false
create_prod_environment    = true

data_processing_project_id = "Project id where the Dataform will be installed and run"

project_owner_email = "Project owner email"

dataform_github_repo = "URL of the GitHub or GitLab repo which contains the Dataform scripts"

dataform_github_token = "GitHub token generated for that repo"

source_ads_export_data = [{ project = "abc", dataset = "dataset1", table_suffix = "_123456" },
{ project = "xyz", dataset = "dataset2", table_suffix = "_567890" }]

activation_project_id  = "Project ID where activation resources are created"
ga4_measurement_id     = "Measurement ID in GA4"
ga4_measurement_secret = "Client secret for authenticatin to GA4 API"

pipelines_github_owner = "Cloud Build github owner account for pipelines"
pipelines_github_repo = "Cloud Build github repository for pipelines"

deploy_activation    = true
deploy_feature_store = true
deploy_pipelines     = true