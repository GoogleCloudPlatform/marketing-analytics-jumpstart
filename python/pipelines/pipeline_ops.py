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
from os import name
from tracemalloc import start

import pip
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
    """
    This function substitutes placeholders in the pipeline_params dictionary with values from the pipeline_param_substitutions dictionary.

    Args:
        pipeline_params: A dictionary of pipeline parameters.
        pipeline_param_substitutions: A dictionary of substitutions to apply to the pipeline parameters.

    Returns:
        A dictionary of pipeline parameters with the substitutions applied.

    Raises:
        Exception: If a placeholder is not found in the pipeline_param_substitutions dictionary.
    """

    # if pipeline parameters include placeholders such as {PROJECT_ID} etc,
    # the following will replace such placeholder with the values
    # in the pipeline_param_substitutions dictionary
    ppp = pipeline_params.copy()
    for k, v in pipeline_params.items():
        if isinstance(v, str):
            ppp[k] = v.format(**pipeline_param_substitutions)
    return ppp


def get_bucket_name_and_path(uri):
    """
    This function takes a Google Cloud Storage URI and returns the bucket name and path.

    Args:
        uri: The Google Cloud Storage URI.

    Returns:
        A tuple containing the bucket name and path.

    Raises:
        ValueError: If the URI is not a valid Google Cloud Storage URI.
    """
    if not uri.startswith("gs://"):
        raise ValueError("URI must start with gs://")
    
    no_prefix_uri = uri[len("gs://"):]
    splits = no_prefix_uri.split("/")

    return splits[0], "/".join(splits[1:])


def write_to_gcs(uri: str, content: str):
    """
    Writes the given content to a Google Cloud Storage (GCS) bucket.

    Args:
        uri: The GCS URI of the file to write to.
        content: The content to write to the file.

    Raises:
        ValueError: If the URI is not a valid GCS URI.
    """

    bucket_name, path = get_bucket_name_and_path(uri)
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(path)
    blob.upload_from_string(content)


def generate_auto_transformation(column_names: List[str]) -> List[Dict[str, Any]]:
    """
    Generates a list of auto-transformation dictionaries for the given column names.

    Args:
        column_names: A list of column names.

    Returns:
        A list of auto-transformation dictionaries.

    Raises:
        ValueError: If the column_names list is empty.
    """
    if not column_names:
        raise ValueError("column_names must not be empty")

    transformations = []
    for column_name in column_names:
        transformations.append({"auto": {"column_name": column_name}})
    return transformations


def write_auto_transformations(uri: str, column_names: List[str]):
    """
    Generates a list of auto-transformation dictionaries for the given column names and writes them to a Google Cloud Storage (GCS) bucket.

    Args:
        uri: The GCS URI of the file to write to.
        column_names: A list of column names.

    Raises:
        ValueError: If the column_names list is empty.
    """

    if not column_names:
        raise ValueError("column_names must not be empty")

    transformations = generate_auto_transformation(column_names)
    write_to_gcs(uri, json.dumps(transformations))

    logging.info("Transformations config written: {}".format(uri))


def read_custom_transformation_file(custom_transformation_file: str):
    """
    Reads a custom transformation file and returns the transformations as a list of dictionaries.

    Args:
        custom_transformation_file: The path to the custom transformation file.

    Returns:
        A list of dictionaries representing the custom transformations.

    Raises:
        FileNotFoundError: If the custom transformation file does not exist.
        JSONDecodeError: If the custom transformation file is not valid JSON.
    """
    
    transformations = None
    try:
        with open(custom_transformation_file, "r") as f:
            transformations = json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(f"Custom transformation file not found: {custom_transformation_file}")
    except json.JSONDecodeError:
        raise json.JSONDecodeError(f"Invalid JSON in custom transformation file: {custom_transformation_file}")
    
    return transformations


def write_custom_transformations(uri: str, custom_transformation_file: str):
    """
    Writes custom transformation definitions to a Google Cloud Storage (GCS) bucket.

    Args:
        uri: The GCS URI of the file to write to.
        custom_transformation_file: The path to the custom transformation file.

    Raises:
        FileNotFoundError: If the custom transformation file does not exist.
        JSONDecodeError: If the custom transformation file is not valid JSON.
    """

    transformations = read_custom_transformation_file(custom_transformation_file)
    write_to_gcs(uri, json.dumps(transformations))

    logging.info("Transformations config written: {}".format(uri))

    return transformations


