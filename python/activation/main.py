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
  @classmethod
  def _add_argparse_args(cls, parser):
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
      cltv-180-180
      cltv-180-90
      cltv-180-30
      purchase-propensity-30-15
      purchase-propensity-15-15
      purchase-propensity-15-7
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
  return activation_type_configuration['source_query_template'].render(
    source_table=args.source_table
  )

def gcs_read_file(project_id, gcs_path):
  matches = re.match("gs://(.*?)/(.*)", gcs_path)
  bucket_name, blob_name = matches.groups()

  storage_client = storage.Client(project=project_id)
  bucket = storage_client.bucket(bucket_name)
  blob = bucket.blob(blob_name)
  with blob.open("r") as f:
    return f.read()

class CallMeasurementProtocolAPI(beam.DoFn):
  def __init__(self, measurement_id, api_secret, debug=False):
    if debug:
      debug_str = "debug/"
    else:
      debug_str = ''
    self.event_post_url = f"https://www.google-analytics.com/{debug_str}mp/collect?measurement_id={measurement_id}&api_secret={api_secret}"

  def process(self, element):
    response = requests.post(self.event_post_url, data=json.dumps(element),headers={'content-type': 'application/json'}, timeout=20)
    yield element, response.status_code, response.content

class ToLogFormat(beam.DoFn):
  def process(self, element):
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
  def default(self, obj):
    if isinstance(obj, Decimal):
      return float(obj)
    return json.JSONEncoder.default(self, obj)

class TransformToPayload(beam.DoFn):
  def __init__(self, template_str, event_name):
    self.template_str = template_str
    self.date_format = "%Y-%m-%d"
    self.event_name = event_name

  def setup(self):
    self.payload_template = Environment(loader=BaseLoader).from_string(self.template_str)

  def process(self, element):
    # Removing bad shaping strings in client_id
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20007)', '')
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20023)', '')
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20013)', '')
    _client_id = element['client_id'].replace(r'<img onerror="_exploit_dom_xss(20010)', '')
    _client_id = element['client_id'].replace(r'q="><script>_exploit_dom_xss(40007)</script>', '')
    _client_id = element['client_id'].replace(r'q="><script>_exploit_dom_xss(40013)</script>', '')
    
    payload_str = self.payload_template.render(
      client_id=_client_id,
      event_timestamp=self.date_to_micro(element["inference_date"]),
      event_name=self.event_name,
      user_properties=self.generate_user_properties(element),
      event_parameters=self.generate_event_parameters(element),
    )
    result = {}
    try:
      result = json.loads(r'{}'.format(payload_str))
    except json.decoder.JSONDecodeError as e:
      logging.error(payload_str)
      logging.error(traceback.format_exc())
    yield result
    

  def date_to_micro(self, date_str):
    try:  # try if date_str is in ISO timestamp format
      return int(datetime.datetime.fromisoformat(date_str).timestamp() * 1E6)

    except Exception as e:
      return int(datetime.datetime.strptime(date_str, self.date_format).timestamp() * 1E6)

  def generate_param_fields(self, element):
    element_copy = element.copy()
    del element_copy['client_id']
    del element_copy['inference_date']
    element_copy = {k: v for k, v in element_copy.items() if v}
    return json.dumps(element_copy, cls=DecimalEncoder)

  def generate_user_properties(self, element):
    element_copy = element.copy()
    del element_copy['client_id']
    del element_copy['inference_date']
    user_properties_obj =  {}
    for k, v in element_copy.items():
      if v:
        user_properties_obj[k] = {'value': v}
    return json.dumps(user_properties_obj, cls=DecimalEncoder)
  
  def generate_event_parameters(self, element):
    element_copy = element.copy()
    del element_copy['client_id']
    del element_copy['inference_date']
    event_parameters_obj =  {}
    for k, v in element_copy.items():
      if v:
        event_parameters_obj[k] = v
    return json.dumps(event_parameters_obj, cls=DecimalEncoder)

def send_success(element):
  return element[1] == requests.status_codes.codes.NO_CONTENT

def load_activation_type_configuration(args):
  config_str = gcs_read_file(args.project, args.activation_type_configuration)
  grand_config = json.loads(config_str)
  activation_config = grand_config[args.activation_type]
  configuration = {
    'activation_event_name': activation_config['activation_event_name'],
    'source_query_template': Environment(loader=BaseLoader).from_string(gcs_read_file(args.project, activation_config['source_query_template']).replace('\n', '')),
    'measurement_protocol_payload_template': gcs_read_file(args.project, activation_config['measurement_protocol_payload_template'])
  }
  return configuration

def run(argv=None):
  pipeline_options = GoogleCloudOptions(
    job_name="activation-processing",
    save_main_session=True)

  activation_options = pipeline_options.view_as(ActivationOptions)

  activation_type_configuration = load_activation_type_configuration(activation_options)

  load_from_source_query = build_query(activation_options, activation_type_configuration)
  logging.info(load_from_source_query)

  table_suffix =f"{datetime.datetime.today().strftime('%Y_%m_%d')}_{str(uuid.uuid4())[:8]}"
  log_table_names = [f'activation_log_{table_suffix}', f'activation_retry_{table_suffix}']
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

  success_log_table_spec = bigquery.TableReference(
    projectId=activation_options.project,
    datasetId=activation_options.log_db_dataset,
    tableId=log_table_names[0])

  failure_log_table_spec = bigquery.TableReference(
    projectId=activation_options.project,
    datasetId=activation_options.log_db_dataset,
    tableId=log_table_names[1])

  with beam.Pipeline(options=pipeline_options) as p:
    measurement_api_responses = (p
    | beam.io.gcp.bigquery.ReadFromBigQuery(project=activation_options.project,
        query=load_from_source_query,
        use_json_exports=True,
        use_standard_sql=True)
    | 'Prepare Measurement Protocol API payload' >> beam.ParDo(TransformToPayload(activation_type_configuration['measurement_protocol_payload_template'], activation_type_configuration['activation_event_name']))
    | 'POST event to Measurement Protocol API' >> beam.ParDo(CallMeasurementProtocolAPI(activation_options.ga4_measurement_id, activation_options.ga4_api_secret, debug=activation_options.use_api_validation))
    )

    success_responses = ( measurement_api_responses
    | 'Get the successful responses' >> beam.Filter(lambda element: element[1] == requests.status_codes.codes.NO_CONTENT)
    )

    failed_responses = ( measurement_api_responses
    | 'Get the failed responses' >> beam.Filter(lambda element: element[1] != requests.status_codes.codes.NO_CONTENT)
    )

    _ = ( success_responses
    | 'Transform log format' >> beam.ParDo(ToLogFormat())
    | 'Store to log BQ table' >> beam.io.WriteToBigQuery(
      success_log_table_spec,
      schema=table_schema,
      write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
      create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED)
    )

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
