# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import logging
import re
import traceback

from apache_beam.io.gcp.internal.clients import bigquery
from apache_beam.options.pipeline_options import GoogleCloudOptions
import apache_beam as beam

import json
import requests
import uuid
import datetime

from decimal import Decimal
from google.cloud import storage
from jinja2 import Environment, BaseLoader


class ActivationOptions(GoogleCloudOptions):
  """
  The ActivationOptions class inherits from the GoogleCloudOptions class, which provides a framework for defining 
  command-line arguments for Google Cloud applications.

  Define the command-line arguments for the activation application.
  The arguments are then used to configure the application and run the activation process.
  """

  @classmethod
  def _add_argparse_args(cls, parser):
    """
    Adds command-line arguments to the parser.

    Args:
      parser: The argparse parser.
    
    The following arguments are defined:
      source_table: The table specification for the source data in the format dataset.data_table.
      ga4_measurement_id: The Measurement ID in Google Analytics 4.
      ga4_api_secret: The client secret for sending data to Google Analytics 4.
      log_db_dataset: The dataset where the log table will be created.
      use_api_validation: A boolean flag indicating whether to use the Measurement Protocol API validation for debugging instead of sending the events.
      activation_type: The activation use case, which can be one of the following values:
        - audience-segmentation-15
        - auto-audience-segmentation-15
        - cltv-180-180
        - cltv-180-90
        - cltv-180-30
        - purchase-propensity-30-15
        - purchase-propensity-15-15
        - purchase-propensity-15-7
        - churn-propensity-30-15
      activation_type_configuration: The GCS path to the configuration file for all activation types.
    """

    parser.add_argument(
      '--source_table',
      type=str,
      help='table specification for the source data. Format [dataset.data_table]',
      required=True
    )
    parser.add_argument(
      '--ga4_measurement_id',
      type=str,
      help='Measurement ID in GA4',
      required=True
    )
    parser.add_argument(
      '--ga4_api_secret',
      type=str,
      help='Client secret for sending to GA4',
      required=True
    )
    parser.add_argument(
      '--log_db_dataset',
      type=str,
      help='dataset where log_table is created',
      required=True
    )
    parser.add_argument(
      '--use_api_validation',
      type=bool,
      help='Use Measurement Protocol API validation for debugging instead of sending the events',
      default=False,
      nargs='?'
    )
    parser.add_argument(
      '--activation_type',
      type=str,
      help='''
      Specifies the activation use case, currently supported values are:
        audience-segmentation-15
        auto-audience-segmentation-15
        cltv-180-180
        cltv-180-90
        cltv-180-30
        purchase-propensity-30-15
        purchase-propensity-15-15
        purchase-propensity-15-7
        churn-propensity-30-15
      ''',
      required=True
    )
    parser.add_argument(
      '--activation_type_configuration',
      type=str,
      help='GCS path to the configuration file all activation types',
      required=True
    )




def build_query(args, activation_type_configuration):
  """
  Builds the query to be used to retrieve data from the source table.

  Args:
    args: The command-line arguments.
    activation_type_configuration: The activation type configuration.

  Returns:
    The query to be used to retrieve data from the source table.
  """
  return activation_type_configuration['source_query_template'].render(
    source_table=args.source_table
  )




def gcs_read_file(project_id, gcs_path):
  """
  Reads a file from Google Cloud Storage (GCS).

  Args:
    project_id: The ID of the Google Cloud project that contains the GCS bucket.
    gcs_path: The path to the file in GCS, in the format "gs://bucket_name/object_name".

  Returns:
    The contents of the file as a string.

  Raises:
    ValueError: If the GCS path is invalid.
    IOError: If an error occurs while reading the file.
  """
  # Validate the GCS path.
  if not gcs_path.startswith("gs://"):
    raise ValueError("Invalid GCS path: {}".format(gcs_path))

  # Extract the bucket name and object name from the GCS path.
  matches = re.match("gs://(.*?)/(.*)", gcs_path)
  if not matches:
    raise ValueError("Invalid GCS path: {}".format(gcs_path))
  bucket_name, blob_name = matches.groups()

  # Create a storage client.
  storage_client = storage.Client(project=project_id)
  # Get a reference to the bucket and blob.
  bucket = storage_client.bucket(bucket_name)
  blob = bucket.blob(blob_name)
  # Open the blob for reading.
  with blob.open("r") as f:
    return f.read()




