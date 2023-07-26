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

from datetime import datetime
from kfp import compiler
from google.cloud.aiplatform.pipeline_jobs import PipelineJob, _set_enable_caching_value
from google.cloud.aiplatform import TabularDataset, Artifact
from typing import Any, Callable, Dict, Mapping, Optional, List
import logging
import json
import yaml
import google.auth.credentials as credentials
from kfp.registry import RegistryClient
from google.cloud import aiplatform, storage
import shutil
import pathlib
import requests
import google.auth


def substitute_pipeline_params(
    pipeline_params: Dict[str, Any],
    pipeline_param_substitutions: Dict[str, Any]
) -> Dict[str, Any]:

    # if pipeline parameters include placeholders such as {PROJECT_ID} etc,
    # the following will replace such placeholder with the values
    # in the pipeline_param_substitutions dictionary
    ppp = pipeline_params.copy()
    for k, v in pipeline_params.items():
        if isinstance(v, str):
            ppp[k] = v.format(**pipeline_param_substitutions)
    return ppp


def get_bucket_name_and_path(uri):
    no_prefix_uri = uri[len("gs://"):]
    splits = no_prefix_uri.split("/")
    return splits[0], "/".join(splits[1:])


def write_to_gcs(uri: str, content: str):
    bucket_name, path = get_bucket_name_and_path(uri)
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(path)
    blob.upload_from_string(content)


def generate_auto_transformation(column_names: List[str]) -> List[Dict[str, Any]]:
    transformations = []
    for column_name in column_names:
        transformations.append({"auto": {"column_name": column_name}})
    return transformations


def write_auto_transformations(uri: str, column_names: List[str]):
    transformations = generate_auto_transformation(column_names)
    write_to_gcs(uri, json.dumps(transformations))

    logging.info("Transformations config written: {}".format(uri))


def compile_pipeline(
        pipeline_func: Callable, 
        template_path: str,
        pipeline_name: str,
        pipeline_parameters: Optional[Dict[str, Any]] = None,
        pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
        enable_caching: bool = True,
        type_check: bool = True) -> str:

    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)
    print(pipeline_parameters)
    compiler.Compiler().compile(
        pipeline_func=pipeline_func,
        package_path=template_path,
        pipeline_name=pipeline_name,
        pipeline_parameters=pipeline_parameters,
        type_check=type_check,
    )

    with open(template_path, 'r') as file:
        configuration = yaml.safe_load(file)

    _set_enable_caching_value(pipeline_spec=configuration,
                              enable_caching=enable_caching)

    with open(template_path, 'w') as yaml_file:
        yaml.dump(configuration, yaml_file)

    return template_path


def run_pipeline_from_func(
        pipeline_func: Callable,
        pipeline_root: str,
        project_id: str,
        location: str,
        service_account: str,
        pipeline_parameters: Optional[Dict[str, Any]],
        pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
        enable_caching: bool = False,
        experiment_name: str = None,
        job_id: str = None,
        labels: Optional[Dict[str, str]] = None,
        credentials: Optional[credentials.Credentials] = None,
        encryption_spec_key_name: Optional[str] = None,
        wait: bool = False) -> str:

    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)

    pl = PipelineJob.from_pipeline_func(
        pipeline_func=pipeline_func,
        parameter_values=pipeline_parameters,
        enable_caching=enable_caching,
        job_id=job_id,
        output_artifacts_gcs_dir=pipeline_root,
        project=project_id,
        location=location,
        credentials=credentials,
        encryption_spec_key_name=encryption_spec_key_name,
        labels=labels
    )
    pl.submit(service_account=service_account, experiment_name=experiment_name)

    if (wait):
        pl.wait()
        if (pl.has_failed):
            raise RuntimeError("Pipeline execution failed")
    return pl