def compile_pipeline(
        pipeline_func: Callable, 
        template_path: str,
        pipeline_name: str,
        pipeline_parameters: Optional[Dict[str, Any]] = None,
        pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
        enable_caching: bool = True,
        type_check: bool = True) -> str:
    """
    Compiles a Vertex AI Pipeline.

    This function takes a pipeline function, a template path, a pipeline name, and optional pipeline parameters and substitutions, and compiles them into a Vertex AI Pipeline YAML file.

    Args:
        pipeline_func: The pipeline function to compile.
        template_path: The path to the pipeline template file.
        pipeline_name: The name of the pipeline.
        pipeline_parameters: The parameters to pass to the pipeline.
        pipeline_parameters_substitutions: A dictionary of substitutions to apply to the pipeline parameters.
        enable_caching: Whether to enable caching for the pipeline.
        type_check: Whether to perform type checking on the pipeline parameters.

    Returns:
        The path to the compiled pipeline YAML file.

    Raises:
        Exception: If an error occurs while compiling the pipeline.
    """

    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)
    logging.info("Pipeline parameters: {}".format(pipeline_parameters))

    #pipeline_parameters.pop('columns_to_skip', None) 

    # The function uses the compiler.Compiler() class to compile the pipeline defined by the pipeline_func function. 
    # The compiled pipeline is saved to the template_path file.
    compiler.Compiler().compile(
        pipeline_func=pipeline_func,
        package_path=template_path,
        pipeline_name=pipeline_name,
        pipeline_parameters=pipeline_parameters,
        type_check=type_check,
    )

    # The function opens the compiled pipeline template file and loads the configuration using the yaml.safe_load() function.
    with open(template_path, 'r') as file:
        configuration = yaml.safe_load(file)

    # The function sets the enable_caching value of the configuration to the enable_caching parameter.
    _set_enable_caching_value(pipeline_spec=configuration,
                              enable_caching=enable_caching)

    # Saves the updated pipeline configuration back to the template_path file.
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
    """
    Runs a Vertex AI Pipeline from a function.

    This function takes a pipeline function, a pipeline root directory, a project ID, a location, a service account, pipeline parameters, and optional parameters for pipeline parameter substitutions, caching, experiment name, job ID, labels, credentials, encryption key name, and waiting for completion. It creates a PipelineJob object from the pipeline function, submits the pipeline to Vertex AI, and optionally waits for the pipeline to complete.

    Args:
        pipeline_func: The pipeline function to run.
        pipeline_root: The root directory of the pipeline.
        project_id: The ID of the project that contains the pipeline.
        location: The location of the pipeline.
        service_account: The service account to use for the pipeline.
        pipeline_parameters: The parameters to pass to the pipeline.
        pipeline_parameters_substitutions: A dictionary of substitutions to apply to the pipeline parameters.
        enable_caching: Whether to enable caching for the pipeline.
        experiment_name: The name of the experiment to create for the pipeline.
        job_id: The ID of the pipeline job.
        labels: The labels to apply to the pipeline.
        credentials: The credentials to use for the pipeline.
        encryption_spec_key_name: The encryption key to use for the pipeline.
        wait: Whether to wait for the pipeline to complete.

    Returns:
        A PipelineJob object.

    Raises:
        RuntimeError: If the pipeline execution fails.
    """

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


def _extract_schema_from_bigquery(
        project: str,
        location: str,
        table_name: str,
        table_schema: str,
        ) -> list:
    """
    Extracts the schema from a BigQuery table or view.

    Args:
        project: The ID of the project that contains the table or view.
        location: The location of the table or view.
        table_name: The name of the table or view.
        table_schema: The path to the schema file.

    Returns:
        A list of the column names in the table or view.

    Raises:
        Exception: If the table or view does not exist.
    """

    from google.cloud import bigquery
    from google.api_core import exceptions
    try:
        client = bigquery.Client(
            project=project,
            #location=location,
        )
        table = client.get_table(table_name)
        schema = [schema.name for schema in table.schema]
    except exceptions.NotFound as e:
        logging.warn(f'Pipeline compiled without columns transformation. \
            Make sure the `data_source_bigquery_table_path` table or view exists! \
            Loading default values from schema file {table_schema}.')
        import json
        with open(table_schema) as f:
            d = json.load(f)
        schema = [feature['name'] for feature in d]
    return schema


