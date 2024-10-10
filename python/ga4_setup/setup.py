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
from typing import List




def get_data_stream(property_id: str, stream_id: str, transport: str = None):
  """
  Retrieves a data stream from Google Analytics 4.

  Args:
    property_id: The ID of the Google Analytics 4 property.
    stream_id: The ID of the data stream.
    transport: The transport to use for the request. Defaults to None.

  Returns:
    A DataStream object.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the data stream.
  """
  client = AnalyticsAdminServiceClient(transport=transport)
  return client.get_data_stream(
    name=f"properties/{property_id}/dataStreams/{stream_id}"
  )




def get_measurement_protocol_secret_value(configuration: map, secret_display_name: str, transport: str = None):
  """
  Retrieves the secret value for a given measurement protocol secret display name.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.
    secret_display_name: The display name of the measurement protocol secret.
    transport: The transport to use for the request. Defaults to None.

  Returns:
    The secret value for the measurement protocol secret, or None if the secret is not found.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the measurement protocol secret.
  """
  client = AnalyticsAdminServiceClient(transport=transport)
  results = client.list_measurement_protocol_secrets(
    parent=f"properties/{configuration['property_id']}/dataStreams/{configuration['stream_id']}"
  )
  for measurement_protocol_secret in results:
    if measurement_protocol_secret.display_name == secret_display_name:
      return measurement_protocol_secret.secret_value
  return None




def get_measurement_protocol_secret(configuration: map, secret_display_name: str):
  """
  Retrieves the secret value for a given measurement protocol secret display name.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.
    secret_display_name: The display name of the measurement protocol secret.

  Returns:
    The secret value for the measurement protocol secret, or None if the secret is not found.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the measurement protocol secret.
  """
  measurement_protocol_secret = get_measurement_protocol_secret_value(
    configuration, secret_display_name)
  if measurement_protocol_secret:
    return measurement_protocol_secret
  else:
    return create_measurement_protocol_secret(configuration, secret_display_name)




def get_measurement_id(configuration: map):
  """
  Retrieves the measurement ID for a given Google Analytics 4 property and data stream.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.

  Returns:
    The measurement ID for the given property and data stream.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the measurement ID.
  """
  return get_data_stream(configuration['property_id'], configuration['stream_id']).web_stream_data.measurement_id

def get_property(configuration: map, transport: str = None):
  client = AnalyticsAdminServiceClient(transport=transport)
  return client.get_property(
    name=f"properties/{configuration['property_id']}"
  )



def create_measurement_protocol_secret(configuration: map, secret_display_name: str, transport: str = None):
  """
  Creates a new measurement protocol secret for a given Google Analytics 4 property and data stream.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.
    secret_display_name: The display name of the measurement protocol secret.
    transport: The transport to use for the request. Defaults to None.

  Returns:
    The secret value for the measurement protocol secret.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while creating the measurement protocol secret.
  """
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
  """
  Loads the event names from the activation type configuration template file.

  Returns:
    A list of event names.
  """
  fo = open('templates/activation_type_configuration_template.tpl')
  activation_types_obj = json.load(fo)
  event_names = []
  for k in activation_types_obj:
    event_names.append(activation_types_obj[k]['activation_event_name'])
  return event_names




def create_custom_events(configuration: map):
  """
  Creates custom events in Google Analytics 4 based on the event names defined in the activation type configuration template file.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while creating the custom events.
  """
  event_names = load_event_names()
  existing_event_names = load_existing_ga4_custom_events(configuration)
  for event_name in event_names:
    if not event_name in existing_event_names:
      print(f"Create custom event with name: {event_name}")
      create_custom_event(configuration, event_name)




def load_existing_ga4_custom_events(configuration: map):
  """
  Loads the existing custom events from Google Analytics 4 based on the provided configuration.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.

  Returns:
    A list of existing custom event names.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the custom events.
  """
  response = load_existing_ga4_custom_event_objs(configuration)
  existing_event_rules = []
  for page in response.pages:
    for event_rule_obj in page.event_create_rules:
      existing_event_rules.append(event_rule_obj.destination_event)
  return existing_event_rules