def compile_automl_tabular_pipeline(
        template_path: str,
        parameters_path: str,
        pipeline_name: str,
        pipeline_parameters: Dict[str, Any] = None,
        pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
        exclude_features = List[Any],
        enable_caching: bool = True) -> tuple:

    from google_cloud_pipeline_components.experimental.automl.tabular import utils as automl_tabular_utils

    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)

    """
        additional_experiments: dict
#    cv_trainer_worker_pool_specs_override: list
#    data_source_bigquery_table_path: str [Default: '']
#    data_source_csv_filenames: str [Default: '']
#    dataflow_service_account: str [Default: '']
#    dataflow_subnetwork: str [Default: '']
#    dataflow_use_public_ips: bool [Default: True]
#    disable_early_stopping: bool [Default: False]
#    distill_batch_predict_machine_type: str [Default: 'n1-standard-16']
#    distill_batch_predict_max_replica_count: int [Default: 25.0]
#    distill_batch_predict_starting_replica_count: int [Default: 25.0]
#    enable_probabilistic_inference: bool [Default: False]
#    encryption_spec_key_name: str [Default: '']
#    evaluation_batch_explain_machine_type: str [Default: 'n1-highmem-8']
#    evaluation_batch_explain_max_replica_count: int [Default: 10.0]
#    evaluation_batch_explain_starting_replica_count: int [Default: 10.0]
#    evaluation_batch_predict_machine_type: str [Default: 'n1-highmem-8']
#    evaluation_batch_predict_max_replica_count: int [Default: 20.0]
#    evaluation_batch_predict_starting_replica_count: int [Default: 20.0]
#    evaluation_dataflow_disk_size_gb: int [Default: 50.0]
#    evaluation_dataflow_machine_type: str [Default: 'n1-standard-4']
#    evaluation_dataflow_max_num_workers: int [Default: 100.0]
#    evaluation_dataflow_starting_num_workers: int [Default: 10.0]
#    export_additional_model_without_custom_ops: bool [Default: False]
#    fast_testing: bool [Default: False]
#    location: str
#    model_description: str [Default: '']
#    model_display_name: str [Default: '']
#    optimization_objective: str
#    optimization_objective_precision_value: float [Default: -1.0]
#    optimization_objective_recall_value: float [Default: -1.0]
#    predefined_split_key: str [Default: '']
#    prediction_type: str
#    project: str
#    quantiles: list
#    root_dir: str
#    run_distillation: bool [Default: False]
#    run_evaluation: bool [Default: False]
#    stage_1_num_parallel_trials: int [Default: 35.0]
#    stage_1_tuner_worker_pool_specs_override: list
#    stage_1_tuning_result_artifact_uri: str [Default: '']
#    stage_2_num_parallel_trials: int [Default: 35.0]
#    stage_2_num_selected_trials: int [Default: 5.0]
#    stats_and_example_gen_dataflow_disk_size_gb: int [Default: 40.0]
#    stats_and_example_gen_dataflow_machine_type: str [Default: 'n1-standard-16']
#    stats_and_example_gen_dataflow_max_num_workers: int [Default: 25.0]
#    stratified_split_key: str [Default: '']
#    study_spec_parameters_override: list
#    target_column: str
#    test_fraction: float [Default: -1.0]
#    timestamp_split_key: str [Default: '']
#    train_budget_milli_node_hours: float
#    training_fraction: float [Default: -1.0]
#    transform_dataflow_disk_size_gb: int [Default: 40.0]
#    transform_dataflow_machine_type: str [Default: 'n1-standard-16']
#    transform_dataflow_max_num_workers: int [Default: 25.0]
#    transformations: str
#    validation_fraction: float [Default: -1.0]
#    vertex_dataset: system.Artifact
#    weight_column: str [Default: '']
    """

    pipeline_parameters['transformations'] = pipeline_parameters['transformations'].format(
        timestamp=datetime.now().strftime("%Y%m%d%H%M%S"))

    from google.cloud import bigquery
    from google.api_core import exceptions

    try:
        client = bigquery.Client()
        table = client.get_table(
            pipeline_parameters['data_source_bigquery_table_path'].split('/')[-1])
        schema = [schema.name for schema in table.schema]
    except exceptions.NotFound as e:
        logging.warn(f'Pipeline compiled without columns transformation. \
            Make sure the `data_source_bigquery_table_path` table or view exists in your config.yaml!')
        schema = []

    for column_to_remove in exclude_features + [
            pipeline_parameters['target_column'],
            pipeline_parameters['stratified_split_key'],
            pipeline_parameters['predefined_split_key'],
            pipeline_parameters['timestamp_split_key']
    ]:
        if column_to_remove in schema:
            schema.remove(column_to_remove)

    logging.info(f'features:{schema}'  )
    # need to remove later
    # if "default" in schema:
    #        schema.remove("default")

    write_auto_transformations(pipeline_parameters['transformations'], schema)
    if pipeline_parameters['predefined_split_key']:
        pipeline_parameters['training_fraction'] = None
        pipeline_parameters['validation_fraction'] = None
        pipeline_parameters['test_fraction'] = None

    # write_to_gcs(pipeline_parameters['transform_config_path'], json.dumps(transformations))

    (
        tp,
        parameter_values,
    ) = automl_tabular_utils.get_automl_tabular_pipeline_and_parameters(**pipeline_parameters)

    with open(pathlib.Path(__file__).parent.resolve().joinpath('automl_tabular_pl_v3.yaml'), 'r') as file:
        configuration = yaml.safe_load(file)

    # can process yaml to change pipeline name
    configuration['pipelineInfo']['name'] = pipeline_name

    _set_enable_caching_value(pipeline_spec=configuration,
                              enable_caching=enable_caching)

    # TODO: This params should be set in conf.yaml . However if i do so the validations in 
    # .get_automl_tabular_pipeline_and_parameters fail as this values are not
    # accepted in the given package. (I use a custom pipeline yaml instead of the one in 
    # the package and that causes the issue.)
    # ETA for a fix is 7th of Feb when a new aiplatform sdk will be released.
    parameter_values['model_display_name'] = "{}-model".format(pipeline_name)
    parameter_values['model_description'] = "{}-model".format(pipeline_name)

    # hydrate pipeline.yaml with parameters as default values
    for k, v in parameter_values.items():
        if k in configuration['root']['inputDefinitions']['parameters']:
            configuration['root']['inputDefinitions']['parameters'][k]['defaultValue'] = v
        else:
            raise Exception("parameter not found in pipeline definition: {}".format(k))

    with open(template_path, 'w') as yaml_file:
        yaml.dump(configuration, yaml_file)

    with open(parameters_path, 'w') as param_file:
        yaml.dump(parameter_values, param_file)

    # shutil.copy(pathlib.Path(__file__).parent.resolve().joinpath('automl_tabular_p_v2.yaml'), template_path)

    return template_path, parameter_values


