# Copyregression 2023 Google LLC
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
from pipelines.components.vertex.component import elect_best_tabular_model, \
                                                  batch_prediction, \
                                                  get_tabular_model_explanation

from pipelines.components.bigquery.component import bq_flatten_tabular_binary_prediction_table, \
                                                    bq_flatten_tabular_regression_table, \
                                                    bq_union_predictions_tables, \
                                                    write_tabular_model_explanation_to_bigquery

from pipelines.components.pubsub.component import send_pubsub_activation_msg


# Function containing a KFP definition for a Prediction pipeline that uses a Tabular Workflow Model.
# This is for Binary Classification model.
@dsl.pipeline()
def prediction_binary_classification_pl(
    project_id: str,
    location: Optional[str],
    model_display_name: str,
    model_metric_name: str,
    model_metric_threshold: float,
    number_of_models_considered: int,
    pubsub_activation_topic: str,
    pubsub_activation_type: str,
    bigquery_source: str,
    bigquery_destination_prefix: str,
    bq_unique_key: str,
    job_name_prefix: str,
    machine_type: str = "n1-standard-4",
    max_replica_count: int = 10,
    batch_size: int = 64,
    accelerator_count: int = 0,
    accelerator_type: str = None,
    generate_explanation: bool = False,
    threashold: float = 0.5,
    positive_label: str = 'true',
):
    """
    This function defines a KFP pipeline for binary classification prediction pipeline using an AutoML Tabular Workflow Model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be deployed.
        model_display_name: The name of the Tabular Workflow Model to be used for prediction.
        model_metric_name: The name of the metric used to select the best model.
        model_metric_threshold: The threshold value for the metric used to select the best model.
        number_of_models_considered: The number of models to consider when selecting the best model.
        pubsub_activation_topic: The name of the Pub/Sub topic to send activation messages to.
        pubsub_activation_type: The type of activation message to send.
        bigquery_source: The BigQuery table containing the data to be predicted.
        bigquery_destination_prefix: The prefix for the BigQuery table where the predictions will be stored.
        bq_unique_key: The name of the column in the BigQuery table that uniquely identifies each row.
        job_name_prefix: The prefix for the Vertex AI Batch Prediction job name.
        machine_type: The machine type to use for the Vertex AI Batch Prediction job.
        max_replica_count: The maximum number of replicas to use for the Vertex AI Batch Prediction job.
        batch_size: The batch size to use for the Vertex AI Batch Prediction job.
        accelerator_count: The number of accelerators to use for the Vertex AI Batch Prediction job.
        accelerator_type: The type of accelerators to use for the Vertex AI Batch Prediction job.
        generate_explanation: Whether to generate explanations for the predictions.
        threashold: The threshold value used to convert the predicted probabilities into binary labels.
        positive_label: The label to assign to predictions with a probability greater than or equal to the threshold.
    """

    # Elect best model based on a metric and a threshold
    purchase_propensity_label = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=model_display_name,
        metric_name=model_metric_name,
        metric_threshold=model_metric_threshold,
        number_of_models_considered=number_of_models_considered,
    ).set_display_name('elect_best_model')

    # Submits a Vertex AI Batch prediction job
    predictions = batch_prediction(
        bigquery_source=bigquery_source,
        bigquery_destination_prefix=bigquery_destination_prefix,
        job_name_prefix=job_name_prefix,
        model=purchase_propensity_label.outputs['elected_model'],
        machine_type=machine_type,
        max_replica_count=max_replica_count,
        batch_size=batch_size,
        accelerator_count=accelerator_count,
        accelerator_type=accelerator_type,
        generate_explanation=generate_explanation
    )

    # Flattens prediction table in BigQuery
    flatten_predictions = bq_flatten_tabular_binary_prediction_table(
        project_id=project_id,
        location=location,
        source_table=bigquery_source,
        predictions_table=predictions.outputs['destination_table'],
        bq_unique_key=bq_unique_key,
        threashold=threashold,
        positive_label=positive_label
    )

    # Sends pubsub message for activation
    send_pubsub_activation_msg(
        project=project_id,
        topic_name=pubsub_activation_topic,
        activation_type=pubsub_activation_type,
        predictions_table=flatten_predictions.outputs['destination_table'],
    )


