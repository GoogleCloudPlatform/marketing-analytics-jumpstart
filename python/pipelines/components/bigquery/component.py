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
from kfp.dsl import component, Output, Artifact, Model, Input, Metrics, Dataset
import os
import yaml

config_file_path = os.path.join(os.path.dirname(
    __file__), '../../../../config/config.yaml')

base_image = None
if os.path.exists(config_file_path):
    with open(config_file_path, encoding='utf-8') as fh:
        configs = yaml.full_load(fh)

    vertex_components_params = configs['vertex_ai']['components']
    repo_params = configs['artifact_registry']['pipelines_docker_repo']

    # target_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['image_name']}:{vertex_components_params['tag']}"
    base_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['base_image_name']}:{vertex_components_params['base_image_tag']}"


@component(base_image=base_image)
def bq_stored_procedure_exec(
    project: str,
    location: str,
    query: str,
    query_parameters: Optional[list],
    timeout: Optional[float] = 1800
) -> None:

    from google.cloud import bigquery
    import logging

    client = bigquery.Client(
        project=project,
        location=location
    )

    params = []

    for i in query_parameters:
        i['value'] = None if i['value'] == "None" else i['value']
        params.append(bigquery.ScalarQueryParameter(i['name'], i['type'], i['value']))

    job_config = bigquery.QueryJobConfig(
        query_parameters=params
    )

    query_job = client.query(
        query=query,
        location=location,
        job_config=job_config)

    query_job.result(timeout=timeout)
    # TODO: return created table


@component(base_image=base_image)
def bq_clustering_exec(
    model: Output[Artifact],
    project_id: str,
    location: str,
    model_dataset_id: str,
    model_name_bq_prefix: str,
    vertex_model_name: str,
    training_data_bq_table: str,
    exclude_features: list,
    km_num_clusters: int = 4,
    km_init_method: str = "KMEANS++",
    # km_init_col: str = "",
    km_distance_type: str = "EUCLIDEAN",
    km_standardize_features: str = "TRUE",
    km_max_interations: int = 20,
    km_early_stop: str = "TRUE",
    km_min_rel_progress: float = 0.01,
    km_warm_start: str = "FALSE"
) -> None:

    from google.cloud import bigquery
    import logging
    from datetime import datetime


    client = bigquery.Client(
        project=project_id,
        location=location
    )

    model_bq_name = f"{model_name_bq_prefix}_{str(int(datetime.now().timestamp()))}"

    exclude_sql=""
    if len(exclude_features)>0:
        for i in exclude_features:
            i = f'`{i}`'
        exclude_sql = f" EXCEPT ({', '.join(exclude_features)}) "
        
    query = f"""CREATE OR REPLACE MODEL 
      `{model_dataset_id}.{model_bq_name}` OPTIONS (model_type='KMEANS', 
      NUM_CLUSTERS={km_num_clusters}, 
      MAX_ITERATIONS={km_max_interations}, 
      MIN_REL_PROGRESS={km_min_rel_progress}, 
      KMEANS_INIT_METHOD='{km_init_method}', 
      --KMEANS_INIT_COL = string_value,
      DISTANCE_TYPE='{km_distance_type}', 
      EARLY_STOP={km_early_stop}, 
      STANDARDIZE_FEATURES={km_standardize_features}, 
      WARM_START={km_warm_start}, 
      MODEL_REGISTRY='VERTEX_AI', 
      VERTEX_AI_MODEL_ID='{vertex_model_name}' ) AS (
        SELECT * {exclude_sql} FROM `{training_data_bq_table}`
      )"""


    client = bigquery.Client(
        project=project_id,
        location=location
    )
    
    query_job = client.query(
        query=query,
        location=location
    )

    r = query_job.result()

    project, dataset  = model_dataset_id.split('.')
    model.metadata = {"projectId": project, "datasetId": dataset,
                      "modelId": model_bq_name, 'vertex_model_name': vertex_model_name}
    
    #TODO: Implement TRAINING info summary on the metrics
    # SELECT * FROM ML.TRAINING_INFO(MODEL `<project-id>.<datasets>.audience_segmentation_model`)