def load_existing_ga4_custom_event_objs(configuration: map):
  """
  Loads the existing custom event objects from Google Analytics 4 based on the provided configuration.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.

  Returns:
    A ListEventCreateRulesResponse object containing the existing custom event objects.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the custom events.
  """
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  request = admin_v1alpha.ListEventCreateRulesRequest(
    parent=f"properties/{configuration['property_id']}/dataStreams/{configuration['stream_id']}",
  )
  return client.list_event_create_rules(request=request)




def create_custom_event(configuration: map, event_name: str):
  """
  Creates a custom event in Google Analytics 4 based on the provided event name.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.
    event_name: The name of the custom event to be created.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while creating the custom event.
  """
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
  """
  Creates custom dimensions in Google Analytics 4 based on the provided configuration.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while creating the custom dimensions.
  """
  existing_dimensions = load_existing_ga4_custom_dimensions(configuration)
  create_custom_dimensions_for('Audience Segmentation', ['a_s_prediction'], existing_dimensions, configuration)
  create_custom_dimensions_for('Purchase Propensity', ['p_p_prediction', 'p_p_decile'], existing_dimensions, configuration)
  create_custom_dimensions_for('CLTV', ['cltv_decile'], existing_dimensions, configuration)
  create_custom_dimensions_for('Auto Audience Segmentation', ['a_a_s_prediction'], existing_dimensions, configuration)
  create_custom_dimensions_for('Churn Propensity', ['c_p_prediction', 'c_p_decile'], existing_dimensions, configuration)




def create_custom_dimensions_for(use_case: str, fields: List[str], existing_dimensions: List[str], configuration: map):
  """
  Creates custom dimensions in Google Analytics 4 based on the provided configuration for a specific use case.

  Args:
    use_case: The use case for which the custom dimensions are being created.
    fields: A list of field names to be used as custom dimensions.
    existing_dimensions: A list of existing custom dimension names.
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while creating the custom dimensions.
  """
  for field in fields:
    display_name = f'MAJ {use_case} {field}'
    if not display_name in existing_dimensions:
      print(f'Create custom dimension: {display_name}')
      create_custom_dimension(configuration, field, display_name)




def create_custom_dimension(configuration: map, field_name: str, display_name: str):
  """
  Creates a custom dimension in Google Analytics 4 based on the provided configuration.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID.
    field_name: The name of the field to be used as the custom dimension.
    display_name: The display name of the custom dimension.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while creating the custom dimension.
  """
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




def load_existing_ga4_custom_dimension_objs(configuration: map):
  """
  Loads the existing custom dimension objects from Google Analytics 4 based on the provided configuration.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID.

  Returns:
    A ListCustomDimensionsResponse object containing the existing custom dimension objects.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the custom dimensions.
  """
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  request = admin_v1alpha.ListCustomDimensionsRequest(
    parent=f"properties/{configuration['property_id']}",
  )
  return client.list_custom_dimensions(request=request)




def load_existing_ga4_custom_dimensions(configuration: map):
  """
  Loads the existing custom dimension objects from Google Analytics 4 based on the provided configuration.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID.

  Returns:
    A list of existing custom dimension names.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while retrieving the custom dimensions.
  """
  page_result = load_existing_ga4_custom_dimension_objs(configuration)
  existing_custom_dimensions = []
  for page in page_result.pages:
    for custom_dimension in page.custom_dimensions:
      existing_custom_dimensions.append(custom_dimension.display_name)
  return existing_custom_dimensions




def update_custom_event_with_new_prefix(event_create_rule, old_prefix, new_prefix):
  """
  Updates an existing custom event in Google Analytics 4 with a new prefix.

  Args:
    event_create_rule: The custom event rule to be updated.
    old_prefix: The old prefix to be replaced.
    new_prefix: The new prefix to be used.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while updating the custom event.
  """
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  event_create_rule.destination_event = event_create_rule.destination_event.replace(old_prefix, new_prefix)
  event_create_rule.event_conditions[0].value = event_create_rule.event_conditions[0].value.replace(old_prefix, new_prefix)
  request = admin_v1alpha.UpdateEventCreateRuleRequest(
    event_create_rule=event_create_rule,
    update_mask="destinationEvent,eventConditions"
  )
  client.update_event_create_rule(request=request)