def compile_automl_tabular_pipeline(
        template_path: str,
        parameters_path: str,
        pipeline_name: str,
        pipeline_parameters: Dict[str, Any] = None,
        pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
        exclude_features = List[Any],
        enable_caching: bool = True) -> tuple:
    """
    Compiles an AutoML Tabular Workflows pipeline. You don't need to define the pipeline elsewhere since the pre-compiled pipeline component is defined in the `automl_tabular_pl_v4.yaml` file.

    Args:
        template_path: The path to the pipeline template file.
        parameters_path: The path to the pipeline parameters file.
        pipeline_name: The name of the pipeline.
        pipeline_parameters: The parameters to pass to the pipeline. All these possible parameters can be set in the config.yaml.tftpl file, instead of in this file.
            additional_experiments: dict
            cv_trainer_worker_pool_specs_override: list
            data_source_bigquery_table_path: str [Default: '']
            data_source_csv_filenames: str [Default: '']
            dataflow_service_account: str [Default: '']
            dataflow_subnetwork: str [Default: '']
            dataflow_use_public_ips: bool [Default: True]
            disable_early_stopping: bool [Default: False]
            distill_batch_predict_machine_type: str [Default: 'n1-standard-16']
            distill_batch_predict_max_replica_count: int [Default: 25.0]
            distill_batch_predict_starting_replica_count: int [Default: 25.0]
            enable_probabilistic_inference: bool [Default: False]
            encryption_spec_key_name: str [Default: '']
            evaluation_batch_explain_machine_type: str [Default: 'n1-highmem-8']
            evaluation_batch_explain_max_replica_count: int [Default: 10.0]
            evaluation_batch_explain_starting_replica_count: int [Default: 10.0]
            evaluation_batch_predict_machine_type: str [Default: 'n1-highmem-8']
            evaluation_batch_predict_max_replica_count: int [Default: 20.0]
            evaluation_batch_predict_starting_replica_count: int [Default: 20.0]
            evaluation_dataflow_disk_size_gb: int [Default: 50.0]
            evaluation_dataflow_machine_type: str [Default: 'n1-standard-4']
            evaluation_dataflow_max_num_workers: int [Default: 100.0]
            evaluation_dataflow_starting_num_workers: int [Default: 10.0]
            export_additional_model_without_custom_ops: bool [Default: False]
            fast_testing: bool [Default: False]
            location: str
            model_description: str [Default: '']
            model_display_name: str [Default: '']
            optimization_objective: str
            optimization_objective_precision_value: float [Default: -1.0]
            optimization_objective_recall_value: float [Default: -1.0]
            predefined_split_key: str [Default: '']
            prediction_type: str
            project: str
            quantiles: list
            root_dir: str
            run_distillation: bool [Default: False]
            run_evaluation: bool [Default: False]
            stage_1_num_parallel_trials: int [Default: 35.0]
            stage_1_tuner_worker_pool_specs_override: list
            stage_1_tuning_result_artifact_uri: str [Default: '']
            stage_2_num_parallel_trials: int [Default: 35.0]
            stage_2_num_selected_trials: int [Default: 5.0]
            stats_and_example_gen_dataflow_disk_size_gb: int [Default: 40.0]
            stats_and_example_gen_dataflow_machine_type: str [Default: 'n1-standard-16']
            stats_and_example_gen_dataflow_max_num_workers: int [Default: 25.0]
            stratified_split_key: str [Default: '']
            study_spec_parameters_override: list
            target_column: str
            test_fraction: float [Default: -1.0]
            timestamp_split_key: str [Default: '']
            train_budget_milli_node_hours: float
            training_fraction: float [Default: -1.0]
            transform_dataflow_disk_size_gb: int [Default: 40.0]
            transform_dataflow_machine_type: str [Default: 'n1-standard-16']
            transform_dataflow_max_num_workers: int [Default: 25.0]
            transformations: str
            validation_fraction: float [Default: -1.0]
            vertex_dataset: system.Artifact
            weight_column: str [Default: '']
        pipeline_parameters_substitutions: A dictionary of substitutions to apply to the pipeline parameters.
        exclude_features: A list of features to exclude from the pipeline.
        enable_caching: Whether to enable caching for the pipeline.

    Returns:
        A tuple containing the path to the compiled pipeline template file and the pipeline parameters.
    """

    from google_cloud_pipeline_components.preview.automl.tabular import utils as automl_tabular_utils

    # This checks if there are any substitutions defined in the pipeline_parameters_substitutions dictionary. If so, it applies these substitutions to the pipeline_parameters dictionary. This allows for using placeholders in the pipeline parameters, making the pipeline more flexible and reusable.
    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)

    # This section handles the feature transformations for the pipeline. It checks if there is a 
    # custom_transformations file specified. If so, it reads the transformations from that file. 
    # Otherwise, it extracts the schema from the BigQuery table and generates automatic transformations based on the schema.
    pipeline_parameters['transformations'] = pipeline_parameters['transformations'].format(
        timestamp=datetime.now().strftime("%Y%m%d%H%M%S"))
    
    schema = {}

    if 'custom_transformations' in pipeline_parameters.keys():
        logging.info("Reading from custom features transformations file: {}".format(pipeline_parameters['custom_transformations']))
        schema = write_custom_transformations(pipeline_parameters['transformations'], 
                                      pipeline_parameters['custom_transformations'])
    else:
        schema = _extract_schema_from_bigquery(
            project=pipeline_parameters['project'],
            location=pipeline_parameters['location'],
            table_name=pipeline_parameters['data_source_bigquery_table_path'].split('/')[-1],
            table_schema=pipeline_parameters['data_source_bigquery_table_schema']
            )

        # If there is no features to exclude, skip the step of removing columns from the schema
        if exclude_features:
            for column_to_remove in exclude_features + [
                    pipeline_parameters['target_column'],
                    pipeline_parameters['stratified_split_key'],
                    pipeline_parameters['predefined_split_key'],
                    pipeline_parameters['timestamp_split_key']
            ]:
                if column_to_remove in schema:
                    schema.remove(column_to_remove)

        logging.info("Writing automatically generated features transformations file: {}".format(pipeline_parameters['transformations']))
        write_auto_transformations(pipeline_parameters['transformations'], schema)
    
    logging.info(f'features:{schema}')

    # This section compiles the AutoML Tabular Workflows pipeline. It uses the automl_tabular_utils module to 
    # generate the pipeline components and parameters. It then loads a pre-compiled pipeline template file 
    # (automl_tabular_pl_v4.yaml) and hydrates it with the generated parameters. Finally, it writes the 
    # compiled pipeline template and parameters to the specified files.
    if pipeline_parameters['predefined_split_key']:
        pipeline_parameters['training_fraction'] = None
        pipeline_parameters['validation_fraction'] = None
        pipeline_parameters['test_fraction'] = None

    pipeline_parameters.pop('data_source_bigquery_table_schema', None)
    pipeline_parameters.pop('custom_transformations', None) 
    
    (
        tp,
        parameter_values,
    ) = automl_tabular_utils.get_automl_tabular_feature_selection_pipeline_and_parameters(**pipeline_parameters) #automl_tabular_utils.get_automl_tabular_pipeline_and_parameters(**pipeline_parameters)

    with open(pathlib.Path(__file__).parent.resolve().joinpath('automl_tabular_pl_v4.yaml'), 'r') as file:
        configuration = yaml.safe_load(file)

    # can process yaml to change pipeline name
    configuration['pipelineInfo']['name'] = pipeline_name

    _set_enable_caching_value(pipeline_spec=configuration,
                              enable_caching=enable_caching)

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

    return template_path, parameter_values