@component(base_image=base_image)
def bq_evaluate(
    model: Input[Artifact],
    project: str,
    location: str,
    metrics: Output[Metrics]
):

    from google.cloud import bigquery
    import json, google.auth, logging

    #TODO: To investigate why EVALUATE doesn't return any result. Find a way to remediate that.

    query = f"""SELECT * FROM ML.EVALUATE(MODEL `{model.metadata["projectId"]}.{model.metadata["datasetId"]}.{model.metadata["modelId"]}`)"""
    
    client = bigquery.Client(
        project=project,
        location=location
    )
    
    query_job = client.query(
        query=query,
        location=location
    )

    r = query_job.result()
    r = list(r)

    for i in r:
        for k,v in i.items():
            metrics.log_metric(k, v)
    """
    r = query_job.result().to_dataframe()

    logging.info(r)
    for row in r[0]:
        for idx, f in enumerate(row):
            metrics.log_metric(eval.metadata["schema"]["fields"][idx]["name"], f["v"])
    """
    
    
## NOT USED
@component(base_image=base_image)
def bq_evaluation_table(
    eval: Input[Artifact],
    metrics: Output[Metrics]
) -> None:
    for row in eval.metadata["rows"]:
        for idx, f in enumerate(row["f"]):
            metrics.log_metric(eval.metadata["schema"]["fields"][idx]["name"], f["v"])


@component(base_image=base_image)
def bq_select_best_kmeans_model(
        project_id: str,
        location: str,
        dataset_id: str,
        model_prefix: str,
        metric_name: str,
        metric_threshold: float,
        number_of_models_considered: int,
        metrics_logger: Output[Metrics],
        elected_model: Output[Artifact]) -> None:

    from google.cloud import bigquery
    import logging
    from enum import Enum

    class MetricsEnum(Enum):
        DAVIES_BOULDIN_INDEX = 'davies_bouldin_index'
        MEAN_SQUARED_DISCTANCE = 'mean_squared_distance'

        def is_new_metric_better(self, new_value: float, old_value: float):
            return new_value < old_value

        @classmethod
        def list(cls):
            return list(map(lambda c: c.value, cls))

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    # TODO(developer): Set dataset_id to the ID of the dataset that contains
    #                  the models you are listing.
    # dataset_id = 'your-project.your_dataset'

    logging.info(f"Getting models from: {project_id}.{dataset_id}")
    models = client.list_models(f"{dataset_id}")  # Make an API request.

    models_to_compare = []
    counter = 0
    for model in models:
        if model.model_id.startswith(model_prefix):
            # logging.info(f"{model.model_id} - {model.created}")
            if (counter < number_of_models_considered):
                models_to_compare.append(model)
                counter += 1
            else:
                canditate = model
                for idx, m in enumerate(models_to_compare):
                    # checks if current canditate is newer than one already in list
                    if canditate.created.timestamp() > m.created.timestamp():
                        tmp = m
                        models_to_compare[idx] = canditate
                        canditate = tmp

            # logging.info(f"{counter} {models_to_compare}")

    if len(models_to_compare) == 0:
        raise Exception(f"No models in vertex model registry match '{model_prefix}'")

    best_model = dict()
    best_eval_metrics = dict()
    for i in models_to_compare:
        logging.info(i.path)
        model_bq_name = f"{i.project}.{i.dataset_id}.{i.model_id}"
        query = f"""
            SELECT * FROM ML.EVALUATE(MODEL `{model_bq_name}`)
        """
        query_job = client.query(
            query=query,
            location=location
        )

        r = list(query_job.result())[0]

        logging.info(f"keys {r.keys()}")
        logging.info(f"{metric_name} {r.get(metric_name)}")

        if (metric_name not in best_model) or MetricsEnum(metric_name).is_new_metric_better(r.get(metric_name), best_model[metric_name]):

            for k in r.keys():
                best_eval_metrics[k] = r.get(k)

            best_model[metric_name] = r.get(metric_name)
            best_model["resource_name"] = i.path
            best_model["uri"] = model_bq_name
            logging.info(
                f"New Model/Version elected | name: {model_bq_name} | metric name: {metric_name} | metric value: {best_model[metric_name]} ")

    if MetricsEnum(metric_name).is_new_metric_better(metric_threshold, best_model[metric_name]):
        raise ValueError(
            f"Model evaluation metric {metric_name} of value {best_model[metric_name]} does not meet minumum criteria of threshold{metric_threshold}")

    for k, v in best_eval_metrics.items():
        if k in MetricsEnum.list():
            metrics_logger.log_metric(k, v)

    # elected_model.uri = f"bq://{best_model['uri']}"
    elected_model.metadata = best_model
    pId, dId, mId = best_model['uri'].split('.')
    elected_model.metadata = {
        "projectId": pId,
        "datasetId": dId,
        "modelId": mId,
        "resourceName": best_model["resource_name"]}