class CallMeasurementProtocolAPI(beam.DoFn):
  """
  This class defines a DoFn that sends events to the Google Analytics 4 Measurement Protocol API.

  The DoFn takes the following arguments:

  - measurement_id: The Measurement ID of the Google Analytics 4 property.
  - api_secret: The API secret for the Google Analytics 4 property.
  - debug: A boolean flag indicating whether to use the Measurement Protocol API validation for debugging instead of sending the events.

  The DoFn yields the following output:

  - The event that was sent.
  - The HTTP status code of the response.
  - The content of the response.
  """
  

  def __init__(self, measurement_id, api_secret, debug=False):
    """
    Initializes the DoFn.

    Args:
      measurement_id: The Measurement ID of the Google Analytics 4 property.
      api_secret: The API secret for the Google Analytics 4 property.
      debug: A boolean flag indicating whether to use the Measurement Protocol API validation for debugging instead of sending the events.
    """
    if debug:
      debug_str = "debug/"
    else:
      debug_str = ''
    self.event_post_url = f"https://www.google-analytics.com/{debug_str}mp/collect?measurement_id={measurement_id}&api_secret={api_secret}"


  def process(self, element):
    """
    Sends the event to the Measurement Protocol API.

    Args:
      element: The event to be sent.

    Yields:
      The event that was sent.
      The HTTP status code of the response.
      The content of the response.
    """
    response = requests.post(self.event_post_url, data=json.dumps(element),headers={'content-type': 'application/json'}, timeout=20)
    yield element, response.status_code, response.content




class ToLogFormat(beam.DoFn):
  """
  This class defines a DoFn that transforms the output of the Measurement Protocol API call into a format suitable for logging.

  The DoFn takes the following arguments:

  - element: A tuple containing the event that was sent and the HTTP status code of the response.

  The DoFn yields the following output:

  - A dictionary containing the following fields:
    - id: A unique identifier for the log entry.
    - activation_id: The ID of the activation event.
    - payload: The JSON payload of the event that was sent.
    - latest_state: The latest state of the event, which can be either "SEND_OK" or "SEND_FAIL".
    - updated_at: The timestamp when the log entry was created.
  """

  def process(self, element):
    """
    Transforms the output of the Measurement Protocol API call into a format suitable for logging.

    Args:
      element: A tuple containing the event that was sent and the HTTP status code of the response.

    Yields:
      A dictionary containing the following fields:
        - id: A unique identifier for the log entry.
        - activation_id: The ID of the activation event.
        - payload: The JSON payload of the event that was sent.
        - latest_state: The latest state of the event, which can be either "SEND_OK" or "SEND_FAIL".
        - updated_at: The timestamp when the log entry was created.
    """
    time_cast = datetime.datetime.now(tz=datetime.timezone.utc)

    if element[1] == requests.status_codes.codes.NO_CONTENT:
      state_msg = 'SEND_OK'
    else:
      state_msg = 'SEND_FAIL'

    result = {}
    try:
      result = {
        'id': str(uuid.uuid4()),
        'activation_id': element[0]['events'][0]['name'],
        'payload': json.dumps(element[0]),
        'latest_state': f"{state_msg} {element[1]}",
        'updated_at': str(time_cast)
      }
    except KeyError as e:
      logging.error(element)
      result = {
        'id': str(uuid.uuid4()),
        'activation_id': "",
        'payload': json.dumps(element[0]),
        'latest_state': f"{state_msg} {element[1]}",
        'updated_at': str(time_cast)
      }
      logging.error(traceback.format_exc())
    yield result




class DecimalEncoder(json.JSONEncoder):
  """
  This class defines a custom JSON encoder that handles Decimal objects correctly.

  The DecimalEncoder class inherits from the `json.JSONEncoder` class and overrides the `default` method to handle Decimal objects. 
  The `default` method is called for objects that are not of a basic type (string, number, boolean, None, list, tuple, dictionary). 
  The DecimalEncoder class checks if the object is a Decimal object and, if so, returns its value as a float. 
  Otherwise, it calls the parent class's `default` method to handle the object.

  The DecimalEncoder class is used to ensure that Decimal objects are encoded as floats when they are converted to JSON. 
  This is important because Decimal objects cannot be directly encoded as JSON strings.
  """

  def default(self, obj):
    """
    Handles the encoding of Decimal objects.

    Args:
      obj: The object to be encoded.

    Returns:
      The JSON representation of the object.
    """
    if isinstance(obj, Decimal):
      return float(obj)
    return json.JSONEncoder.default(self, obj)