# Function to upload the pipeline YAML files to gcs
def upload_pipeline_artefact_registry(
        template_path: str,
        project_id: str,
        region: str,
        repo_name: str,
        tags: list = None,
        description: str = None) -> str:
    """
    This function uploads a pipeline YAML file to the Artifact Registry.

    Args:
        template_path: The path to the pipeline YAML file.
        project_id: The ID of the project that contains the pipeline.
        region: The location of the pipeline.
        repo_name: The name of the repository to upload the pipeline to.
        tags: A list of tags to apply to the pipeline.
        description: A description of the pipeline.

    Returns:
        The name of the uploaded pipeline.

    Raises:
        Exception: If an error occurs while uploading the pipeline.
    """
    logging.info(f"Uploading pipeline to {region}-kfp.pkg.dev/{project_id}/{repo_name}")

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
    """
    This function deletes a pipeline from the Artifact Registry.

    Args:
        project_id: The ID of the project that contains the pipeline.
        region: The location of the pipeline.
        repo_name: The name of the repository that contains the pipeline.
        package_name: The name of the pipeline to delete.

    Returns:
        A string containing the response from the Artifact Registry.

    Raises:
        Exception: If an error occurs while deleting the pipeline.
    """

    host = f"https://{region}-kfp.pkg.dev/{project_id}/{repo_name}"
    client = RegistryClient(host=host)
    response = client.delete_package(package_name=package_name)
    logging.info(f"Pipeline deleted : {package_name}")
    logging.info(response)
    return response