def upload_pipeline_artefact_registry(
        template_path: str,
        project_id: str,
        region: str,
        repo_name: str,
        tags: list = None,
        description: str = None) -> str:

    host = f"https://{region}-kfp.pkg.dev/{project_id}/{repo_name}"
    client = RegistryClient(host=host)
    response = client.upload_pipeline(
        file_name=template_path,
        tags=tags,
        extra_headers={"description": description})
    logging.info(f"Pipeline uploaded : {host}")
    logging.info(response)
    return response[0]


def delete_pipeline_artefact_registry(
        project_id: str,
        region: str,
        repo_name: str,
        package_name: str) -> str:

    host = f"https://{region}-kfp.pkg.dev/{project_id}/{repo_name}"
    client = RegistryClient(host=host)
    response = client.delete_package(package_name=package_name)
    logging.info(f"Pipeline deleted : {package_name}")
    logging.info(response)
    return response


def get_gcp_bearer_token() -> str:
    # creds.valid is False, and creds.token is None
    # Need to refresh credentials to populate those
    creds, project = google.auth.default()
    creds.refresh(google.auth.transport.requests.Request())
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token


def schedule_pipeline(
        project_id: str,
        region: str,
        pipeline_name: str,
        pipeline_template_uri: str,
        pipeline_sa: str,
        pipeline_root: str,
        cron: str,
        max_concurrent_run_count: str,
        start_time: str = None,
        end_time: str = None) -> dict:

    url = f"https://{region}-aiplatform.googleapis.com/v1beta1/projects/{project_id}/locations/{region}/schedules"

    delete_schedules(project_id, region, pipeline_name)

    body = dict(
        display_name=f"{pipeline_name}",
        cron=cron,
        max_concurrent_run_count=max_concurrent_run_count,
        start_time=start_time,
        end_time=end_time,
        create_pipeline_job_request=dict(
            parent=f"projects/{project_id}/locations/{region}",
            pipelineJob=dict(
                displayName=f"{pipeline_name}",
                template_uri=pipeline_template_uri,
                service_account=pipeline_sa,
                runtimeConfig=dict(
                    gcsOutputDirectory=pipeline_root,
                    parameterValues=dict()
                )
            )
        )
    )

    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    resp = requests.post(url=url, json=body, headers=headers)
    data = resp.json()  # Check the JSON Response Content documentation below

    logging.info(f"scheduler for {pipeline_name} submitted")
    return data


def get_schedules(
        project_id: str,
        region: str,
        pipeline_name: str) -> list:

    filter = ""
    if pipeline_name is not None:
        filter = f"filter=display_name={pipeline_name}"
    url = f"https://{region}-aiplatform.googleapis.com/v1beta1/projects/{project_id}/locations/{region}/schedules?{filter}"

    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    resp = requests.get(url=url, headers=headers)
    data = resp.json()  # Check the JSON Response Content documentation below
    if "schedules" in data:
        return data['schedules']
    else:
        return None