class TransformToPayload(beam.DoFn):
  """
  This class defines a DoFn that transforms the output of the inference pipeline into a format suitable for sending to the Google Analytics 4 Measurement Protocol API.

  The DoFn takes the following arguments:

  - template_str: The Jinja2 template string used to generate the Measurement Protocol payload.
  - event_name: The name of the event to be sent to Google Analytics 4.

  The DoFn yields the following output:

  - A dictionary containing the Measurement Protocol payload.

  The DoFn performs the following steps:

  1. Removes bad shaping strings in the `client_id` field.
  2. Renders the Jinja2 template string using the provided data and event name.
  3. Converts the rendered template string into a JSON object.
  4. Handles any JSON decoding errors.

  The DoFn is used to ensure that the Measurement Protocol payload is formatted correctly before being sent to Google Analytics 4.
  """
  def __init__(self, template_str, event_name):
    """
    Initializes the DoFn.

    Args:
      template_str: The Jinja2 template string used to generate the Measurement Protocol payload.
      event_name: The name of the event to be sent to Google Analytics 4.
    """
    self.template_str = template_str
    self.date_format = "%Y-%m-%d"
    self.date_time_format = "%Y-%m-%d %H:%M:%S.%f %Z"
    self.event_name = event_name


  def setup(self):
    """
    Sets up the Jinja2 environment.
    """
    self.payload_template = Environment(loader=BaseLoader).from_string(self.template_str)


  def process(self, element):
    """
    Transforms the output of the inference pipeline into a format suitable for sending to the Google Analytics 4 Measurement Protocol API.

    Args:
      element: A dictionary containing the output of the inference pipeline.

    Yields:
      A dictionary containing the Measurement Protocol payload.
    """
    # Removing bad shaping strings in client_id
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20007)', '')
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20023)', '')
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20013)', '')
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20010)', '')
    _client_id = element['client_id'].replace(r'q="><script>_exploit_dom_xss(40007)</script>', '')
    _client_id = element['client_id'].replace(r'q="><script>_exploit_dom_xss(40013)</script>', '')
    
    payload_str = self.payload_template.render(
      client_id=_client_id,
      user_id=self.generate_user_id_key_value_pair(element),
      event_timestamp=self.date_to_micro(element["inference_date"]),
      event_name=self.event_name,
      session_id=element['session_id'],
      user_properties=self.generate_user_properties(element),
    )
    result = {}
    try:
      result = json.loads(r'{}'.format(payload_str))
    except json.decoder.JSONDecodeError as e:
      logging.error(payload_str)
      logging.error(traceback.format_exc())
    yield result
    

  def date_to_micro(self, date_str):
    """
    Converts a date string to a microsecond timestamp.

    Args:
      date_str: The date string to be converted.

    Returns:
      The microsecond timestamp.
    """
    try:  # try if date_str with date time format
      return int(datetime.datetime.strptime(date_str, self.date_time_format).timestamp() * 1E6)

    except Exception as e:
      return int(datetime.datetime.strptime(date_str, self.date_format).timestamp() * 1E6)


  def generate_param_fields(self, element):
    """
    Generates a JSON string containing the parameter fields of the element.

    Args:
      element: The element to be processed.

    Returns:
      A JSON string containing the parameter fields of the element.
    """
    element_copy = element.copy()
    del element_copy['client_id']
    del element_copy['user_id']
    del element_copy['session_id']
    del element_copy['inference_date']
    element_copy = {k: v for k, v in element_copy.items() if v}
    return json.dumps(element_copy, cls=DecimalEncoder)


  def generate_user_properties(self, element):
    """
    Generates a JSON string containing the user properties of the element.

    Args:
      element: The element to be processed.

    Returns:
      A JSON string containing the user properties of the element.
    """
    element_copy = element.copy()
    del element_copy['client_id']
    del element_copy['user_id']
    del element_copy['session_id']
    del element_copy['inference_date']
    user_properties_obj =  {}
    for k, v in element_copy.items():
      if v:
        user_properties_obj[k] = {'value': str(v)}
    return json.dumps(user_properties_obj, cls=DecimalEncoder)
  

  def generate_user_id_key_value_pair(self, element):
    """
    If the user_id field is not empty generate the key/value string with the user_id.
    else return empty string
    Args:
      element: The element to be processed.

    Returns:
      A string containing the key and value with the user_id.
    """
    user_id = element['user_id']
    if user_id:
      return f'"user_id": "{user_id}",'
    return ""





def send_success(element):
  """
  Checks if the Measurement Protocol API call was successful.

  Args:
    element: A tuple containing the event that was sent and the HTTP status code of the response.

  Returns:
    True if the Measurement Protocol API call was successful, False otherwise.
  """
  return element[1] == requests.status_codes.codes.NO_CONTENT