# Function containing a KFP definition for a Prediction pipeline that uses a Tabular Workflow Model.
# This is for Regression model.
@dsl.pipeline()
def prediction_regression_pl(
    project_id: str,
    location: Optional[str],
    model_display_name: str,
    model_metric_name: str,
    model_metric_threshold: float,
    number_of_models_considered: int,
    pubsub_activation_topic: str,
    pubsub_activation_type: str,
    bigquery_source: str,
    bigquery_destination_prefix: str,
    bq_unique_key: str,
    job_name_prefix: str,
    machine_type: str = "n1-standard-4",
    max_replica_count: int = 10,
    batch_size: int = 64,
    accelerator_count: int = 0,
    accelerator_type: str = None,
    generate_explanation: bool = False
):
    """
    This function defines a KFP pipeline for regression prediction pipeline using an AutoML Tabular Workflow Model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be deployed.
        model_display_name: The name of the Tabular Workflow Model to be used for prediction.
        model_metric_name: The name of the metric used to select the best model.
        model_metric_threshold: The threshold value for the metric used to select the best model.
        number_of_models_considered: The number of models to consider when selecting the best model.
        pubsub_activation_topic: The name of the Pub/Sub topic to send activation messages to.
        pubsub_activation_type: The type of activation message to send.
        bigquery_source: The BigQuery table containing the data to be predicted.
        bigquery_destination_prefix: The prefix for the BigQuery table where the predictions will be stored.
        bq_unique_key: The name of the column in the BigQuery table that uniquely identifies each row.
        job_name_prefix: The prefix for the Vertex AI Batch Prediction job name.
        machine_type: The machine type to use for the Vertex AI Batch Prediction job.
        max_replica_count: The maximum number of replicas to use for the Vertex AI Batch Prediction job.
        batch_size: The batch size to use for the Vertex AI Batch Prediction job.
        accelerator_count: The number of accelerators to use for the Vertex AI Batch Prediction job.
        accelerator_type: The type of accelerators to use for the Vertex AI Batch Prediction job.
        generate_explanation: Whether to generate explanations for the predictions.
    """

    # Elect best model based on a metric and a threshold
    customer_lifetime_value_model = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=model_display_name,
        metric_name=model_metric_name,
        metric_threshold=model_metric_threshold,
        number_of_models_considered=number_of_models_considered,
    ).set_display_name('elect_best_clv_model')

    # Submits a Vertex AI Batch prediction job
    predictions = batch_prediction(
        bigquery_source=bigquery_source,
        bigquery_destination_prefix=bigquery_destination_prefix,
        job_name_prefix=job_name_prefix,
        model=customer_lifetime_value_model.outputs['elected_model'],
        machine_type=machine_type,
        max_replica_count=max_replica_count,
        batch_size=batch_size,
        accelerator_count=accelerator_count,
        accelerator_type=accelerator_type,
        generate_explanation=generate_explanation
    )

    # Flattens prediction table in BigQuery
    flatten_predictions = bq_flatten_tabular_regression_table(
        project_id=project_id,
        location=location,
        source_table=bigquery_source,
        predictions_table=predictions.outputs['destination_table'],
        bq_unique_key=bq_unique_key
    )

    # Sends pubsub message for activation
    send_pubsub_activation_msg(
        project=project_id,
        topic_name=pubsub_activation_topic,
        activation_type=pubsub_activation_type,
        predictions_table=flatten_predictions.outputs['destination_table'],
    )


