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
    bq_flatten_kmeans_prediction_table, bq_evaluate,
    bq_clustering_exec, bq_stored_procedure_exec)

from pipelines.components.vertex.component import (
    get_latest_model,
    batch_prediction,
    return_unmanaged_model
)
from pipelines.components.pubsub.component import send_pubsub_activation_msg
from pipelines.components.python.component import train_scikit_cluster_model

from google_cloud_pipeline_components.types import artifact_types
from google_cloud_pipeline_components.v1.bigquery import (
    BigqueryCreateModelJobOp, BigqueryEvaluateModelJobOp,
    BigqueryExportModelJobOp, BigqueryPredictModelJobOp,
    BigqueryQueryJobOp)

from google_cloud_pipeline_components.v1.endpoint import (EndpointCreateOp,
                                                            ModelDeployOp)
from google_cloud_pipeline_components.v1.model import ModelUploadOp
from google_cloud_pipeline_components.types import artifact_types


# This is the Vertex AI Pipeline definition for Auto Audience Segmentation Traning pipelines.
# This pipeline will be compiled, uploaded and scheduled by a terraform resource in the folder `infrastructure/terraform/modules/pipelines/pipelines.tf`.
# To change these parameters, check the appropriate section in the `config.yaml.tftpl` file.
@dsl.pipeline()
def training_pl(
    project_id: str,
    dataset: str,
    location: Optional[str],
    training_table: str,
    bucket_name: str,
    model_name: str,
    p_wiggle: int,
    min_num_clusters: int, 
    image_uri: str,
):
    # Train scikit-learn clustering model and upload to GCS
    train_interest_based_segmentation_model = train_scikit_cluster_model(
        location=location,
        project_id=project_id,
        dataset=dataset,
        training_table=training_table,
        p_wiggle=p_wiggle,
        min_num_clusters=min_num_clusters,
        bucket_name=bucket_name,
        model_name=model_name
    )

    # Return unmanaged model resource uploaded to GCS
    unmanaged_model = return_unmanaged_model(
        image_uri=image_uri,
        bucket_name=bucket_name,
        model_name=model_name
    ).after(*[train_interest_based_segmentation_model])

    # Consuming the UnmanagedContainerModel artifact for the previous step
    model_upload_with_artifact = ModelUploadOp(
        project=project_id,
        location=location,
        display_name=model_name,
        unmanaged_container_model=unmanaged_model.outputs['model']
    ).after(*[unmanaged_model])




# This is the Vertex AI Pipeline definition for Auto Audience Segmentation Prediction pipelines.
# This pipeline will be compiled, uploaded and scheduled by a terraform resource in the folder `infrastructure/terraform/modules/pipelines/pipelines.tf`.
# To change these parameters, check the appropriate section in the `config.yaml.tftpl` file.
@dsl.pipeline()
def prediction_pl(
    project_id: str,
    location: Optional[str],
    model_name: str,
    bigquery_source: str,
    bigquery_destination_prefix: str,
    pubsub_activation_topic: str,
    pubsub_activation_type: str,
    aggregated_predictions_dataset_location: str,
    query_aggregate_last_day_predictions: str
):
    # Get the latest model named `model_name`
    model_op = get_latest_model(
        project=project_id,
        location=location,
        display_name=model_name
    )

    # Submit a vertex ai job to run batch prediction using the `bigquery_source` as prediction dataset.
    prediction_op = batch_prediction(
        job_name_prefix='vaip-batch',
        bigquery_source=f"{bigquery_source}",
        bigquery_destination_prefix=bigquery_destination_prefix,
        model=model_op.outputs["elected_model"],
        max_replica_count=1,
        # dst_table_expiration_hours=24*7
    ).after(model_op)

    # Sends a pubsub activation message that will trigger the Activation Dataflow job.
    send_pubsub_activation_msg(
        project=project_id,
        topic_name=pubsub_activation_topic,
        activation_type=pubsub_activation_type,
        predictions_table=prediction_op.outputs['destination_table'],
    ).set_display_name('send_pubsub_activation_msg').after(prediction_op)

    # Invokes the BQ stored procedure that collects all predictions tables and aggregates into a single table.
    bq_stored_procedure_exec(
        project=project_id,
        location=aggregated_predictions_dataset_location,
        query=query_aggregate_last_day_predictions,
        query_parameters=[]
    ).set_display_name('aggregate_predictions').after(prediction_op)

