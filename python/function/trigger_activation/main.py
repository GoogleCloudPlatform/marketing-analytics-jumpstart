# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import base64
import functions_framework 
import json
import os

from datetime import datetime
from google.cloud import dataflow_v1beta3

@functions_framework.cloud_event
def subscribe(cloud_event):
  project_id = os.environ.get('ACTIVATION_PROJECT')
  region = os.environ.get('ACTIVATION_REGION')

  template_file_gcs_location = os.environ.get('TEMPLATE_FILE_GCS_LOCATION')
  ga4_measurement_id = os.environ.get('GA4_MEASUREMENT_ID')
  ga4_measurement_secret = os.environ.get('GA4_MEASUREMENT_SECRET')
  activation_type_configuration = os.environ.get('ACTIVATION_TYPE_CONFIGURATION')
  temp_location = os.environ.get('PIPELINE_TEMP_LOCATION')
  log_db_dataset = os.environ.get('LOG_DATA_SET')
  service_account_email = os.environ.get('PIPELINE_WORKER_EMAIL')

  message_data = base64.b64decode(cloud_event.data["message"]["data"]).decode()
  message_obj = json.loads(message_data)

  activation_type = message_obj['activation_type']
  source_table = message_obj['source_table']

  environment_param = dataflow_v1beta3.FlexTemplateRuntimeEnvironment(service_account_email=service_account_email)

  parameters = {
    'project': project_id,
    'activation_type': activation_type,
    'activation_type_configuration': activation_type_configuration,
    'source_table': source_table,
    'temp_location': temp_location,
    'ga4_measurement_id': ga4_measurement_id,
    'ga4_api_secret': ga4_measurement_secret,
    'log_db_dataset': log_db_dataset
  }
  
  flex_template_param = dataflow_v1beta3.LaunchFlexTemplateParameter(
    job_name=f"activation-pipline-{activation_type.replace('_','-')}-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
    container_spec_gcs_path=template_file_gcs_location,
    environment=environment_param,
    parameters=parameters
  )
  request = dataflow_v1beta3.LaunchFlexTemplateRequest(
    project_id=project_id,
    location=region,
    launch_parameter=flex_template_param
  )

  client = dataflow_v1beta3.FlexTemplatesServiceClient()

  response = client.launch_flex_template(request=request)

  print(response)
