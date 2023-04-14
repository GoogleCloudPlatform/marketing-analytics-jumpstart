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
from unittest.mock import patch
from pytest_mock import MockerFixture
import inspect
import logging
import shutil
from datetime import datetime
import yaml
from kfp.dsl import component, Output, Artifact, Model, Input, Metrics, ClassificationMetrics

artifacts_path = os.path.join(os.path.dirname(__file__), 'artifacts')

data_path = os.path.join(os.path.dirname(__file__), 'test_data')


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
def test_pred(variables):
    from kfp.components.executor import Executor
    from kfp.components.executor_main import component_executor
    from pipelines.components.vertex.component import elect_best_tabular_model
    import json

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['prediction']

    executor_input = {
        "inputs": {
            "parameterValues": {
                'project': generic_pipeline_vars['project_id'],
                'location': generic_pipeline_vars['region'],
                'display_name': my_pipeline_vars['pipeline_parameters']['model_display_name'],
                'metric_name': my_pipeline_vars['pipeline_parameters']['model_metric_name'],
                'metric_threshold': my_pipeline_vars['pipeline_parameters']['model_metric_threshold'],
                'number_of_models_considered': my_pipeline_vars['pipeline_parameters']['number_of_models_considered'],
            }
        },
        "outputs": {
            "artifacts": {
                "metrics_logger": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "system.Metrics"
                            },
                            "uri": "gs://test/metrics_logger"
                        }
                    ]
                },
                "classification_metrics_logger": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "system.ClassificationMetrics"
                            },
                            "uri": "gs://test/classification_metrics_logger"
                        }
                    ]
                },
                "elected_model": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "google.VertexModel"
                            },
                            "uri": "gs://test/vmodel"
                        }
                    ]
                }
            },
            "outputFile": f"{artifacts_path}/output_metadata.json"
        }
    }
    with open(os.path.join(artifacts_path, 'input_data.json'), "w") as f:
        json.dump(executor_input, f)

    Executor(
        executor_input=executor_input,
        function_to_execute=elect_best_tabular_model.python_func).execute()





@pytest.mark.inte
@pytest.mark.compo
def test_regression_best_model(variables):
    from kfp.components.executor import Executor
    from kfp.components.executor_main import component_executor
    from pipelines.components.vertex.component import elect_best_tabular_model
    import json

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['clv']['prediction']

    executor_input = {
        "inputs": {
            "parameterValues": {
                'project': generic_pipeline_vars['project_id'],
                'location': generic_pipeline_vars['region'],
                'display_name': my_pipeline_vars['pipeline_parameters']['model_display_name'],
                'metric_name': my_pipeline_vars['pipeline_parameters']['model_metric_name'],
                'metric_threshold': my_pipeline_vars['pipeline_parameters']['model_metric_threshold'],
                'number_of_models_considered': my_pipeline_vars['pipeline_parameters']['number_of_models_considered'],
            }
        },
        "outputs": {
            "artifacts": {
                "metrics_logger": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "system.Metrics"
                            },
                            "uri": "gs://test/metrics_logger"
                        }
                    ]
                },
                "classification_metrics_logger": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "system.ClassificationMetrics"
                            },
                            "uri": "gs://test/classification_metrics_logger"
                        }
                    ]
                },
                "elected_model": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "google.VertexModel"
                            },
                            "uri": "gs://test/vmodel"
                        }
                    ]
                }
            },
            "outputFile": f"{artifacts_path}/output_metadata.json"
        }
    }
    with open(os.path.join(artifacts_path, 'input_data.json'), "w") as f:
        json.dump(executor_input, f)

    Executor(
        executor_input=executor_input,
        function_to_execute=elect_best_tabular_model.python_func).execute()