def get_gcp_bearer_token() -> str:
    """
    Retrieves a bearer token for Google Cloud Platform (GCP) authentication.
    creds.valid is False, and creds.token is None
    Need to refresh credentials to populate those

    Returns:
        A string containing the bearer token.

    Raises:
        Exception: If an error occurs while retrieving the bearer token.
    """

    # Get the default credentials for the current environment.
    creds, project = google.auth.default()

    # Refresh the credentials to ensure they are valid.
    creds.refresh(google.auth.transport.requests.Request())

    # Extract the bearer token from the refreshed credentials.
    bearer_token = creds.token

    # Return the bearer token.
    return bearer_token


# Function to schedule the pipeline.
def schedule_pipeline(
        project_id: str,
        region: str,
        template_path: str,
        pipeline_name: str,
        pipeline_sa: str,
        pipeline_root: str,
        cron: str,
        max_concurrent_run_count: str,
        start_time: str,
        end_time: str,
        pipeline_parameters: Dict[str, Any] = None,
        pipeline_parameters_substitutions: Optional[Dict[str, Any]] = None,
    ) -> dict:
    """
    This function schedules a Vertex AI Pipeline to run on a regular basis.

    Args:
        project_id: The ID of the project that contains the pipeline.
        region: The location of the pipeline.
        pipeline_name: The name of the pipeline to schedule.
        pipeline_template_uri: The URI of the pipeline template file.
        pipeline_sa: The service account to use for the pipeline.
        pipeline_root: The root directory of the pipeline.
        cron: The cron expression that defines the schedule.
        max_concurrent_run_count: The maximum number of concurrent pipeline runs.
        start_time: The start time of the schedule.
        end_time: The end time of the schedule.

    Returns:
        A dictionary containing information about the scheduled pipeline.

    Raises:
        Exception: If an error occurs while scheduling the pipeline.
    """

    from google.cloud import aiplatform

    # Substitute pipeline parameters with necessary substitutions
    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)
    
    # Deletes scheduled queries with matching description
    delete_schedules(project_id, region, pipeline_name)

    # Create a PipelineJob object
    pipeline_job = aiplatform.PipelineJob(
        template_path=template_path,
        pipeline_root=pipeline_root,
        display_name=f"{pipeline_name}",
    )

    # Create the schedule with the pipeline job defined
    pipeline_job_schedule = pipeline_job.create_schedule(
        display_name=f"{pipeline_name}",
        cron=cron,
        max_concurrent_run_count=max_concurrent_run_count,
        start_time=start_time,
        end_time=end_time,
        service_account=pipeline_sa,
    )

    logging.info(f"Pipeline scheduled : {pipeline_name}")

    return pipeline_job


def get_schedules(
        project_id: str,
        region: str,
        pipeline_name: str) -> list:
    """
    This function retrieves all schedules associated with a given pipeline name in a specific project and region.

    Args:
        project_id: The ID of the project that contains the pipeline.
        region: The location of the pipeline.
        pipeline_name: The name of the pipeline to retrieve schedules for.

    Returns:
        A list of the schedules associated with the pipeline. If no schedules are found, returns None.

    Raises:
        Exception: If an error occurs while retrieving the schedules.
    """

    # Defines the filter query parameter for the URL request
    filter = ""
    if pipeline_name is not None:
        filter = f"filter=display_name={pipeline_name}"
    url = f"https://{region}-aiplatform.googleapis.com/v1beta1/projects/{project_id}/locations/{region}/schedules?{filter}"

    # Defines the header for the URL request
    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    # Make the request
    resp = requests.get(url=url, headers=headers)
    data = resp.json()  # Check the JSON Response Content 
    if "schedules" in data:
        return data['schedules']
    else:
        return None


