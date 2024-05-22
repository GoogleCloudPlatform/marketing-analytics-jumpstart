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

from typing import Optional
from kfp.dsl import component, Input, Dataset
import os
import yaml

config_file_path = os.path.join(os.path.dirname(
    __file__), '../../../../config/config.yaml')

base_image = None
if os.path.exists(config_file_path):
    with open(config_file_path, encoding='utf-8') as fh:
        configs = yaml.full_load(fh)

    vertex_components_params = configs['vertex_ai']['components']
    repo_params = configs['artifact_registry']['pipelines_docker_repo']

    # target_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['image_name']}:{vertex_components_params['tag']}"
    base_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['base_image_name']}:{vertex_components_params['base_image_tag']}"


@component(base_image=base_image)
def send_pubsub_activation_msg(
    project: str,
    topic_name: str,
    activation_type: str,
    predictions_table: Input[Dataset]
) -> None:
    """
    This function sends a Pub/Sub message to trigger the activation application.

    Args:
        project: The Google Cloud project ID.
        topic_name: The name of the Pub/Sub topic to send the message to.
        activation_type: The type of activation message to send.
        predictions_table: The BigQuery table containing the predictions to be activated.

    Returns:
        None
    """

    import json
    import logging
    from google.cloud import pubsub

    publisher = pubsub.PublisherClient()

    logging.info(f'Publishing message to topic {topic_name}')

    # References an existing topic
    topic_path = publisher.topic_path(project, topic_name)

    message_json = json.dumps({
        "activation_type": activation_type,
        "source_table": predictions_table.metadata['table_id'],
        "predictions_column": predictions_table.metadata['predictions_column']
    })

    message_bytes = message_json.encode('utf-8')

    # Publishes a message

    publish_future = publisher.publish(topic_path, data=message_bytes)
    publish_future.result()  # Verify the publish succeeded
    logging.info('Message published.')