@dsl.pipeline()
def prediction_binary_classification_regression_pl(
    project_id: str,
    location: Optional[str],
    purchase_bigquery_source: str,
    purchase_bigquery_destination_prefix: str,
    purchase_bq_unique_key: str,
    purchase_job_name_prefix: str,
    clv_bigquery_source: str,
    clv_bigquery_destination_prefix: str,
    clv_bq_unique_key: str,
    clv_job_name_prefix: str,
    purchase_model_display_name: str,
    purchase_model_metric_name: str,
    purchase_model_metric_threshold: float,
    number_of_purchase_models_considered: int,
    clv_model_display_name: str,
    clv_model_metric_name: str,
    clv_model_metric_threshold: float,
    number_of_clv_models_considered: int,
    pubsub_activation_topic: str,
    pubsub_activation_type: str,
    machine_type: str = "n1-standard-4",
    max_replica_count: int = 10,
    batch_size: int = 64,
    accelerator_count: int = 0,
    accelerator_type: str = None,
    generate_explanation: bool = False,
    threashold: float = 0.5,
    positive_label: str = 'true',
):
    """
    This function defines a KFP pipeline for a combined binary classification and regression prediction pipeline using AutoML Tabular Workflow Models.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be deployed.
        purchase_bigquery_source: The BigQuery table containing the data to be predicted for purchase propensity.
        purchase_bigquery_destination_prefix: The prefix for the BigQuery table where the purchase propensity predictions will be stored.
        purchase_bq_unique_key: The name of the column in the BigQuery table that uniquely identifies each row for purchase propensity.
        purchase_job_name_prefix: The prefix for the Vertex AI Batch Prediction job name for purchase propensity.
        clv_bigquery_source: The BigQuery table containing the data to be predicted for customer lifetime value.
        clv_bigquery_destination_prefix: The prefix for the BigQuery table where the customer lifetime value predictions will be stored.
        clv_bq_unique_key: The name of the column in the BigQuery table that uniquely identifies each row for customer lifetime value.
        clv_job_name_prefix: The prefix for the Vertex AI Batch Prediction job name for customer lifetime value.
        purchase_model_display_name: The name of the Tabular Workflow Model to be used for purchase propensity prediction.
        purchase_model_metric_name: The name of the metric used to select the best model for purchase propensity.
        purchase_model_metric_threshold: The threshold value for the metric used to select the best model for purchase propensity.
        number_of_purchase_models_considered: The number of models to consider when selecting the best model for purchase propensity.
        clv_model_display_name: The name of the Tabular Workflow Model to be used for customer lifetime value prediction.
        clv_model_metric_name: The name of the metric used to select the best model for customer lifetime value.
        clv_model_metric_threshold: The threshold value for the metric used to select the best model for customer lifetime value.
        number_of_clv_models_considered: The number of models to consider when selecting the best model for customer lifetime value.
        pubsub_activation_topic: The name of the Pub/Sub topic to send activation messages to.
        pubsub_activation_type: The type of activation message to send.
        machine_type: The machine type to use for the Vertex AI Batch Prediction job.
        max_replica_count: The maximum number of replicas to use for the Vertex AI Batch Prediction job.
        batch_size: The batch size to use for the Vertex AI Batch Prediction job.
        accelerator_count: The number of accelerators to use for the Vertex AI Batch Prediction job.
        accelerator_type: The type of accelerators to use for the Vertex AI Batch Prediction job.
        generate_explanation: Whether to generate explanations for the predictions.
        threashold: The threshold value used to convert the predicted probabilities into binary labels for purchase propensity.
        positive_label: The label to assign to predictions with a probability greater than or equal to the threshold for purchase propensity.
    """

    # Elects the best purchase propensity model based on a metric and a threshold
    purchase_propensity_best_model = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=purchase_model_display_name,
        metric_name=purchase_model_metric_name,
        metric_threshold=purchase_model_metric_threshold,
        number_of_models_considered=number_of_purchase_models_considered,
    ).set_display_name('elect_best_purchase_propensity_model')

    # Submits a Vertex AI Batch Prediction job for purchase propensity
    propensity_predictions = batch_prediction(
        bigquery_source=purchase_bigquery_source,
        bigquery_destination_prefix=purchase_bigquery_destination_prefix,
        job_name_prefix=purchase_job_name_prefix,
        model=purchase_propensity_best_model.outputs['elected_model'],
        machine_type=machine_type,
        max_replica_count=max_replica_count,
        batch_size=batch_size,
        accelerator_count=accelerator_count,
        accelerator_type=accelerator_type,
        generate_explanation=generate_explanation
    ).set_display_name('propensity_predictions')

    # Elects the best customer lifetime value regression model based on a metric and a threshold
    customer_lifetime_value_model = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=clv_model_display_name,
        metric_name=clv_model_metric_name,
        metric_threshold=clv_model_metric_threshold,
        number_of_models_considered=number_of_clv_models_considered,
    ).set_display_name('elect_best_clv_model')

    # Submits a Vertex AI Batch Prediction job for customer lifetime value
    clv_predictions = batch_prediction(
        bigquery_source=clv_bigquery_source,
        bigquery_destination_prefix=clv_bigquery_destination_prefix,
        job_name_prefix=clv_job_name_prefix,
        model=customer_lifetime_value_model.outputs['elected_model'],
        machine_type=machine_type,
        max_replica_count=max_replica_count,
        batch_size=batch_size,
        accelerator_count=accelerator_count,
        accelerator_type=accelerator_type,
        generate_explanation=generate_explanation
    ).set_display_name('clv_predictions')

    # Flattens the prediction table for the customer lifetime value model
    clv_flatten_predictions = bq_flatten_tabular_regression_table(
        project_id=project_id,
        location=location,
        source_table=clv_bigquery_source,
        predictions_table=clv_predictions.outputs['destination_table'],
        bq_unique_key=clv_bq_unique_key
    ).set_display_name('clv_flatten_predictions')

    # Union the two predicitons tables: the flatenned clv predictions and the purchase propensity predictions
    union_predictions = bq_union_predictions_tables(
        project_id=project_id,
        location=location,
        predictions_table_propensity=propensity_predictions.outputs['destination_table'],
        predictions_table_regression=clv_flatten_predictions.outputs['destination_table'],
        table_propensity_bq_unique_key=purchase_bq_unique_key,
        table_regression_bq_unique_key=clv_bq_unique_key,
        threashold=threashold
    ).set_display_name('union_predictions')

    # Sends pubsub message for activation
    send_pubsub_activation_msg(
        project=project_id,
        topic_name=pubsub_activation_topic,
        activation_type=pubsub_activation_type,
        predictions_table=union_predictions.outputs['destination_table'],
    )


