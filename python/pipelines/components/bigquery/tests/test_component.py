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
@pytest.mark.parametrize("prediction_model_id", ["<prediction_model_id>"])
def test_bq_clustering_predictions(variables, prediction_model_id):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']

    mock = MockerFixture(config=None)
    model = mock.Mock(
        spec=Model,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "projectId": my_pipeline_vars['pipeline_parameters']['project_id'],
            "datasetId": "audience_segmentation",
            "modelId": prediction_model_id
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
@pytest.mark.parametrize("prediction_table_id", ["<prediction_table_id>"])
def test_bq_flatten_tabular_binary_prediction_table(variables, prediction_table_id):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['prediction']

    mock = MockerFixture(config=None)
    prediction_table = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "table_id": prediction_table_id,
            "predictions_column_prefix": "predicted_",
            "predictions_column": "prediction"
        })
  
    destination_table = mock.Mock(
        spec=Artifact, 
        uri=os.path.join(artifacts_path,"artifact"),
        path=os.path.join(artifacts_path,"artifact"),
        metadata={}
    )

    bq_flatten_tabular_binary_prediction_table.python_func(
        project_id= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        source_table= my_pipeline_vars['pipeline_parameters']['bigquery_source'],
        destination_table= destination_table,
        bq_unique_key= my_pipeline_vars['pipeline_parameters']['bq_unique_key'],
        predictions_table=prediction_table
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


@pytest.mark.inte
@pytest.mark.compo
@pytest.mark.parametrize("prediction_table_id", ["<prediction_table_id>"])
def test_bq_flatten_tabular_regression_table(variables, prediction_table_id):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['prediction']

    mock = MockerFixture(config=None)
    prediction_table = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "table_id": prediction_table_id,
            "predictions_column_prefix": "predicted_",
            "predictions_column": "prediction"
        })
  
    destination_table = mock.Mock(
        spec=Artifact, 
        uri=os.path.join(artifacts_path,"artifact"),
        path=os.path.join(artifacts_path,"artifact"),
        metadata={}
    )

    bq_flatten_tabular_regression_table.python_func(
        project_id= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        source_table= my_pipeline_vars['pipeline_parameters']['bigquery_source'],
        destination_table= destination_table,
        bq_unique_key= my_pipeline_vars['pipeline_parameters']['bq_unique_key'],
        predictions_table=prediction_table
    )


@pytest.mark.inte
@pytest.mark.compo
@pytest.mark.parametrize("prediction_table_id", ["<prediction_table_id>"])
def test_bq_flatten_kmeans_prediction_table(variables, prediction_table_id):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['segmentation']['prediction']

    mock = MockerFixture(config=None)
    source_table = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "table_id": prediction_table_id,
            "predictions_column_prefix": "CENTROID_ID"
        })
  
    destination_table = mock.Mock(
        spec=Artifact, 
        uri=os.path.join(artifacts_path,"artifact"),
        path=os.path.join(artifacts_path,"artifact"),
        metadata={}
    )

    bq_flatten_kmeans_prediction_table.python_func(
        project_id= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        destination_table= destination_table,
        source_table=source_table
    )


@pytest.mark.inte
@pytest.mark.compo
@pytest.mark.parametrize("prediction_table_propensity_id", ["<prediction_table_propensity_id>"])
@pytest.mark.parametrize("prediction_table_regression_id", ["<prediction_table_regression_id>"])
def test_bq_union_predictions_tables(variables, prediction_table_propensity_id, prediction_table_regression_id):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['clv']['prediction']

    mock = MockerFixture(config=None)
    predictions_table_propensity = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "table_id": prediction_table_propensity_id,
            "predictions_column_prefix": "predicted_",
            "predictions_column": "prediction"
        })
    predictions_table_regression = mock.Mock(
        spec=Dataset,
        uri=os.path.join(artifacts_path,"model"),
        path=os.path.join(artifacts_path,"model"),
        metadata={
            "table_id": prediction_table_regression_id,
            "predictions_column": "prediction"
        })
  
    destination_table = mock.Mock(
        spec=Artifact, 
        uri=os.path.join(artifacts_path,"artifact"),
        path=os.path.join(artifacts_path,"artifact"),
        metadata={}
    )

    bq_union_predictions_tables.python_func(
        project_id= my_pipeline_vars['pipeline_parameters']['project_id'],
        location= my_pipeline_vars['pipeline_parameters']['location'],
        predictions_table_propensity= predictions_table_propensity,
        predictions_table_regression= predictions_table_regression,
        table_propensity_bq_unique_key= my_pipeline_vars['pipeline_parameters']['purchase_bq_unique_key'],
        table_regression_bq_unique_key= my_pipeline_vars['pipeline_parameters']['clv_bq_unique_key'],
        destination_table= destination_table,
    )