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

from typing import Optional, List
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
    query_parameters: Optional[list] = [],
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
        CREATE OR REPLACE TEMP TABLE prediction_indexes AS (
            SELECT 
            (SELECT offset from UNNEST({predictions_column}.classes) c with offset where c = "0") AS index_z,
            (SELECT offset from UNNEST({predictions_column}.classes) c with offset where c = "1") AS index_one,
            {predictions_column} as {predictions_column},
            * EXCEPT({predictions_column})
            FROM `{predictions_table.metadata['table_id']}`
        );

        CREATE OR REPLACE TEMP TABLE prediction_greatest_scores AS (
            SELECT 
            {predictions_column}.scores[SAFE_OFFSET(index_z)] AS score_zero,
            {predictions_column}.scores[SAFE_OFFSET(index_one)] AS score_one,
            GREATEST({predictions_column}.scores[SAFE_OFFSET(index_z)], {predictions_column}.scores[SAFE_OFFSET(index_one)]) AS greatest_score,
            LEAST({predictions_column}.scores[SAFE_OFFSET(index_z)], {predictions_column}.scores[SAFE_OFFSET(index_one)]) AS least_score,
            *
            FROM prediction_indexes
        );

        CREATE OR REPLACE TABLE `{destination_table.metadata["table_id"]}` AS (
            SELECT
                CASE 
                WHEN a.score_zero > {threashold} THEN 'false'
                WHEN a.score_one > {threashold} THEN 'true'
                ELSE 'false' 
                END AS {destination_table.metadata["predictions_column"]},
                CASE
                WHEN a.score_zero > {threashold} THEN a.least_score
                WHEN a.score_one > {threashold} THEN a.greatest_score
                ELSE a.least_score 
                END as prediction_prob,
                b.* 
            FROM prediction_greatest_scores as a
            INNER JOIN `{source_table}` as b on a.{bq_unique_key}=b.{bq_unique_key} 
        );
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


@component(base_image=base_image)
def bq_dynamic_query_exec_output(
    location: str,
    project_id: str,
    dataset: str,
    create_table: str,
    mds_project_id: str,
    mds_dataset: str,
    date_start: str,
    date_end: str,
    reg_expression: str,
    destination_table: Output[Dataset],
    perc_keep: int = 35,
) -> None:
    
    from google.cloud import bigquery
    import logging
    import numpy as np
    import pandas as pd
    import jinja2
    import re

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    # Construct query template
    template = jinja2.Template("""
        CREATE OR REPLACE TABLE `{{project_id}}.{{dataset}}.{{create_table}}` AS (
        SELECT
            feature,
            ROUND(100 * SUM(users) OVER (ORDER BY users DESC) / SUM(users) OVER (), 2) as cumulative_traffic_percent,

        FROM (
            SELECT
                REGEXP_EXTRACT(page_path, '{{re_page_path}}') as feature,
                COUNT(DISTINCT user_id) as users

            FROM (
                SELECT
                    user_pseudo_id as user_id,
                    page_location as page_path
                FROM `{{mds_project_id}}.{{mds_dataset}}.event`
                WHERE
                    event_name = 'page_view'
                    AND DATE(event_timestamp) BETWEEN '{{date_start}}' AND '{{date_end}}'
            )
            GROUP BY 1
        )
        WHERE
            feature IS NOT NULL
        QUALIFY
            cumulative_traffic_percent <= {{perc_keep}}
        ORDER BY 2 ASC
        )
    """)

    # Apply parameters to template
    sql = template.render(
        project_id=project_id,
        dataset=dataset,
        create_table=create_table,
        mds_project_id=mds_project_id,
        mds_dataset=mds_dataset,
        re_page_path=reg_expression,
        date_start=date_start,
        date_end=date_end,
        perc_keep=perc_keep
    )

    logging.info(f"{sql}")

    # Run the BQ query
    query_job = client.query(
        query=sql,
        location=location
    )
    results = query_job.result()

    for row in results:
        logging.info("row info: {}".format(row))


    # Extract rows values
    sql = f"""SELECT feature FROM `{project_id}.{dataset}.{create_table}`"""
    query_df = client.query(query=sql).to_dataframe()

    # Prepare component output
    destination_table.metadata["table_id"] = f"{project_id}.{dataset}.{create_table}"
    destination_table.metadata["features"] = list(query_df.feature.tolist())
    

