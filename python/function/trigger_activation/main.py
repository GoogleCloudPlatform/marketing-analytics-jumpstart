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

from google.api_core.gapic_v1.client_info import ClientInfo

USER_AGENT_ACTIVATION = 'cloud-solutions/marketing-analytics-jumpstart-activation-v1'

@functions_framework.cloud_event
def subscribe(cloud_event):
  """
  This function is triggered by a Pub/Sub message. The message contains the activation type and the source table.
  The function then launches a Dataflow Flex Template to process the data and send the activation events to GA4.
  This function demonstrates how to use Cloud Functions to trigger a Dataflow Flex Template based on a Pub/Sub message. 
  This allows for automated processing of data and sending activation events to GA4.

  Args:
      cloud_event: The CloudEvent message.

  Returns:
      None.
  """

  # ACTIVATION_PROJECT: The Google Cloud project ID.
  project_id = os.environ.get('ACTIVATION_PROJECT')
  # ACTIVATION_REGION: The Google Cloud region where the Dataflow Flex Template will be launched.
  region = os.environ.get('ACTIVATION_REGION')
  # TEMPLATE_FILE_GCS_LOCATION: The Google Cloud Storage location of the Dataflow Flex Template file.
  template_file_gcs_location = os.environ.get('TEMPLATE_FILE_GCS_LOCATION')
  # GA4_MEASUREMENT_ID: The Google Analytics 4 measurement ID.
  ga4_measurement_id = os.environ.get('GA4_MEASUREMENT_ID')
  # GA4_MEASUREMENT_SECRET: The Google Analytics 4 measurement secret.
  ga4_measurement_secret = os.environ.get('GA4_MEASUREMENT_SECRET')
  # ACTIVATION_TYPE_CONFIGURATION: The path to a JSON file containing the configuration for the activation type.
  activation_type_configuration = os.environ.get('ACTIVATION_TYPE_CONFIGURATION')
  # PIPELINE_TEMP_LOCATION: The Google Cloud Storage location for temporary files used by the Dataflow Flex Template.
  temp_location = os.environ.get('PIPELINE_TEMP_LOCATION')
  # LOG_DATA_SET: The BigQuery dataset where the logs of the Dataflow Flex Template will be stored.
  log_db_dataset = os.environ.get('LOG_DATA_SET')
  # PIPELINE_WORKER_EMAIL: The service account email used by the Dataflow Flex Template workers.
  service_account_email = os.environ.get('PIPELINE_WORKER_EMAIL')

  # Decodes the base64 encoded data in the message and parses it as JSON.
  # It then extracts the activation_type and source_table values from the JSON object.
  message_data = base64.b64decode(cloud_event.data["message"]["data"]).decode()
  message_obj = json.loads(message_data)

  activation_type = message_obj['activation_type']
  source_table = message_obj['source_table']

  # Creates a FlexTemplateRuntimeEnvironment object with the service account email.
  environment_param = dataflow_v1beta3.FlexTemplateRuntimeEnvironment(service_account_email=service_account_email)

  # It then creates a dictionary of parameters for the Dataflow Flex Template, including the project ID, activation type, 
  # activation type configuration, source table, temporary location, GA4 measurement ID, GA4 measurement secret, and log dataset.
  # Finally, it creates a LaunchFlexTemplateParameter object with the job name, container spec GCS path, environment, and parameters.
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
    job_name=f"activation-pipeline-{activation_type.replace('_','-')}-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
    container_spec_gcs_path=template_file_gcs_location,
    environment=environment_param,
    parameters=parameters
  )

  # Creates a LaunchFlexTemplateRequest object with the project ID, region, and launch parameter.
  # It then uses the FlexTemplatesServiceClient to launch the Dataflow Flex Template.
  request = dataflow_v1beta3.LaunchFlexTemplateRequest(
    project_id=project_id,
    location=region,
    launch_parameter=flex_template_param
  )
  client = dataflow_v1beta3.FlexTemplatesServiceClient(client_info=ClientInfo(user_agent=USER_AGENT_ACTIVATION))
  response = client.launch_flex_template(request=request)

  print(response)