# Function containing a KFP definition for a Explanation pipeline that uses a Tabular Workflow Model.
# This is a Explanation Pipeline Definition that will output the Feature Attribution
@dsl.pipeline()
def explanation_tabular_workflow_regression_pl(
    project: str,
    location: str,
    data_location: str,
    model_display_name: str,
    model_metric_name: str,
    model_metric_threshold: float,
    number_of_models_considered: int,
    bigquery_destination_prefix: str,
):
    """
    This function defines a KFP pipeline for a Explanation pipeline that uses a Tabular Workflow Model.
    This is a Explanation Pipeline Definition that will output the Feature Attribution

    Args:
        project: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be deployed.
        data_location: The location of the data to be used for explanation.
        model_display_name: The name of the Tabular Workflow Model to be used for explanation.
        model_metric_name: The name of the metric used to select the best model.
        model_metric_threshold: The threshold value for the metric used to select the best model.
        number_of_models_considered: The number of models to consider when selecting the best model.
        bigquery_destination_prefix: The prefix for the BigQuery table where the explanation will be stored.
    """

    # Elect best model based on a metric and a threshold
    value_based_bidding_model = elect_best_tabular_model(
        project=project,
        location=location,
        display_name=model_display_name,
        metric_name=model_metric_name,
        metric_threshold=model_metric_threshold,
        number_of_models_considered=number_of_models_considered,
    ).set_display_name('elect_best_vbb_model')

    # Get the model explanation
    value_based_bidding_model_explanation = get_tabular_model_explanation(
        project=project,
        location=location,
        model=value_based_bidding_model.outputs['elected_model'],
    ).set_display_name('get_vbb_model_explanation')

    # Write the model explanation to BigQuery
    value_based_bidding_flatten_explanation = write_tabular_model_explanation_to_bigquery(
        project=project,
        location=location,
        data_location = data_location,
        model_explanation=value_based_bidding_model_explanation.outputs['model_explanation'],
        destination_table=bigquery_destination_prefix,
    ).set_display_name('write_vbb_model_explanation')