@component(base_image=base_image)
def bq_dynamic_stored_procedure_exec_output(
    project_id: str,
    location: str,
    dataset: str,
    mds_project_id: str,
    mds_dataset: str,
    dynamic_table_input: Input[Dataset],
    training_table_output: Output[Dataset],
    date_start: str,
    date_end: str,
    lookback_days: int,
    reg_expression: str,
    stored_procedure_name: str,
    training_table: str,
    timeout: Optional[float] = 1800
) -> None:

    from google.cloud import bigquery
    import logging
    import numpy as np
    import pandas as pd
    import jinja2
    import re

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        location=location
    )

    def _clean_column_values(f):
        if f == '/' or f == '' or f is None: return 'homepage'
        if f.startswith('/'): f = f[1:]
        if f.endswith('/'): f = f[:-1]
        return re.sub('[^0-9a-zA-Z]+', '_', f)
    
    template = jinja2.Template("""
        CREATE OR REPLACE PROCEDURE `{{project_id}}.{{dataset}}.{{stored_procedure_name}}`(
        DATE_START DATE, 
        DATE_END DATE, 
        LOOKBACK_DAYS INT64
        )
        BEGIN

            DECLARE RE_PAGE_PATH STRING DEFAULT "{{reg_expression|e}}";
            
            CREATE OR REPLACE TABLE `{{project_id}}.{{dataset}}.{{training_table}}`
            AS
            WITH 
                visitor_pool AS (
                    SELECT
                    user_pseudo_id,
                    MAX(event_timestamp) as feature_timestamp,
                    DATE(MAX(event_timestamp)) - LOOKBACK_DAYS as date_lookback
                    FROM `{{mds_project_id}}.{{mds_dataset}}.event`
                    WHERE DATE(event_timestamp) BETWEEN DATE_START AND DATE_END
                    GROUP BY 1
            )

            SELECT
                user_id,
                feature_timestamp,
                {% for f in features %}COUNTIF( REGEXP_EXTRACT(page_path, RE_PAGE_PATH) = '{{ f }}' ) as {{ clean_column_values(f) }},
                {% endfor %}
            FROM (
                SELECT
                    vp.feature_timestamp,
                    ga.user_pseudo_id as user_id,
                    page_location as page_path
                FROM `{{mds_project_id}}.{{mds_dataset}}.event` as ga
                INNER JOIN visitor_pool as vp
                    ON vp.user_pseudo_id = ga.user_pseudo_id
                        AND DATE(ga.event_timestamp) >= vp.date_lookback
                WHERE
                    event_name = 'page_view'
                    AND DATE(ga.event_timestamp) BETWEEN DATE_START - LOOKBACK_DAYS AND DATE_END
            )
            GROUP BY 1, 2;
        END
    """)
    template.globals.update({'clean_column_values': _clean_column_values})

    sql = template.render(
        project_id=project_id,
        dataset=dataset,
        stored_procedure_name = stored_procedure_name,
        training_table=training_table,
        mds_project_id=mds_project_id,
        mds_dataset=mds_dataset,
        reg_expression=reg_expression,
        features= dynamic_table_input.metadata['features'] if isinstance(dynamic_table_input.metadata['features'], List) else list(dynamic_table_input.metadata['features'])
    )

    logging.info(f"{sql}")

    # Run the BQ query
    query_job = client.query(
        query=sql,
        location=location
    )
    results = query_job.result()

    for row in results:
        logging.info("row info: {}".format(row))
    
    query_job = client.query(
        query=f"CALL `{project_id}.{dataset}.{stored_procedure_name}`(@DATE_START, @DATE_END, @LOOKBACK_DAYS);",
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ScalarQueryParameter("DATE_START", "DATE", date_start),
                bigquery.ScalarQueryParameter("DATE_END", "DATE", date_end),
                bigquery.ScalarQueryParameter("LOOKBACK_DAYS", "INTEGER", lookback_days)
            ]
        )
    )
    results = query_job.result()

    for row in results:
        logging.info("row info: {}".format(row))
    
    # Prepare component output
    training_table_output.metadata["table_id"] = f"{project_id}.{dataset}.{training_table}"
    training_table_output.metadata["stored_procedure_name"] = f"{project_id}.{dataset}.{stored_procedure_name}"




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
    threashold: float
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
        CREATE OR REPLACE TEMP TABLE prediction_indexes AS (
            SELECT 
            (SELECT offset from UNNEST({predictions_column_propensity}.classes) c with offset where c = "0") AS index_zero,
            (SELECT offset from UNNEST({predictions_column_propensity}.classes) c with offset where c = "1") AS index_one,
            {predictions_column_propensity},
            * EXCEPT({predictions_column_propensity})
            FROM `{predictions_table_propensity.metadata['table_id']}`
        );

        CREATE OR REPLACE TEMP TABLE prediction_greatest_scores AS (
            SELECT 
            {predictions_column_propensity}.scores[SAFE_OFFSET(index_zero)] AS score_zero,
            {predictions_column_propensity}.scores[SAFE_OFFSET(index_one)] AS score_one,
            GREATEST({predictions_column_propensity}.scores[SAFE_OFFSET(index_zero)], {predictions_column_propensity}.scores[SAFE_OFFSET(index_one)]) AS greatest_score,
            * EXCEPT({predictions_column_propensity})
            FROM prediction_indexes
        );

        CREATE OR REPLACE TEMP TABLE flattened_prediction AS (
            SELECT
                CASE 
                WHEN a.score_zero > {threashold} THEN 'false'
                WHEN a.score_one > {threashold} THEN 'true'
                ELSE 'false' 
                END AS {predictions_column_regression},
                a.score_one AS prediction_prob,
                a.*
            FROM prediction_greatest_scores AS a
        );
        
        CREATE OR REPLACE TEMP TABLE non_purchasers_prediction AS (
        SELECT
            B.{table_regression_bq_unique_key},
            0.0 AS clv_prediction,
            B.* EXCEPT({table_regression_bq_unique_key}, {predictions_column_regression})
        FROM
            flattened_prediction A
        INNER JOIN
            `{predictions_table_regression.metadata['table_id']}` B
        ON
            A.prediction_prob <= {threashold}
            AND A.{table_propensity_bq_unique_key} = B.{table_regression_bq_unique_key} 
        );

        CREATE OR REPLACE TEMP TABLE purchasers_prediction AS (
        SELECT
            B.{table_regression_bq_unique_key},
            COALESCE(B.{predictions_column_regression}, 0.0) AS clv_prediction,
            B.* EXCEPT({table_regression_bq_unique_key}, {predictions_column_regression})
        FROM
            flattened_prediction A
        INNER JOIN
            `{predictions_table_regression.metadata['table_id']}` B
        ON
            A.prediction_prob > {threashold}
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

# This component writes Tabular Workflows feature importance values to a BigQuery table
@component(base_image=base_image)
def write_tabular_model_explanation_to_bigquery(
    project: str,
    location: str,
    data_location: str,
    destination_table: str,
    model_explanation: Input[Dataset],
):
    """
    Writes the tabular model explanation to BigQuery.
    """
    import logging
    from google.cloud import bigquery
    from google.cloud.exceptions import NotFound
    from google.api_core.retry import Retry
    from google.api_core import exceptions
    import time

    client = bigquery.Client(project=project, 
                             location=data_location)
    
    feature_names = model_explanation.metadata['feature_names']
    values = model_explanation.metadata['values']
    model_id = model_explanation.metadata['model_id']
    model_name = model_explanation.metadata['model_name']
    model_version = model_explanation.metadata['model_version']
    
        # Check if table exists continue otherwise create table
    query = """CREATE OR REPLACE TABLE `"""+ destination_table +"""` (
        processed_timestamp TIMESTAMP,
        model_id STRING,
        model_name STRING,
        model_version STRING,
        feature_names STRING,
        values FLOAT64
    )
    OPTIONS (
    description = "A table with feature names and numerical values"
    );
    """
    # Execute the query as a job
    try:
        query_job = client.query(query)
        # Wait for the query job to complete
        query_job.result()  # Waits for job to finish
        # Get query results and convert to pandas DataFrame
        df = query_job.to_dataframe()
        logging.info(df)
    except NotFound as e:
        logging.error(f"Error during vbb weights CREATE query job execution: {e}")

    # Build the INSERT query
    insert_query = "INSERT INTO `{}` (processed_timestamp, model_id, model_name, model_version, feature_names, values) VALUES ".format(destination_table)
    for i in range(len(feature_names)):
        insert_query += "(CURRENT_TIMESTAMP(), '{}', '{}', '{}', '{}', {}), ".format(model_id, model_name, model_version, feature_names[i], values[i])
    insert_query = insert_query[:-2]

    logging.info(insert_query)

    # Execute the insert a job with retries because the table isnt ready to be used sometimes after creation

    # Retry configuration
    max_retries = 5
    retry_delay = 15  # Seconds to wait between retries

    def retry_if_exception_type(exception_types):
        def decorator(func):
            def new_func(*args, **kwargs):
                try:
                    return func(*args, **kwargs)
                except exception_types as error:
                    raise exceptions.RetryError(error, cause=error)
            return new_func
        return decorator

    retry_predicate = Retry(
        predicate=retry_if_exception_type(
            exceptions.NotFound
        ),
    )

    def execute_query_with_retries(query):
        """Executes the query with retries."""
        query_job = client.query(query, retry=retry_predicate)

        while not query_job.done():  # Check if the query job is complete
            print("Query running...")
            time.sleep(retry_delay)  # Wait before checking status again
            query_job.reload()  # Reload the job state

        if query_job.errors:
            raise RuntimeError(f"Query errors: {query_job.errors}")

        return query_job.result()  # Return the results

    # Execute the query
    try:
        result = execute_query_with_retries(insert_query)


    except RuntimeError as e:
        logging.error(f"Query failed after retries: {e}")
    

    