def rename_existing_ga4_custom_events(configuration: map, old_prefix, new_prefix):
  """
  Renames existing custom events in Google Analytics 4 by replacing the old prefix with the new prefix.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID and data stream ID.
    old_prefix: The old prefix to be replaced.
    new_prefix: The new prefix to be used.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while renaming the custom events.
  """
  existing_event_rules = load_existing_ga4_custom_event_objs(configuration)
  for page in existing_event_rules.pages:
    for create_event_rule in page.event_create_rules:
      if create_event_rule.destination_event.startswith(old_prefix):
        update_custom_event_with_new_prefix(create_event_rule, old_prefix, new_prefix)




def update_custom_dimension_with_new_prefix(custom_dimension, old_prefix, new_prefix):
  """
  Updates an existing custom dimension in Google Analytics 4 with a new prefix.

  Args:
    custom_dimension: The custom dimension to be updated.
    old_prefix: The old prefix to be replaced.
    new_prefix: The new prefix to be used.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while updating the custom dimension.
  """
  client = admin_v1alpha.AnalyticsAdminServiceClient()
  custom_dimension.display_name = custom_dimension.display_name.replace(old_prefix, new_prefix)
  request = admin_v1alpha.UpdateCustomDimensionRequest(
    custom_dimension=custom_dimension,
    update_mask="displayName"
  )
  client.update_custom_dimension(request=request)




def rename_existing_ga4_custom_dimensions(configuration: map, old_prefix, new_prefix):
  """
  Renames existing custom dimensions in Google Analytics 4 by replacing the old prefix with the new prefix.

  Args:
    configuration: A dictionary containing the Google Analytics 4 property ID.
    old_prefix: The old prefix to be replaced.
    new_prefix: The new prefix to be used.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while renaming the custom dimensions.
  """
  page_result = load_existing_ga4_custom_dimension_objs(configuration)
  for page in page_result.pages:
    for custom_dimension in page.custom_dimensions:
      if custom_dimension.display_name.startswith(old_prefix):
        update_custom_dimension_with_new_prefix(custom_dimension, old_prefix, new_prefix)




def entry():
  """
  This function is the entry point for the setup script. It takes three arguments:

  Args:
    ga4_resource: The Google Analytics 4 resource to be configured.
    ga4_property_id: The Google Analytics 4 property ID.
    ga4_stream_id: The Google Analytics 4 data stream ID.

  Raises:
    GoogleAnalyticsAdminError: If an error occurs while configuring the Google Analytics 4 resource.
  """
  
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

  import argparse

  parser = argparse.ArgumentParser()
  parser.add_argument('--ga4_resource', type=str, required=True)
  parser.add_argument('--ga4_property_id', type=str, required=True)
  parser.add_argument('--ga4_stream_id', type=str, required=True)
  args = parser.parse_args()

  configuration = {
    'property_id': args.ga4_property_id,
    'stream_id': args.ga4_stream_id
  }

  # python setup.py --ga4_resource=measurement_properties
  if args.ga4_resource == "measurement_properties":
    secret_display_name = 'MAJ Activation'
    properties = {
      'measurement_id': get_measurement_id(configuration),
      'measurement_secret': get_measurement_protocol_secret(configuration, secret_display_name)
    }
    print(json.dumps(properties))

  if args.ga4_resource == "check_property_type":
    property = get_property(configuration)
    result = {
      'supported': f"{property.property_type == property.property_type.PROPERTY_TYPE_ORDINARY}"
    }
    print(json.dumps(result))

  # python setup.py --ga4_resource=custom_events
  if args.ga4_resource == "custom_events":
    rename_existing_ga4_custom_events(configuration, "mas_", "maj_")
    create_custom_events(configuration)

  # python setup.py --ga4_resource=custom_dimensions
  if args.ga4_resource == "custom_dimensions":
    rename_existing_ga4_custom_dimensions(configuration, "MDE ", "MAJ ")
    create_custom_dimensions(configuration)
