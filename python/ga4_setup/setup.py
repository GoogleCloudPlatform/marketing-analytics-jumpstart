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


import json
from google.analytics import admin_v1alpha
from google.analytics.admin import AnalyticsAdminServiceClient


def get_data_stream(property_id: str, stream_id: str, transport: str = None):
  client = AnalyticsAdminServiceClient(transport=transport)
  return client.get_data_stream(
    name=f"properties/{property_id}/dataStreams/{stream_id}"
  )


def get_measurement_protocol_secret_value(configuration: map, secret_display_name: str, transport: str = None):
  client = AnalyticsAdminServiceClient(transport=transport)
  results = client.list_measurement_protocol_secrets(
    parent=f"properties/{configuration['property_id']}/dataStreams/{configuration['stream_id']}"
  )
  for measurement_protocol_secret in results:
    if measurement_protocol_secret.display_name == secret_display_name:
      return measurement_protocol_secret.secret_value
  return None


def get_measurement_protocol_secret(configuration: map, secret_display_name: str):
  measurement_protocol_secret = get_measurement_protocol_secret_value(
    configuration, secret_display_name)
  if measurement_protocol_secret:
    return measurement_protocol_secret
  else:
    create_measurement_protocol_secret(configuration, secret_display_name)


def get_measurement_id(configuration: map):
  return get_data_stream(configuration['property_id'], configuration['stream_id']).web_stream_data.measurement_id


def create_measurement_protocol_secret(configuration: map, secret_display_name: str, transport: str = None):
  from google.analytics.admin_v1alpha import MeasurementProtocolSecret
  client = AnalyticsAdminServiceClient(transport=transport)
  measurement_protocol_secret = client.create_measurement_protocol_secret(
    parent=f"properties/{configuration['property_id']}/dataStreams/{configuration['stream_id']}",
    measurement_protocol_secret=MeasurementProtocolSecret(
      display_name=secret_display_name
    ),
  )
  return measurement_protocol_secret.secret_value


def load_event_names():
  fo = open('../../templates/activation_type_configuration_template.tpl')
  activation_types_obj = json.load(fo)
  event_names = []
  for k in activation_types_obj:
    event_names.append(activation_types_obj[k]['activation_event_name'])
  return event_names


def create_custom_events(configuration: map):
  event_names = load_event_names()
  existing_event_names = load_existing_ga4_custom_events(configuration)
  for event_name in event_names:
    if not event_name in existing_event_names:
      create_custom_event(configuration, event_name)
      print(f"Create customer event with name: {event_name}")


def load_custom_dimensions(query_file: str):
  reserved_words = ['select', 'extract', 'from', 'where', 'and', 'order', 'limit']
  ret_fields = []
  with open(query_file, "r") as f:
    lines = f.readlines()
  for line in lines:
    line = line.lower().lstrip()
    for word in reserved_words:
      if line.startswith(word):
        break
    else:
      fields = line.split(',')
      column_rename_key_word = ' as '
      for field in fields:
        field = field.strip()
        if column_rename_key_word in field:
          field_split = field.split(column_rename_key_word)
          field = field_split[1]
        if field:
          ret_fields.append(field)
  return ret_fields


def load_existing_ga4_custom_events(configuration: map):
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  request = admin_v1alpha.ListEventCreateRulesRequest(
    parent=f"properties/{configuration['property_id']}/dataStreams/{configuration['stream_id']}",
  )
  response = client.list_event_create_rules(request=request)
  existing_event_rules = []
  for page in response.pages:
    for event_rule_obj in page.event_create_rules:
      existing_event_rules.append(event_rule_obj.destination_event)

  return existing_event_rules


def create_custom_event(configuration: map, event_name: str):
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  event_create_rule = admin_v1alpha.EventCreateRule()
  condition = admin_v1alpha.MatchingCondition()

  condition.field = "event_name"
  condition.comparison_type = "EQUALS"
  condition.value = event_name

  event_create_rule.destination_event = event_name
  event_create_rule.event_conditions.append(condition)

  request = admin_v1alpha.CreateEventCreateRuleRequest(
    parent=f"properties/{configuration['property_id']}/dataStreams/{configuration['stream_id']}",
    event_create_rule=event_create_rule,
  )

  response = client.create_event_create_rule(request=request)


def create_custom_dimensions(configuration: map):
  existing_dimensions = load_existing_ga4_custom_dimensions(configuration)
  fields = load_custom_dimensions(
    '../../sql/query/audience_segmentation_query_template.sqlx')
  use_case = 'Audience Segmentation'
  for field in fields:
    display_name = f'MDE {use_case} {field}'
    if not display_name in existing_dimensions:
      create_custom_dimension(configuration, field, display_name)
      print(f'need to create custom dimension: {display_name}')


def create_custom_dimension(configuration: map, field_name: str, display_name: str):
  client = admin_v1alpha.AnalyticsAdminServiceClient()

  custom_dimension = admin_v1alpha.CustomDimension()
  custom_dimension.parameter_name = field_name
  custom_dimension.display_name = display_name
  custom_dimension.scope = "USER"

  request = admin_v1alpha.CreateCustomDimensionRequest(
    parent=f"properties/{configuration['property_id']}",
    custom_dimension=custom_dimension,
  )

  client.create_custom_dimension(request=request)


def load_existing_ga4_custom_dimensions(configuration: map):
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  request = admin_v1alpha.ListCustomDimensionsRequest(
    parent=f"properties/{configuration['property_id']}",
  )
  page_result = client.list_custom_dimensions(request=request)
  existing_custom_dimensions = []
  for page in page_result.pages:
    for custom_dimension in page.custom_dimensions:
      existing_custom_dimensions.append(custom_dimension.display_name)
  return existing_custom_dimensions


if __name__ == "__main__":
  '''
  Following Google API scopes are required to call Google Analytics Admin API:
  https://www.googleapis.com/auth/analytics
  https://www.googleapis.com/auth/analytics.edit
  https://www.googleapis.com/auth/analytics.manage.users
  https://www.googleapis.com/auth/analytics.manage.users.readonly
  https://www.googleapis.com/auth/analytics.provision
  https://www.googleapis.com/auth/analytics.readonly
  https://www.googleapis.com/auth/analytics.user.deletion
  '''

  import os
  import argparse

  parser = argparse.ArgumentParser()
  parser.add_argument('--ga4_resource', type=str, required=True)
  args = parser.parse_args()

  configuration = {
    'property_id': os.getenv('GA4_PROPERTY_ID'),
    'stream_id': os.getenv('GA4_STREAM_ID')
  }

  # python setup.py --ga4_resource=measurement_properties
  if args.ga4_resource == "measurement_properties":
    secret_display_name = 'MDE Activation'
    properties = {
      'measurement_id': get_measurement_id(configuration),
      'measurement_secret': get_measurement_protocol_secret(configuration, secret_display_name)
    }
    print(json.dumps(properties))

  # python setup.py --ga4_resource=custom_events
  if args.ga4_resource == "custom_events":
    create_custom_events(configuration)

  # python setup.py --ga4_resource=custom_dimensions
  if args.ga4_resource == "custom_dimensions":
    create_custom_dimensions(configuration)
