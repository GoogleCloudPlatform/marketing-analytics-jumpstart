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
    bq_flatten_kmeans_prediction_table, bq_evaluate)
from pipelines.components.pubsub.component import send_pubsub_activation_msg
from pipelines.components.python.component import hyper_parameter_tuning_scikit_audience_model
from pipelines.components.bigquery.component import (bq_clustering_exec)

# This is the Vertex AI Pipeline definition for Audience Segmentation Traning pipelines.
# This pipeline will be compiled, uploaded and scheduled by a terraform resource in the folder `infrastructure/terraform/modules/pipelines/pipelines.tf`.
# To change these parameters, check the appropriate section in the `config.yaml.tftpl` file.
@dsl.pipeline()
def training_pl(
    project_id: str,
    dataset: str,
    location: str,
    
    model_name_bq_prefix: str,
    vertex_model_name: str,

    training_data_bq_table: str,
    exclude_features: list,

    p_wiggle: int,
    columns_to_skip: int,

    km_distance_type: str,
    km_early_stop: str,
    km_warm_start: str,
    
    use_split_column: str,
    use_hparams_tuning: str
    

):
    """
    This function defines the Vertex AI Pipeline for Audience Segmentation Training.
    Model type is KMEANS which uses k-means clustering for data segmentation; for example, 
    identifying customer segments. K-means is an unsupervised learning technique, so model training does not require labels or split data for training or evaluation.

    Args:
        project_id (str): The Google Cloud project ID.
        location (str): The Google Cloud region where the pipeline will be deployed.
        dataset (str): The BigQuery dataset ID where the model will be stored.
        model_name_bq_prefix (str): The prefix for the BQML model name.
        vertex_model_name (str): The name of the Vertex AI model.
        training_data_bq_table (str): The BigQuery table containing the training data.
        exclude_features (list): A list of features to exclude from the training data.
        km_num_clusters (int): The number of clusters to use for training.
        km_init_method (str): The initialization method to use for training.
        km_distance_type (str): The distance type to use for training.
        km_standardize_features (str): Whether to standardize the features before training.
        km_max_interations (int): The maximum number of iterations to train for.
        km_early_stop (str): Whether to use early stopping during training.
        km_min_rel_progress (float): The minimum relative progress required for early stopping.
        km_warm_start (str): Whether to use warm start during training.
    """

    # Runs hyperparameter tuning to find the best number of segments
    hp_params = hyper_parameter_tuning_scikit_audience_model(
        location=location,
        project_id=project_id,
        dataset=dataset,
        training_table=training_data_bq_table,
        p_wiggle=p_wiggle,
        columns_to_skip=columns_to_skip,
        use_split_column=use_split_column,
    )

    # Train BQML clustering model and uploads to Vertex AI Model Registry
    bq_model = bq_clustering_exec(
        project_id= project_id,
        location= location,
        model_dataset_id= dataset,
        model_name_bq_prefix= model_name_bq_prefix,
        vertex_model_name= vertex_model_name,
        training_data_bq_table= training_data_bq_table,
        exclude_features=exclude_features,
        model_parameters = hp_params.outputs["model_parameters"],
        km_distance_type= km_distance_type,
        km_early_stop= km_early_stop,
        km_warm_start= km_warm_start,
        use_split_column= use_split_column,
        use_hparams_tuning= use_hparams_tuning
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
    pubsub_activation_topic: str,
    pubsub_activation_type: str
):
    """
    This function defines the Vertex AI Pipeline for Audience Segmentation Prediction.

    Args:
        project_id (str): The Google Cloud project ID.
        location (Optional[str]): The Google Cloud region where the pipeline will be deployed.
        model_dataset_id (str): The BigQuery dataset ID where the model is stored.
        model_name_bq_prefix (str): The prefix for the BQML model name.
        model_metric_name (str): The metric name to use for model selection.
        model_metric_threshold (float): The metric threshold to use for model selection.
        number_of_models_considered (int): The number of models to consider for selection.
        bigquery_source (str): The BigQuery table containing the prediction data.
        bigquery_destination_prefix (str): The prefix for the BigQuery table where the predictions will be stored.
        pubsub_activation_topic (str): The Pub/Sub topic to send the activation message to.
        pubsub_activation_type (str): The type of activation message to send.
    """

    # Get the best candidate model according to the parameters.
    segmentation_model = bq_select_best_kmeans_model(
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
        model = segmentation_model.outputs['elected_model'],
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

