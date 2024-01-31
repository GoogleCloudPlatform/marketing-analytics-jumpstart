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
import kfp.components as components
import kfp.dsl as dsl
from pipelines.components.vertex.component import elect_best_tabular_model, \
                                                  batch_prediction, \
                                                  get_tabular_model_explanation

from pipelines.components.bigquery.component import bq_flatten_tabular_binary_prediction_table, \
                                                    bq_flatten_tabular_regression_table, \
                                                    bq_union_predictions_tables, \
                                                    bq_stored_procedure_exec, \
                                                    write_tabular_model_explanation_to_bigquery

from pipelines.components.pubsub.component import send_pubsub_activation_msg

# elect_best_tabular_model = components.load_component_from_file(
#    os.path.join(os.path.dirname(__file__),'components/vertex/component_metadata/elect_best_tabular_model.yaml')
#  )


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
    aggregated_predictions_dataset_location: str,
    query_aggregate_last_day_predictions: str,
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

    purchase_propensity_label = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=model_display_name,
        metric_name=model_metric_name,
        metric_threshold=model_metric_threshold,
        number_of_models_considered=number_of_models_considered,
    ).set_display_name('elect_best_model')

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

    flatten_predictions = bq_flatten_tabular_binary_prediction_table(
        project_id=project_id,
        location=location,
        source_table=bigquery_source,
        predictions_table=predictions.outputs['destination_table'],
        bq_unique_key=bq_unique_key,
        threashold=threashold,
        positive_label=positive_label
    )

    bq_stored_procedure_exec(
        project=project_id,
        location=aggregated_predictions_dataset_location,
        query=query_aggregate_last_day_predictions,
        query_parameters=[]
    ).set_display_name('aggregate_predictions').after(flatten_predictions)

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

    customer_lifetime_value_model = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=model_display_name,
        metric_name=model_metric_name,
        metric_threshold=model_metric_threshold,
        number_of_models_considered=number_of_models_considered,
    ).set_display_name('elect_best_clv_model')

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

    flatten_predictions = bq_flatten_tabular_regression_table(
        project_id=project_id,
        location=location,
        source_table=bigquery_source,
        predictions_table=predictions.outputs['destination_table'],
        bq_unique_key=bq_unique_key
    )

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

    aggregated_predictions_dataset_location: str,
    query_aggregate_last_day_predictions: str,

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

    purchase_propensity_best_model = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=purchase_model_display_name,
        metric_name=purchase_model_metric_name,
        metric_threshold=purchase_model_metric_threshold,
        number_of_models_considered=number_of_purchase_models_considered,
    ).set_display_name('elect_best_purchase_propensity_model')

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

    customer_lifetime_value_model = elect_best_tabular_model(
        project=project_id,
        location=location,
        display_name=clv_model_display_name,
        metric_name=clv_model_metric_name,
        metric_threshold=clv_model_metric_threshold,
        number_of_models_considered=number_of_clv_models_considered,
    ).set_display_name('elect_best_clv_model')

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

    clv_flatten_predictions = bq_flatten_tabular_regression_table(
        project_id=project_id,
        location=location,
        source_table=clv_bigquery_source,
        predictions_table=clv_predictions.outputs['destination_table'],
        bq_unique_key=clv_bq_unique_key
    ).set_display_name('clv_flatten_predictions')

    union_predictions = bq_union_predictions_tables(
        project_id=project_id,
        location=location,
        predictions_table_propensity=propensity_predictions.outputs['destination_table'],
        predictions_table_regression=clv_flatten_predictions.outputs['destination_table'],
        table_propensity_bq_unique_key=purchase_bq_unique_key,
        table_regression_bq_unique_key=clv_bq_unique_key,
    ).set_display_name('union_predictions')

    bq_stored_procedure_exec(
        project=project_id,
        location=aggregated_predictions_dataset_location,
        query=query_aggregate_last_day_predictions,
        query_parameters=[]
    ).set_display_name('aggregate_predictions').after(union_predictions)

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
    location: Optional[str],
    model_display_name: str,
    model_metric_name: str,
    model_metric_threshold: float,
    number_of_models_considered: int,
    bigquery_destination_prefix: str,
):
    #TODO: Implement the explanation pipeline for the value based bidding model
    value_based_bidding_model = elect_best_tabular_model(
        project=project,
        location=location,
        display_name=model_display_name,
        metric_name=model_metric_name,
        metric_threshold=model_metric_threshold,
        number_of_models_considered=number_of_models_considered,
    ).set_display_name('elect_best_vbb_model')

    value_based_bidding_model_explanation = get_tabular_model_explanation(
        project=project,
        location=location,
        model=value_based_bidding_model.outputs['elected_model'],
    ).set_display_name('get_vbb_model_explanation')

    value_based_bidding_flatten_explanation = write_tabular_model_explanation_to_bigquery(
        project=project,
        location=location,
        model_explanation=value_based_bidding_model_explanation.outputs['model_explanation'],
        destination_table=bigquery_destination_prefix,
    ).set_display_name('write_vbb_model_explanation')