def pause_schedule(
        project_id: str,
        region: str,
        pipeline_name: str) -> list:

    schedules = get_schedules(project_id, region, pipeline_name)
    if schedules is None:
        logging.info(f"No schedules found with display_name {pipeline_name}")
        return None

    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    paused_schedules = []
    for s in schedules:
        url = f"https://{region}-aiplatform.googleapis.com/v1beta1/{s['name']}:pause"
        resp = requests.post(url=url, headers=headers)

        data = resp.json()  # Check the JSON Response Content documentation below
        print(resp.status_code == 200)
        if resp.status_code != 200:
            raise Exception(
                f"Unable to pause resourse {s['name']}. request returned with status code {resp.status_code}")
        logging.info(f"scheduled resourse {s['name']} paused")
        paused_schedules.append(s['name'])

    return paused_schedules


def delete_schedules(
        project_id: str,
        region: str,
        pipeline_name: str) -> list:

    schedules = get_schedules(project_id, region, pipeline_name)
    if schedules is None:
        logging.info(f"No schedules found with display_name {pipeline_name}")
        return None

    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    deleted_schedules = []
    for s in schedules:
        url = f"https://{region}-aiplatform.googleapis.com/v1beta1/{s['name']}"
        resp = requests.delete(url=url, headers=headers)

        data = resp.json()  # Check the JSON Response Content documentation below
        logging.info(f"scheduled resourse {s['name']} deleted")
        deleted_schedules.append(s['name'])

    return deleted_schedules


def run_pipeline(
    pipeline_root: str,
    template_path: str,
    project_id: str,
    location: str,
    service_account: str,
    pipeline_parameters: Optional[Dict[str, Any]],
    pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
    enable_caching: bool = False,
    experiment_name: str = None,
    job_id: str = None,
    failure_policy: str = 'fast',
    labels: Optional[Dict[str, str]] = None,
    credentials: Optional[credentials.Credentials] = None,
    encryption_spec_key_name: Optional[str] = None,
    wait: bool = False,
) -> PipelineJob:

    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)
    
    logging.info(f"Pipeline parameters : {pipeline_parameters}")

    # Create Vertex Dataset
    #vertex_datasets_uri = create_dataset(
    #    display_name=pipeline_parameters['vertex_dataset_display_name'],
    #    bigquery_source=pipeline_parameters['data_source_bigquery_table_path'],
    #    project_id=pipeline_parameters['project'])
    #
    #input_artifacts: Dict[str, str] = {}
    #input_artifacts['vertex_datasets'] = vertex_datasets_uri

    pl = PipelineJob(
        display_name='na',  # not needed and will be optional in next major release
        template_path=template_path,
        job_id=job_id,
        pipeline_root=pipeline_root,
        enable_caching=enable_caching,
        project=project_id,
        location=location,
        parameter_values=pipeline_parameters,
        #input_artifacts=input_artifacts,
        encryption_spec_key_name=encryption_spec_key_name,
        credentials=credentials,
        failure_policy=failure_policy,
        labels=labels)

    pl.submit(service_account=service_account, experiment=experiment_name)
    if (wait):
        pl.wait()
        if (pl.has_failed):
            raise RuntimeError("Pipeline execution failed")
    return pl


#def create_dataset(
#    display_name: str,
#    bigquery_source: str,
#    project_id: str,
#    location: str = "us-central1",
#    credentials: Optional[credentials.Credentials] = None,
#    sync: bool = True,
#    create_request_timeout: Optional[float] = None,
#    ) -> str:
#    
#    #bigquery_source in this format "bq://<project_id>.purchase_propensity.v_purchase_propensity_training_30_15"
#    #dataset = TabularDataset.create(
#    #    display_name=display_name,
#    #    bq_source=[bigquery_source],
#    #    project=project_id,
#    #    location=location,
#    #    credentials=credentials,
#    #    sync=sync,
#    #    create_request_timeout=create_request_timeout)
#    #dataset.wait()
#
#    artifact = Artifact.create(
#        schema_title="system.Dataset",
#        uri=bigquery_source,
#        display_name=display_name,
#        project=project_id,
#        location=location,
#    )
#    artifact.wait()
#
#    # Should be: 7104764862735056896
#    # Cannot use full resource name of format: projects/294348452381/locations/us-central1/datasets/7104764862735056896
#    return artifact.resource_id
    