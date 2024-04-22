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
import kfp as kfp
import kfp.dsl as dsl

from pipelines.components.bigquery.component import (
    bq_select_best_kmeans_model, bq_clustering_predictions, 
    bq_flatten_kmeans_prediction_table, bq_evaluate, bq_stored_procedure_exec)
from pipelines.components.pubsub.component import send_pubsub_activation_msg

from google_cloud_pipeline_components.types import artifact_types
from google_cloud_pipeline_components.v1.bigquery import (
    BigqueryCreateModelJobOp, BigqueryEvaluateModelJobOp,
    BigqueryExportModelJobOp, BigqueryPredictModelJobOp,
    BigqueryQueryJobOp)

from google_cloud_pipeline_components.v1.endpoint import (EndpointCreateOp,
                                                            ModelDeployOp)
from google_cloud_pipeline_components.v1.model import ModelUploadOp
from kfp.components.importer_node import importer

from pipelines.components.bigquery.component import (
    bq_clustering_exec)

# This is the Vertex AI Pipeline definition for Audience Segmentation Traning pipelines.
# This pipeline will be compiled, uploaded and scheduled by a terraform resource in the folder `infrastructure/terraform/modules/pipelines/pipelines.tf`.
# To change these parameters, check the appropriate section in the `config.yaml.tftpl` file.
@dsl.pipeline()
def training_pl(
    project_id: str,
    location: str,
    
    model_dataset_id: str,
    model_name_bq_prefix: str,
    vertex_model_name: str,

    training_data_bq_table: str,
    exclude_features: list,

    km_num_clusters: int,
    km_init_method: str,
    #km_init_col: str = "",
    km_distance_type: str,
    km_standardize_features: str,
    km_max_interations: int,
    km_early_stop: str,
    km_min_rel_progress: float,
    km_warm_start: str
    

):

    # Train BQML clustering model and uploads to Vertex AI Model Registry
    bq_model = bq_clustering_exec(
        project_id= project_id,
        location= location,
        model_dataset_id= model_dataset_id,
        model_name_bq_prefix= model_name_bq_prefix,
        vertex_model_name= vertex_model_name,
        training_data_bq_table= training_data_bq_table,
        exclude_features=exclude_features,
        km_num_clusters= km_num_clusters,
        km_init_method= km_init_method,
        #km_init_col: str = "",
        km_distance_type= km_distance_type,
        km_standardize_features= km_standardize_features,
        km_max_interations= km_max_interations,
        km_early_stop= km_early_stop,
        km_min_rel_progress= km_min_rel_progress,
        km_warm_start= km_warm_start
    )
    
    # Evaluate the BQ model
    evaluateModel = bq_evaluate(
        project=project_id, 
        location=location, 
        model=bq_model.outputs["model"]).after(bq_model)
    


# This is the Vertex AI Pipeline definition for Audience Segmentation Prediction pipelines.
# This pipeline will be compiled, uploaded and scheduled by a terraform resource in the folder `infrastructure/terraform/modules/pipelines/pipelines.tf`.
# To change these parameters, check the appropriate section in the `config.yaml.tftpl` file.
@dsl.pipeline()
def prediction_pl(
    project_id: str,
    location: Optional[str],
    model_dataset_id: str, # to also include project.dataset
    model_name_bq_prefix: str, # must match the model name defined in the training pipeline. for now it is {NAME_OF_PIPELINE}-model
    model_metric_name: str, # one of davies_bouldin_index ,  mean_squared_distance
    model_metric_threshold: float,
    number_of_models_considered: int,
    bigquery_source: str,
    bigquery_destination_prefix: str,
    aggregated_predictions_dataset_location: str,
    query_aggregate_last_day_predictions: str,
    pubsub_activation_topic: str,
    pubsub_activation_type: str,
):

    # Get the best candidate model according to the parameters.
    purchase_propensity_label = bq_select_best_kmeans_model(
        project_id=project_id,
        location=location,
        model_prefix=model_name_bq_prefix,
        dataset_id= model_dataset_id,
        metric_name= model_metric_name,
        metric_threshold= model_metric_threshold,
        number_of_models_considered= number_of_models_considered,
    ).set_display_name('elect_latest_model')

    # Submits a BigQuery job to generate the predictions using the `bigquery_source` and prediction dataset.
    predictions_op = bq_clustering_predictions(
        model = purchase_propensity_label.outputs['elected_model'],
        project_id = project_id,
        location = location,
        bigquery_source = bigquery_source,
        bigquery_destination_prefix= bigquery_destination_prefix)

    # Flattens the prediction table
    flatten_predictions = bq_flatten_kmeans_prediction_table(
        project_id=project_id,
        location=location,
        source_table=predictions_op.outputs['destination_table']
    )

    # Sends a pubsub activation message that will trigger the Activation Dataflow job.
    send_pubsub_activation_msg(
        project=project_id,
        topic_name=pubsub_activation_topic,
        activation_type=pubsub_activation_type,
        predictions_table=flatten_predictions.outputs['destination_table'],
    ).set_display_name('send_pubsub_activation_msg').after(flatten_predictions)

    # Invokes the BQ stored procedure that collects all predictions tables and aggregates into a single table.
    bq_stored_procedure_exec(
        project=project_id,
        location=aggregated_predictions_dataset_location,
        query=query_aggregate_last_day_predictions,
        query_parameters=[]

    ).set_display_name('aggregate_predictions').after(flatten_predictions)