@component(base_image=base_image)
def bq_clustering_predictions(
    model: Input[Model],
    project_id: str,
    location: str,
    bigquery_source: str,
    bigquery_destination_prefix: str,
    destination_table: Output[Dataset]
) -> None:

    from datetime import datetime
    from google.cloud import bigquery
    import logging

    timestamp = str(int(datetime.now().timestamp()))
    destination_table.metadata["table_id"] = f"{bigquery_destination_prefix}_{timestamp}"
    model_uri = f"{model.metadata['projectId']}.{model.metadata['datasetId']}.{model.metadata['modelId']}"

    client = bigquery.Client(
        project=project_id, 
        location=location
    )

    query = f"""
            SELECT * FROM ML.PREDICT(MODEL `{model_uri}`, 
            TABLE `{bigquery_source}`)
        """

    query_job = client.query(
        query=query,
        location=location,
        job_config=bigquery.QueryJobConfig(
            destination=destination_table.metadata["table_id"])
    )

    r = query_job.result()
    if (query_job.done()):
        logging.info(f"Job Completed: {query_job.state}")

    destination_table.metadata["predictions_column_prefix"] = "CENTROID_ID"


@component(base_image=base_image)
def bq_flatten_tabular_binary_prediction_table(
    destination_table: Output[Dataset],
    project_id: str,
    location: str,
    source_table: str,
    predictions_table: Input[Dataset],
    bq_unique_key: str,
    threashold: float = 0.5,
    positive_label: str = 'true'
):

    from google.cloud import bigquery
    import logging

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    # Inspect the metadata set on destination_table and predictions_table
    logging.info(destination_table.metadata)
    logging.info(predictions_table.metadata)

    # Make an API request.
    bq_table = client.get_table(predictions_table.metadata['table_id'])
    destination_table.metadata["table_id"] = f"{predictions_table.metadata['table_id']}_view"
    destination_table.metadata["predictions_column"] = 'prediction'

    # View table properties
    logging.info(
        "Got table '{}.{}.{} located at {}'.".format(
            bq_table.project, bq_table.dataset_id, bq_table.table_id, bq_table.location)
    )

    predictions_column = None
    for i in bq_table.schema:
        if (i.name.startswith(predictions_table.metadata['predictions_column_prefix'])):
            predictions_column = i.name

    if predictions_column is None:
        raise Exception(
            f"no prediction field found in given table {predictions_table.metadata['table_id']}")
 
    query = f"""
        CREATE OR REPLACE TABLE `{destination_table.metadata["table_id"]}` AS (SELECT 
            CASE 
                WHEN {predictions_column}.classes[OFFSET(0)]='{positive_label}' AND {predictions_column}.scores[OFFSET(0)]> {threashold} THEN 'true'
                WHEN {predictions_column}.classes[OFFSET(1)]='{positive_label}' AND {predictions_column}.scores[OFFSET(1)]> {threashold} THEN 'true'
                ELSE 'false'
            END AS {destination_table.metadata["predictions_column"]},
            CASE 
                WHEN {predictions_column}.classes[OFFSET(0)]='{positive_label}' THEN {predictions_column}.scores[OFFSET(0)]
                ELSE {predictions_column}.scores[OFFSET(1)]
            END AS prediction_prob, b.*
            FROM `{predictions_table.metadata['table_id']}` as a
            INNER JOIN `{source_table}` as b on a.{bq_unique_key}=b.{bq_unique_key}            
            )
    """
  
  
    job_config = bigquery.QueryJobConfig()
    job_config.write_disposition = 'WRITE_TRUNCATE'
    
    # Reconstruct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=bq_table.location
    )
    query_job = client.query(
        query=query,
        location=bq_table.location
    )

    results = query_job.result()

    logging.info(query)

    for row in results:
        logging.info("row info: {}".format(row))




