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
from pipelines.components.bigquery.component import *

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
@pytest.mark.segmentation
def test_bq_select_best_kmeans_model(variables):
    from kfp.components.executor import Executor
    import json

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']

    executor_input = {
        "inputs": {
            "parameterValues": {
                'project_id': my_pipeline_vars['pipeline_parameters']['project_id'],
                'location': my_pipeline_vars['pipeline_parameters']['location'],
                'dataset_id': my_pipeline_vars['pipeline_parameters']['model_dataset_id'],
                'model_prefix': my_pipeline_vars['pipeline_parameters']['model_name_bq_prefix'],
                'metric_name': my_pipeline_vars['pipeline_parameters']['model_metric_name'],
                'metric_threshold': my_pipeline_vars['pipeline_parameters']['model_metric_threshold'],
                'number_of_models_considered': my_pipeline_vars['pipeline_parameters']['number_of_models_considered']
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
                "elected_model": {
                    "artifacts": [
                        {
                            "metadata": {},
                            "name": "projects/123/locations/us-central1/metadataStores/default/artifacts/123",
                            "type": {
                                "schemaTitle": "system.Model"
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
        function_to_execute=bq_select_best_kmeans_model.python_func).execute()


@pytest.mark.inte
@pytest.mark.compo
@pytest.mark.segmentation
def test_bq_clustering_predictions(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']

    mock = MockerFixture(config=None)
    model = mock.Mock(
        spec=Model,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "projectId": "propensity-modelling-368616",
            "datasetId": "audience_segmentation",
            "modelId": "test_audience_segmentation_model_1680785176"
        })
        
    destination_table = mock.Mock(
        spec=Artifact, 
        uri=os.path.join(artifacts_path,"artifact"),
        path=os.path.join(artifacts_path,"artifact"),
        metadata={}
    )

    bq_clustering_predictions.python_func(
        model=model,
        project_id= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        bigquery_source= my_pipeline_vars['pipeline_parameters']['bigquery_source'],
        bigquery_destination_prefix= my_pipeline_vars['pipeline_parameters']['bigquery_destination_prefix'],
        destination_table=destination_table
    )

@pytest.mark.inte
@pytest.mark.compo
def test_bq_flatten_tabular_binary_prediction_table(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']

    mock = MockerFixture(config=None)
    prediction_table = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "table_id": "propensity-modelling-368616.ds.bank_marketing_prediction_1678207170",
            "predictions_column_prefix": "predicted_loan",
        })

    
    source_table = "propensity-modelling-368616.ds.bank_marketing_prediction_1678207170"
        
    destination_table = mock.Mock(
        spec=Artifact, 
        uri=os.path.join(artifacts_path,"artifact"),
        path=os.path.join(artifacts_path,"artifact"),
        metadata={}
    )

    bq_flatten_tabular_binary_prediction_table.python_func(
        project_id= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        source_table=source_table,
        destination_table=destination_table
    )




@pytest.mark.inte_eval
def test_bq_evaluate(variables):

    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']
    mock = MockerFixture(config=None)
    model = mock.Mock(
        spec=Model,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "projectId": "propensity-modelling-368616",
            "datasetId": "audience_segmentation",
            "modelId": "test_audience_segmentation_model_1680785176"
        })
        

    bq_evaluate.python_func(
        model=model,
        project= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        metrics = mock.Mock(spec=Metrics,
            uri=os.path.join(artifacts_path,"model"),
            path=os.path.join(artifacts_path,"model"),
            metadata={})
    )
