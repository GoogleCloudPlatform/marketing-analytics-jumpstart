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
def test_elect_best_tabular_model_propensity_prediction(variables):
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
def test_elect_best_tabular_model_ltv_prediction(variables):
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
                'display_name': my_pipeline_vars['pipeline_parameters']['clv_model_display_name'],
                'metric_name': my_pipeline_vars['pipeline_parameters']['clv_model_metric_name'],
                'metric_threshold': my_pipeline_vars['pipeline_parameters']['clv_model_metric_threshold'],
                'number_of_models_considered': my_pipeline_vars['pipeline_parameters']['number_of_clv_models_considered'],
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
def test_get_latest_model_auto_segmentation_prediction(variables):
    from kfp.components.executor import Executor
    from kfp.components.executor_main import component_executor
    from pipelines.components.vertex.component import get_latest_model
    import json

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['auto_segmentation']['prediction']

    executor_input = {
        "inputs": {
            "parameterValues": {
                'project': generic_pipeline_vars['project_id'],
                'location': generic_pipeline_vars['region'],
                'display_name': my_pipeline_vars['pipeline_parameters']['model_name'],
            }
        },
        "outputs": {
            "artifacts": {
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
        function_to_execute=get_latest_model.python_func).execute()



@pytest.mark.inte
@pytest.mark.compo
@pytest.mark.parametrize("model_resource_number", ["<model_resource_number>"])
@pytest.mark.parametrize("metadata_store_resource_number", ["<metadata_store_resource_number>"])
def test_batch_prediction_auto_segmentation_prediction(variables, model_resource_number, metadata_store_resource_number):
    from kfp.components.executor import Executor
    from kfp.components.executor_main import component_executor
    from pipelines.components.vertex.component import batch_prediction
    import json
    from google.cloud import resourcemanager_v3

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['auto_segmentation']['prediction']

    rm = resourcemanager_v3.ProjectsClient()
    req = resourcemanager_v3.GetProjectRequest(name=f"projects/{generic_pipeline_vars['project_id']}")
    res = rm.get_project(request=req)
    project_number_str = res.name.split('/')[1]

    executor_input = {
        "inputs": {
            "artifacts": {
                "model": {
                    "artifacts": [
                        {
                            "metadata": {
                                "resourceName": f"projects/{project_number_str}/locations/{generic_pipeline_vars['region']}/models/{model_resource_number}",
                                "version": "1"
                            },
                            "name": f"projects/{project_number_str}/locations/{generic_pipeline_vars['region']}/metadataStores/default/artifacts/{metadata_store_resource_number}",
                            "type": {
                                "schemaTitle": "google.VertexModel"
                            },
                            "uri": f"https://{generic_pipeline_vars['region']}-aiplatform.googleapis.com/v1/projects/{project_number_str}/locations/{generic_pipeline_vars['region']}/models/{model_resource_number}/versions/1"
                        }
                    ]
                }
            },
            "parameterValues": {
                'accelerator_count': 0,
                'accelerator_type': "ACCELERATOR_TYPE_UNSPECIFIED",
                'batch_size': 64,
                'bigquery_destination_prefix': f"{generic_pipeline_vars['project_id']}.auto_audience_segmentation.p_auto_audience_segmentation_inference_15",
                'bigquery_source': f"{generic_pipeline_vars['project_id']}.auto_audience_segmentation.v_auto_audience_segmentation_inference_15",
                'dst_table_expiration_hours': 0,
                'generate_explanation': 0,
                'job_name_prefix': "test-vaip-batch",
                'machine_type': "n1-standard-2",
                'max_replica_count': 1,
                'pipelinechannel--bigquery_source':f"{generic_pipeline_vars['project_id']}.auto_audience_segmentation.v_auto_audience_segmentation_inference_15",
                'project': generic_pipeline_vars['project_id'],
                'location': generic_pipeline_vars['region'],
                'display_name': my_pipeline_vars['pipeline_parameters']['model_name'],
            }
        },
        "outputs": {
            "artifacts": {
                "destination_table": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": f"projects/{project_number_str}/locations/{generic_pipeline_vars['region']}/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "system.Dataset"
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
        function_to_execute=batch_prediction.python_func).execute()