@component(base_image=base_image)
def bq_flatten_tabular_regression_table(
    project_id: str,
    location: str,
    source_table: str,
    predictions_table: Input[Dataset],
    bq_unique_key: str,
    destination_table: Output[Dataset]
):

    from google.cloud import bigquery
    import logging

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    # Inspect the metadata set on destination_table and predictions_table
    logging.info(destination_table.metadata)
    logging.info(predictions_table.metadata)

    # Make an API request.
    bq_table = client.get_table(predictions_table.metadata['table_id'])
    destination_table.metadata["table_id"] = f"{predictions_table.metadata['table_id']}_view"
    destination_table.metadata["predictions_column"] = 'prediction'

    # View table properties
    logging.info(
        "Got table '{}.{}.{} located at {}'.".format(
            bq_table.project, bq_table.dataset_id, bq_table.table_id, bq_table.location)
    )

    predictions_column = None
    for i in bq_table.schema:
        if (i.name.startswith(predictions_table.metadata['predictions_column_prefix'])):
            predictions_column = i.name

    if predictions_column is None:
        raise Exception(
            f"no prediction field found in given table {predictions_table.metadata['table_id']}")

    query = f"""
        CREATE OR REPLACE TABLE `{destination_table.metadata["table_id"]}` AS (SELECT 
            GREATEST(0.0,{predictions_column}.value) AS {destination_table.metadata["predictions_column"]}, b.*
            FROM `{predictions_table.metadata['table_id']}` as a
            INNER JOIN `{source_table}` as b on a.{bq_unique_key}=b.{bq_unique_key} 
            )
    """
    job_config = bigquery.QueryJobConfig()
    job_config.write_disposition = 'WRITE_TRUNCATE'
    
    # Reconstruct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=bq_table.location
    )
    query_job = client.query(
        query=query,
        location=bq_table.location,
    )

    results = query_job.result()

    logging.info(query)

    for row in results:
        logging.info("row info: {}".format(row))




@component(base_image=base_image)
def bq_flatten_kmeans_prediction_table(
    project_id: str,
    location: str,
    source_table: Input[Dataset],
    destination_table: Output[Dataset]
):

    from google.cloud import bigquery
    import logging

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    # Make an API request.
    bq_table = client.get_table(source_table.metadata['table_id'])

    destination_table.metadata["table_id"] = f"{source_table.metadata['table_id']}_view"
    destination_table.metadata["predictions_column"] = 'prediction'

    # View table properties
    logging.info(
        "Got table '{}.{}.{}'.".format(
            bq_table.project, bq_table.dataset_id, bq_table.table_id)
    )

    predictions_column = None
    for i in bq_table.schema:
        if (i.name.startswith(source_table.metadata['predictions_column_prefix'])):
            predictions_column = i.name

    if predictions_column is None:
        raise Exception(
            f"no prediction field found in given table {source_table.metadata['table_id']}")

    query = f"""
        CREATE OR REPLACE VIEW `{destination_table.metadata["table_id"]}` AS (SELECT 
            {predictions_column} AS {destination_table.metadata["predictions_column"]}
            , * EXCEPT({predictions_column})
            FROM `{source_table.metadata['table_id']}`)
    """
    job_config = bigquery.QueryJobConfig()
    job_config.write_disposition = 'WRITE_TRUNCATE'
    """
    # Make an API request to create the view.
    view = bigquery.Table(f"{table.metadata['table_id']}_view")
    view.view_query = query
    view = client.create_table(table = view)
    logging.info(f"Created {view.table_type}: {str(view.reference)}")
    """
    query_job = client.query(
        query=query,
        location=location
    )

    results = query_job.result()

    for row in results:
        logging.info("row info: {}".format(row))




