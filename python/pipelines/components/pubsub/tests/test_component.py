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

import pytest
import os
from pytest_mock import MockerFixture
import pipelines.pipeline_ops as pl_ops
import inspect
import logging
import shutil
from unittest.mock import patch
from datetime import datetime
import yaml
from kfp.dsl import component, Output, Artifact, Model, Input, Metrics, Dataset
from pipelines.components.pubsub.component import send_pubsub_activation_msg

artifacts_path = os.path.join(os.path.dirname(__file__), './artifacts/')
data_path = os.path.join(os.path.dirname(__file__), './test_data/')


@pytest.fixture(scope="session", autouse=True)
def test_setup():
    # SETUP
    patcher = patch(
        "kfp.components.types.artifact_types._GCS_LOCAL_MOUNT_PREFIX", f"{artifacts_path}/")

    patcher.start()

    if not os.path.exists(artifacts_path):
        os.makedirs(artifacts_path)

    yield "testing..."

    # TEARDOWN

    patcher.stop()
    # try:
    #    shutil.rmtree(artifacts_path)
    # except OSError as e:
    #    print("Error: %s - %s." % (e.filename, e.strerror))

# ------------------------------------------------------------------------------------------------------------------------


@pytest.mark.inte
@pytest.mark.compo
def test_send_pubsub_activation_msg(variables):
    from kfp.components.executor import Executor
    import json

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']

    mock = MockerFixture(config=None)
    predictions_table = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path, "model"),
        path=os.path.join(artifacts_path, "model"),
        metadata={
            "table_id": "propensity-modelling-368616.ds.bank_marketing_prediction_1678207170",
            "predictions_column": "predictions",
        })

    send_pubsub_activation_msg.python_func(
        project=generic_pipeline_vars['project_id'],
        topic_name=my_pipeline_vars['pipeline_parameters']['pubsub_activation_topic'],
        activation_type= my_pipeline_vars['pipeline_parameters']['pubsub_activation_type'],
        predictions_table=predictions_table
    )