def pause_schedule(
        project_id: str,
        region: str,
        pipeline_name: str) -> list:
    """
    This function pauses all schedules associated with a given pipeline name in a specific project and region.

    Args:
        project_id: The ID of the project that contains the pipeline.
        region: The location of the pipeline.
        pipeline_name: The name of the pipeline to pause schedules for.

    Returns:
        A list of the names of the paused schedules. If no schedules are found, returns None.
    
    Raises:
        Exception: If an error occurs while pausing the schedules.
    """

    # Get the list of schedules for the given pipeline name
    schedules = get_schedules(project_id, region, pipeline_name)
    if schedules is None:
        logging.info(f"No schedules found with display_name {pipeline_name}")
        return None

    # Creating the request header
    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    # Pause the schedules where the display_name matches
    paused_schedules = []
    for s in schedules:
        url = f"https://{region}-aiplatform.googleapis.com/v1beta1/{s['name']}:pause"
        resp = requests.post(url=url, headers=headers)

        data = resp.json()  # Check the JSON Response Content
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
    """
    This function deletes all schedules associated with a given pipeline name in a specific project and region.

    Args:
        project_id: The ID of the project that contains the pipeline.
        region: The location of the pipeline.
        pipeline_name: The name of the pipeline to delete schedules for.

    Returns:
        A list of the names of the deleted schedules. If no schedules are found, returns None.
    
    Raises:
        Exception: If an error occurs while deleting the schedules.
    """

    # Get all schedules for the given pipeline name
    schedules = get_schedules(project_id, region, pipeline_name)
    if schedules is None:
        logging.info(f"No schedules found with display_name {pipeline_name}")
        return None

    # Defines the header used in the API request
    headers = requests.structures.CaseInsensitiveDict()
    headers["Content-Type"] = "application/json"
    headers["Authorization"] = "Bearer {}".format(get_gcp_bearer_token())

    # Delete each schedule where the display_name matches
    deleted_schedules = []
    for s in schedules:
        url = f"https://{region}-aiplatform.googleapis.com/v1beta1/{s['name']}"
        resp = requests.delete(url=url, headers=headers)

        data = resp.json()  # Check the JSON Response Content
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
    
    """
    Runs a Vertex AI Pipeline.
    This function provides a convenient way to run a Vertex AI Pipeline. It takes care of creating the PipelineJob object, 
    submitting the pipeline, and waiting for completion (if desired). It also allows for substituting placeholders in the 
    pipeline parameters, making the pipeline more flexible and reusable.

    Args:
        pipeline_root: The root directory of the pipeline.
        template_path: The path to the pipeline template file.
        project_id: The ID of the project that contains the pipeline.
        location: The location of the pipeline.
        service_account: The service account to use for the pipeline.
        pipeline_parameters: The parameters to pass to the pipeline.
        pipeline_parameters_substitutions: A dictionary of substitutions to apply to the pipeline parameters.
        enable_caching: Whether to enable caching for the pipeline.
        experiment_name: The name of the experiment to create for the pipeline.
        job_id: The ID of the pipeline job.
        failure_policy: The failure policy for the pipeline.
        labels: The labels to apply to the pipeline.
        credentials: The credentials to use for the pipeline.
        encryption_spec_key_name: The encryption key to use for the pipeline.
        wait: Whether to wait for the pipeline to complete.

    Returns:
        A PipelineJob object.
    """

    # Substitute placeholders in the pipeline_parameters dictionary with values from the pipeline_parameters_substitutions dictionary. 
    # This is useful for making the pipeline more flexible and reusable, as the same pipeline can be used with different parameter 
    # values by simply providing a different pipeline_parameters_substitutions dictionary.
    if pipeline_parameters_substitutions != None:
        pipeline_parameters = substitute_pipeline_params(
            pipeline_parameters, pipeline_parameters_substitutions)
    
    logging.info(f"Pipeline parameters : {pipeline_parameters}")

    # Creates a PipelineJob object with the provided arguments.
    pl = PipelineJob(
        display_name='na',  # not needed and will be optional in next major release
        template_path=template_path,
        job_id=job_id,
        pipeline_root=pipeline_root,
        enable_caching=enable_caching,
        project=project_id,
        location=location,
        parameter_values=pipeline_parameters,
        encryption_spec_key_name=encryption_spec_key_name,
        credentials=credentials,
        failure_policy=failure_policy,
        labels=labels)

    # Submits the pipeline to Vertex AI 
    pl.submit(service_account=service_account, experiment=experiment_name)

    logging.info(f"Pipeline submitted")

    # Waits for the pipeline to complete.
    if (wait):
        pl.wait()
        if (pl.has_failed):
            raise RuntimeError("Pipeline execution failed")
    return pl
    