##TODO: improve code
@component(base_image=base_image)
def bq_union_predictions_tables(
    project_id: str,
    location: str,
    predictions_table_propensity: Input[Dataset],
    predictions_table_regression: Input[Dataset],
    table_propensity_bq_unique_key: str,
    table_regression_bq_unique_key: str,
    destination_table: Output[Dataset],
    threashold: float = 0.5
):
    from google.cloud import bigquery
    import logging

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    # Inspect the metadata set on destination_table and predictions_table
    logging.info(destination_table.metadata)
    logging.info(predictions_table_propensity.metadata)
    logging.info(predictions_table_regression.metadata)

    # Get BigQuery Table Object
    bq_table_propensity = client.get_table(predictions_table_propensity.metadata['table_id'])
    # View table properties
    logging.info(
        "Got table '{}.{}.{} located at {}'.".format(
            bq_table_propensity.project, bq_table_propensity.dataset_id, bq_table_propensity.table_id, bq_table_propensity.location)
    )
    # Get BigQuery Table Object
    bq_table_regression = client.get_table(predictions_table_regression.metadata['table_id'])
    # View table properties
    logging.info(
        "Got table '{}.{}.{} located at {}'.".format(
            bq_table_regression.project, bq_table_regression.dataset_id, bq_table_regression.table_id, bq_table_regression.location)
    )

    # Get table prediction column
    predictions_column_propensity = None
    for i in bq_table_propensity.schema:
        if (i.name.startswith(predictions_table_propensity.metadata['predictions_column_prefix'])):
            predictions_column_propensity = i.name
    if predictions_column_propensity is None:
        raise Exception(
            f"no prediction field found in given table {predictions_table_propensity.metadata['table_id']}")
    predictions_column_regression = None
    for i in bq_table_regression.schema:
        if (i.name.startswith(predictions_table_regression.metadata['predictions_column'])):
            predictions_column_regression = i.name
    if predictions_column_regression is None:
        raise Exception(
            f"no prediction field found in given table {predictions_table_regression.metadata['table_id']}")

    destination_table.metadata["table_id"] = f"{predictions_table_regression.metadata['table_id']}_final"
    destination_table.metadata["predictions_column"] = 'prediction'
    query = f"""
        CREATE TEMP TABLE flattened_prediction AS (
        SELECT 
            CASE 
                WHEN {predictions_column_propensity}.classes[OFFSET(1)]='0' AND {predictions_column_propensity}.scores[OFFSET(1)]> {threashold} THEN 'false'
                WHEN {predictions_column_propensity}.classes[OFFSET(0)]='1' AND {predictions_column_propensity}.scores[OFFSET(0)]> {threashold} THEN 'true'
                ELSE 'false'
            END AS {predictions_column_regression},
            CASE 
                WHEN {predictions_column_propensity}.classes[OFFSET(1)]='0' AND {predictions_column_propensity}.scores[OFFSET(1)]> {threashold} THEN 
                {predictions_column_propensity}.scores[OFFSET(1)]
                WHEN {predictions_column_propensity}.classes[OFFSET(0)]='1' AND {predictions_column_propensity}.scores[OFFSET(0)]> {threashold} THEN
                {predictions_column_propensity}.scores[OFFSET(0)]
                ELSE {predictions_column_propensity}.scores[OFFSET(0)]
            END AS prediction_prob, 
            a.* EXCEPT({predictions_column_propensity})
            FROM `{predictions_table_propensity.metadata['table_id']}` as a
        );
        
        CREATE TEMP TABLE non_purchasers_prediction AS (
        SELECT
            B.{table_regression_bq_unique_key},
            0.0 AS clv_prediction,
            B.* EXCEPT({table_regression_bq_unique_key}, {predictions_column_regression})
        FROM
            flattened_prediction A
        INNER JOIN
            `{predictions_table_regression.metadata['table_id']}` B
        ON
            A.prediction = "false" AND A.prediction_prob > {threashold}
            AND A.{table_propensity_bq_unique_key} = B.{table_regression_bq_unique_key} 
        );

        CREATE TEMP TABLE purchasers_prediction AS (
        SELECT
            B.{table_regression_bq_unique_key},
            GREATEST(0.0, B.{predictions_column_regression}) AS clv_prediction,
            B.* EXCEPT({table_regression_bq_unique_key}, {predictions_column_regression})
        FROM
            flattened_prediction A
        INNER JOIN
            `{predictions_table_regression.metadata['table_id']}` B
        ON
            A.prediction = "true" AND A.prediction_prob > {threashold}
            AND A.{table_propensity_bq_unique_key} = B.{table_regression_bq_unique_key}
        );

        CREATE OR REPLACE TABLE `{destination_table.metadata["table_id"]}` AS
        SELECT
            A.clv_prediction AS {destination_table.metadata["predictions_column"]},
            A.* EXCEPT(clv_prediction)
        FROM
            non_purchasers_prediction A
        UNION ALL
        SELECT
            B.clv_prediction AS {destination_table.metadata["predictions_column"]},
            B.* EXCEPT(clv_prediction)
        FROM
            purchasers_prediction B
        ;
    """

    logging.info(query)

    job_config = bigquery.QueryJobConfig()
    job_config.write_disposition = 'WRITE_TRUNCATE'
    
    # Reconstruct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=bq_table_regression.location
    )
    query_job = client.query(
        query=query,
        location=bq_table_regression.location,
    )
    results = query_job.result()

    for row in results:
        logging.info("row info: {}".format(row))