def load_activation_type_configuration(args):
  """
  Loads the activation type configuration from Google Cloud Storage (GCS).

  Args:
    args: The command-line arguments.

  Returns:
    A dictionary containing the activation type configuration.

  Raises:
    ValueError: If the GCS path is invalid.
    IOError: If an error occurs while reading the file.
  """
  # Read the configuration file from GCS.
  config_str = gcs_read_file(args.project, args.activation_type_configuration)
  # Parse the JSON configuration file.
  grand_config = json.loads(config_str)

  # Get the activation type configuration.
  activation_config = grand_config[args.activation_type]

  # Create the activation type configuration dictionary.
  configuration = {
    'activation_event_name': activation_config['activation_event_name'],
    'source_query_template': Environment(loader=BaseLoader).from_string(gcs_read_file(args.project, activation_config['source_query_template']).replace('\n', ' ')),
    'measurement_protocol_payload_template': gcs_read_file(args.project, activation_config['measurement_protocol_payload_template'])
  }

  return configuration




def run(argv=None):
  """
  Runs the activation application.

  Args:
    argv: The command-line arguments.
  """
  # Create the pipeline options.
  pipeline_options = GoogleCloudOptions(
    job_name="activation-processing",
    save_main_session=True)

  # Get the activation options.
  activation_options = pipeline_options.view_as(ActivationOptions)
  # Load the activation type configuration.
  logging.info(f"Loading activation type configuration from {activation_options}")
  activation_type_configuration = load_activation_type_configuration(activation_options)

  # Build the query to be used to retrieve data from the source table.
  logging.info(f"Building query to retrieve data from {activation_type_configuration}")
  load_from_source_query = build_query(activation_options, activation_type_configuration)
  logging.info(load_from_source_query)

  # Create a unique table suffix for the log tables.
  table_suffix =f"{datetime.datetime.today().strftime('%Y_%m_%d')}_{str(uuid.uuid4())[:8]}"
  # Create the log table names.
  log_table_names = [f'activation_log_{table_suffix}', f'activation_retry_{table_suffix}']
  # Create the log table schema.
  table_schema = {
    'fields': [{
      'name': 'id', 'type': 'STRING', 'mode': 'REQUIRED'
      }, {
      'name': 'activation_id', 'type': 'STRING', 'mode': 'REQUIRED'
      }, {
      'name': 'payload', 'type': 'STRING', 'mode': 'REQUIRED'
      }, {
      'name': 'latest_state', 'type': 'STRING', 'mode': 'REQUIRED'
      }, {
      'name': 'updated_at', 'type': 'TIMESTAMP', 'mode': 'REQUIRED'
    }]
  }

  # Create the BigQuery table references for the log tables.
  success_log_table_spec = bigquery.TableReference(
    projectId=activation_options.project,
    datasetId=activation_options.log_db_dataset,
    tableId=log_table_names[0])

  failure_log_table_spec = bigquery.TableReference(
    projectId=activation_options.project,
    datasetId=activation_options.log_db_dataset,
    tableId=log_table_names[1])

  # Create the pipeline.
  with beam.Pipeline(options=pipeline_options) as p:
    # Read the data from the source table.
    measurement_api_responses = (p
    | beam.io.gcp.bigquery.ReadFromBigQuery(project=activation_options.project,
        query=load_from_source_query,
        use_json_exports=True,
        use_standard_sql=True)
    | 'Prepare Measurement Protocol API payload' >> beam.ParDo(TransformToPayload(activation_type_configuration['measurement_protocol_payload_template'], activation_type_configuration['activation_event_name']))
    | 'POST event to Measurement Protocol API' >> beam.ParDo(CallMeasurementProtocolAPI(activation_options.ga4_measurement_id, activation_options.ga4_api_secret, debug=activation_options.use_api_validation))
    )

    # Filter the successful responses
    success_responses = ( measurement_api_responses
    | 'Get the successful responses' >> beam.Filter(lambda element: element[1] == requests.status_codes.codes.NO_CONTENT)
    )

    # Filter the failed responses
    failed_responses = ( measurement_api_responses
    | 'Get the failed responses' >> beam.Filter(lambda element: element[1] != requests.status_codes.codes.NO_CONTENT)
    )

    # Store the successful responses in the log tables
    _ = ( success_responses
    | 'Transform log format' >> beam.ParDo(ToLogFormat())
    | 'Store to log BQ table' >> beam.io.WriteToBigQuery(
      success_log_table_spec,
      schema=table_schema,
      write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
      create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED)
    )

    # Store the failed responses in the log tables
    _ = ( failed_responses
    | 'Transform failure log format' >> beam.ParDo(ToLogFormat())
    | 'Store to failure log BQ table' >> beam.io.WriteToBigQuery(
      failure_log_table_spec,
      schema=table_schema,
      write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
      create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED)
    )




if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()
