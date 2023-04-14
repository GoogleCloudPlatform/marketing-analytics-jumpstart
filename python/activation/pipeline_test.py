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

import unittest
import apache_beam as beam
from unittest.mock import MagicMock, patch
from apache_beam.testing.test_pipeline import TestPipeline
from apache_beam.testing.util import assert_that, equal_to


from main import TransformToPayload, build_query, gcs_read_file
from decimal import Decimal
from jinja2 import Environment, BaseLoader

class data:
  def __init__(self, **kwargs):
    self.__dict__.update(kwargs)

class CountTest(unittest.TestCase):

  def test_transform_to_payload(self):
    template_str = '''
    {
      "client_id": "{{client_id}}",
      "timestamp_micros": {{event_timestamp}},
      "nonPersonalizedAds": false,
      "events": [{
        "name": "{{event_name}}",
        "params": {{param_fields}}
        }
      ]}
    '''

    INPUT = [{
      'client_id':'client-id-value-test',
      'inference_date':'2023-02-25',
      'string_field':'string value',
      'int_field':42,
      'bool_field':True,
      'null_field': None,
      'decimal_field': Decimal(22.4)
    }]

    with TestPipeline() as p:
      input = p | beam.Create(INPUT)
      output = input | beam.ParDo(TransformToPayload(
        template_str, "test_activation_name"))

      assert_that(
        output,
        equal_to([
          {
            "client_id": "client-id-value-test",
            "timestamp_micros": 1677283200000000,
            "nonPersonalizedAds": False,
            "events": [
              {
                "name": "test_activation_name",
                "params": {
                  'string_field':'string value',
                  'int_field':42,
                  'bool_field':True,
                  'decimal_field': 22.4,
                }
              }
            ]
          }
        ])
      )

  def test_build_source_query(self):
    query_template_string = 'SELECT * FROM {{source_table}}'

    parameter_input = data(source_table='test_dataset.test_table')

    configuration = {
      'source_query_template': Environment(loader=BaseLoader).from_string(query_template_string)
    }

    source_data_query = build_query(parameter_input, configuration)

    self.assertEqual(
      source_data_query,
      'SELECT * FROM test_dataset.test_table'
    )

  @patch('google.cloud.storage.Client')
  def test_gcs_read_file(self, mock_storage):
    mock_client = MagicMock()
    mock_bucket = MagicMock()
    mock_storage.return_value = mock_client
    mock_client.bucket.return_value = mock_bucket

    gcs_read_file('test_project', 'gs://test-bucket/test-file')

    mock_storage.assert_called_with(project='test_project')
    mock_client.bucket.assert_called_with('test-bucket')
    mock_bucket.blob.assert_called_with('test-file')

if __name__ == '__main__':
  unittest.main()
