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
import os, logging, yaml, toml
from kfp.dsl import component, Output, Artifact, Model, Input, Metrics, ClassificationMetrics, Dataset
from ma_components.vertex import VertexModel


pyproject_toml_file_path = os.path.join(os.path.dirname(__file__), '../../../../pyproject.toml')
config_file_path = os.path.join(os.path.dirname(__file__), '../../../../config/config.yaml')

packages_to_install = [] 
if os.path.exists(pyproject_toml_file_path):
    dependencies = toml.load(pyproject_toml_file_path)['tool']['poetry']['group']['component_vertex']['dependencies']
    for k,v in dependencies.items():
        packages_to_install.append(f"{k}=={v}")

target_image=None
if os.path.exists(config_file_path):
    with open(config_file_path, encoding='utf-8') as fh:
            configs = yaml.full_load(fh)

    vertex_components_params = configs['vertex_ai']['components']
    repo_params = configs['artifact_registry']['pipelines_docker_repo']

    #target_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['image_name']}:{vertex_components_params['tag']}"
    base_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['base_image_name']}:{vertex_components_params['base_image_tag']}"




@component(
    base_image=base_image,
    #target_image=target_image,
    #packages_to_install=packages_to_install
)
def elect_best_tabular_model(
    project: str,
    location: str,
    display_name: str,
    metric_name: str,
    metric_threshold: float,
    number_of_models_considered: int,
    metrics_logger: Output[Metrics],
    classification_metrics_logger: Output[ClassificationMetrics],
    elected_model: Output[VertexModel]
) -> None:
    """Vertex pipelines component that elects the best model based on some 
    criteria such as metric, minimum accepted threshold and number of 
    last models to compare. The compoenent uses google-cloud-aiplatform Model.get_model_evaluation()
    to retrieve evaluation results. It compares against models with the same name or different versions within 
    the same model. For models with multiple versions, the best version becomes the default version.

    Args:
        project (str):
            Project to retrieve models and model registry from
        location (str):
            Location to retrieve models and model registry from
        display_name (str):
            The display name of the model for which selection is going to be made
        metric_name (str): 
            The name of the metic based on which the model will be evaluated
        metric_threshold (float): 
            The minimum or maximum (depended on metrci) accepted value of the selected metric. If the metric value is below or above this threashold, the model will not be selected. For logLoss this value should be max accepted logLoss. For auROC and auPR this value should be minumum accepted.
        number_of_models_considered (int):
            Defines the number of latest models to be considered for selection. If you always want the last model then this value should be 1
    Returns:
        

    Raises:
        ValueError: given metric_goal not a valid MetricGoal
        ValueError: Model evaluation metric {metric_name} of value {best_model[metric_name]} does not meet minumum criteria of threshold {metric_threshold}
    """
  
    from google.cloud import aiplatform as aip
    import logging
    from pprint import pformat
    from enum import Enum
    #from google_cloud_pipeline_components.types.artifact_types import VertexModel

    class MetricsEnum(Enum):
        # classification
        LOG_LOSS = 'logLoss'
        AU_ROC = 'auRoc'
        AU_PRC = 'auPrc'

        # regression
        MAE = 'meanAbsoluteError'
        MAPE = 'meanAbsolutePercentageError'
        RMSE = 'rootMeanSquaredError'
        RMSLE = 'rootMeanSquaredLogError'
        R2 = 'rSquared'

        def is_new_metric_better(self, new_value: float, old_value: float):
            return new_value<old_value if self.name in [MetricsEnum.LOG_LOSS.name, MetricsEnum.MAE.name, MetricsEnum.MAPE.name, MetricsEnum.RMSE.name, MetricsEnum.RMSLE.name] else new_value>old_value

        @classmethod
        def list(cls):
            return list(map(lambda c: c.value, cls))


    logging.info(display_name)
    aip.init(project=project, location=location)  
    models = aip.Model.list(filter=f'display_name="{display_name}"')
    
    models_versions_to_compare = []

    # find the X (number_of_models_considered) latest models based on created date of models and versions
    counter = 0
    for model in models:
        model_registry = aip.ModelRegistry(model=model.name)
        for v in model_registry.list_versions():
            if(counter<number_of_models_considered):
                models_versions_to_compare.append(v)
                counter+=1
            else:
                canditate_v = v
                for idx, mv in enumerate(models_versions_to_compare):
                    if canditate_v.version_create_time.timestamp() > mv.version_create_time.timestamp(): # checks if current canditate is newer than one already in list
                        tmp = mv
                        models_versions_to_compare[idx] = canditate_v
                        canditate_v = tmp
 
    if len(models_versions_to_compare)==0:
        raise Exception(f"No models in vertex model registry match '{display_name}'")

    
    
    best_model = dict()
    best_eval_metrics = dict()
    for model_version in models_versions_to_compare:
        logging.info(f"{model_version.model_resource_name} @ {model_version.version_id}")
        model = aip.Model(model_name=f"{model_version.model_resource_name}@{model_version.version_id}")
        evaluation = model.get_model_evaluation() # retruns data from latest evaluation job
        
        if (metric_name not in best_model) or MetricsEnum(metric_name).is_new_metric_better(evaluation.metrics[metric_name], best_model[metric_name]):
            best_eval_metrics = evaluation.metrics
            best_model[metric_name] = best_eval_metrics[metric_name]
            best_model["resource_name"] = model.resource_name
            best_model["display_name"] = model.display_name
            best_model["version"] = model.version_id
            logging.info(f"New Model/Version elected | name: {model.resource_name} | version {model.version_id} | metric name: {metric_name} | metric value: {best_eval_metrics[metric_name]} ")

    if MetricsEnum(metric_name).is_new_metric_better(metric_threshold, best_model[metric_name]):
        raise ValueError(f"Model evaluation metric {metric_name} of value {best_model[metric_name]} does not meet minumum criteria of threshold {metric_threshold}")
    
    #make the best version of the best model as default
    aip.ModelRegistry(model=best_model["resource_name"]).add_version_aliases(['default'], best_model["version"])
       
    #fpr_arr = []
    #tpr_arr = []
    #th_arr = []
    for k,v in best_eval_metrics.items():
        if k in MetricsEnum.list():
            logging.info(f"Metrics Logger: Model Evaluation Metric name {k} and value {v}")
            def _isnan(value):
                try:
                    import math
                    return math.isnan(float(value))
                except:
                    return False
            
            if _isnan(v):
                v = "0"
            metrics_logger.log_metric(k, v)

        
        elif k == 'confidenceMetrics':
            for confidence_metrics in v:
                if 'confidenceThreshold' in confidence_metrics :
                    if confidence_metrics['confidenceThreshold']>=0 and confidence_metrics['confidenceThreshold']<=1:
                        classification_metrics_logger.log_roc_data_point(
                            float(confidence_metrics['falsePositiveRate']) if 'falsePositiveRate' in confidence_metrics else 0,
                            float(confidence_metrics['recall']) if 'recall' in confidence_metrics else 0,
                            float(confidence_metrics['confidenceThreshold'])
                        )
                    if 'confusionMatrix' in confidence_metrics and (confidence_metrics['confidenceThreshold']>0.48 or confidence_metrics['confidenceThreshold']<0.52):
                        confusion_m = confidence_metrics['confusionMatrix']
                        classification_metrics_logger.log_confusion_matrix(
                            [v['displayName'] for v in confusion_m['annotationSpecs']], 
                            confusion_m['rows'])

                    #th_arr.append(float(confidence_metrics['confidenceThreshold']))
                    #fpr_arr.append(float(confidence_metrics['falsePositiveRate']) if 'falsePositiveRate' in confidence_metrics else 0)
                    #tpr_arr.append(float(confidence_metrics['recall']) if 'recall' in confidence_metrics else 0)

    #elected_model.name=best_model["display_name"]
  
    elected_model.uri = f"https://{location}-aiplatform.googleapis.com/v1/{best_model['resource_name']}/versions/{best_model['version']}"
    elected_model.metadata = {
        'resourceName': best_model["resource_name"],
        'version': best_model["version"],
        }

    elected_model.schema_title = 'google.VertexModel'
    #classification_metrics_logger.log_roc_curve(fpr_arr,tpr_arr, th_arr)



    
@component(
    base_image=base_image,
    #target_image=target_image,
    #packages_to_install=packages_to_install 
)
def get_latest_model(
    project: str,
    location: str,
    display_name: str,
    elected_model: Output[VertexModel]
) -> None:
    """Vertex pipelines component that elects the latest model based on the display name.

    Args:
        project (str):
            Project to retrieve models and model registry from
        location (str):
            Location to retrieve models and model registry from
        display_name (str):
            The display name of the model for which selection is going to be made
        elected_model: Output[VertexModel]:
            The output VertexModel object containing the latest model information.

    Raises:
        Exception: If no models are found in the vertex model registry that match the display name.
    """
  
    from google.cloud import aiplatform as aip
    import logging
    from pprint import pformat
    from enum import Enum
    #from google_cloud_pipeline_components.types.artifact_types import VertexModel

    class MetricsEnum(Enum):
        LOG_LOSS = 'logLoss'
        AU_ROC = 'auRoc'
        AU_PRC = 'auPrc'

        def is_new_metric_better(self, new_value: float, old_value: float):
            return new_value<old_value if self.name == MetricsEnum.LOG_LOSS.name else new_value>old_value

        @classmethod
        def list(cls):
            return list(map(lambda c: c.value, cls))

    number_of_models_considered: int = 1

    logging.info(display_name)
    aip.init(project=project, location=location)  
    models = aip.Model.list(filter=f'display_name="{display_name}"', order_by=f"create_time desc")
    
    models_versions_to_compare = []

    # find the X (number_of_models_considered) latest models based on created date of models and versions
    counter = 0
    for model in models:
        model_registry = aip.ModelRegistry(model=model.name)
        for v in model_registry.list_versions():
            if counter < number_of_models_considered:
                models_versions_to_compare.append(v)
                counter += 1
            else:
                canditate_v = v
                for idx, mv in enumerate(models_versions_to_compare):
                    if canditate_v.version_create_time.timestamp() > mv.version_create_time.timestamp(): # checks if current canditate is newer than one already in list
                        tmp = mv
                        models_versions_to_compare[idx] = canditate_v
                        canditate_v = tmp
 
    if len(models_versions_to_compare) == 0:
        raise Exception(f"No models in vertex model registry match '{display_name}'")

    model = models_versions_to_compare[0]

    logging.info(f"Selected model : {model}")

    aip.ModelRegistry(model=model.model_resource_name).add_version_aliases(['default'], model.version_id)


    elected_model.uri = f"https://{location}-aiplatform.googleapis.com/v1/{model.model_resource_name}/versions/{model.version_id}"
    elected_model.metadata = {
        'resourceName': model.model_resource_name,
        'version': model.version_id,
        }

    elected_model.schema_title = 'google.VertexModel'




@component(base_image=base_image)
def batch_prediction(
    destination_table: Output[Dataset],
    bigquery_source: str,
    bigquery_destination_prefix: str,
    job_name_prefix: str,
    model: Input[VertexModel],
    machine_type: str = "n1-standard-2",
    max_replica_count: int = 10,
    batch_size: int = 64,
    accelerator_count: int = 0,
    accelerator_type: str = None,
    generate_explanation: bool = False,
    dst_table_expiration_hours: int = 0
):
    """Vertex pipelines component that performs batch prediction using a Vertex AI model.

    Args:
        destination_table (Output[Dataset]):
            The output BigQuery table where the predictions will be stored.
        bigquery_source (str):
            The BigQuery table containing the data to be predicted.
        bigquery_destination_prefix (str):
            The BigQuery table prefix where the predictions will be stored.
        job_name_prefix (str):
            The prefix for the batch prediction job name.
        model (Input[VertexModel]):
            The Vertex AI model to be used for prediction.
        machine_type (str, optional):
            The machine type to use for the batch prediction job. Defaults to "n1-standard-2".
        max_replica_count (int, optional):
            The maximum number of replicas to use for the batch prediction job. Defaults to 10.
        batch_size (int, optional):
            The batch size to use for the batch prediction job. Defaults to 64.
        accelerator_count (int, optional):
            The number of accelerators to use for the batch prediction job. Defaults to 0.
        accelerator_type (str, optional):
            The type of accelerators to use for the batch prediction job. Defaults to None.
        generate_explanation (bool, optional):
            Whether to generate explanations for the predictions. Defaults to False.
        dst_table_expiration_hours (int, optional):
            The number of hours after which the destination table will expire. Defaults to 0.

    Raises:
        Exception: If the batch prediction job fails.
    """

    from datetime import datetime, timedelta, timezone
    import logging
    from google.cloud import bigquery
    from google.cloud.aiplatform import Model
    model = Model(f"{model.metadata['resourceName']}@{model.metadata['version']}")
    timestamp = str(int(datetime.now().timestamp()))

    batch_prediction_job = model.batch_predict(
        job_display_name=f"{job_name_prefix}-{timestamp}",
        instances_format="bigquery",
        predictions_format="bigquery",
        bigquery_source=f"bq://{bigquery_source}",
        bigquery_destination_prefix=f"bq://{bigquery_destination_prefix}",
        machine_type=machine_type,
        max_replica_count=max_replica_count,
        batch_size=batch_size,
        accelerator_count=accelerator_count,
        accelerator_type=accelerator_type,
        generate_explanation=generate_explanation
    )

    batch_prediction_job.wait()

    # Filling the destination_table with the bigquery destination table.
    destination_table.metadata["table_id"] = f"{batch_prediction_job.to_dict()['outputInfo']['bigqueryOutputDataset'].replace('bq://','')}.{batch_prediction_job.to_dict()['outputInfo']['bigqueryOutputTable']}"
    destination_table.metadata["predictions_column_prefix"] = "predicted_"
    destination_table.metadata["predictions_column"] = "prediction"
    destination_table.metadata["predictions_prob_column"] = "prediction_prob"

    if dst_table_expiration_hours > 0:
        client = bigquery.Client(project=model.project)
        table = client.get_table(destination_table.metadata["table_id"])
        expiration = datetime.now(timezone.utc) + timedelta(
            hours=dst_table_expiration_hours
        )
        table.expires = expiration
        client.update_table(table, ["expires"])

    logging.info(batch_prediction_job.to_dict())




@component(base_image=base_image)
# Note currently KFP SDK doesn't support outputting artifacts in `google` namespace.
# Use the base type dsl.Artifact instead.
def return_unmanaged_model(
    image_uri: str,
    bucket_name: str,
    model_name: str,
    model: Output[Artifact]
) -> None:
    """Vertex pipelines component that returns an unmanaged model artifact.

    Args:
        image_uri (str):
            The URI of the container image for the unmanaged model.
        bucket_name (str):
            The name of the Google Cloud Storage bucket where the unmanaged model is stored.
        model_name (str):
            The name of the unmanaged model file in the Google Cloud Storage bucket.
        model (Output[Artifact]):
            The output VertexModel artifact.

    Raises:
        Exception: If the model artifact cannot be created.
    """
    from google_cloud_pipeline_components import v1
    from google_cloud_pipeline_components.types import artifact_types
    from kfp import dsl

    model_uri = f"gs://{bucket_name}/{model_name}"
    model.metadata['containerSpec'] = {
        'imageUri':
            f"{image_uri}"
    }
    model.uri = model_uri
    


# Create tabular model explanation component
@component(base_image=base_image)
def get_tabular_model_explanation(
    project: str,
    location: str,
    model: Input[VertexModel],
    model_explanation: Output[Dataset],
) -> None:
    """Vertex pipelines component that retrieves tabular model explanations from the AutoML API.

    Args:
        project (str):
            Project to retrieve models and model registry from
        location (str):
            Location to retrieve models and model registry from
        model (Input[VertexModel]):
            The Vertex AI model for which explanations will be retrieved.
        model_explanation (Output[Dataset]):
            The output BigQuery dataset where the model explanations will be stored.

    Raises:
        Exception: If the model explanations cannot be retrieved.
    """
    from google.cloud import aiplatform
    import logging
    import re

    #Get explanaitions from the AutoML API
    aiplatform.init(project=project, location=location)
    model = aiplatform.Model(model.metadata["resourceName"]) # exmaple: 'projects/mde-aggregated-vbb/locations/us-central1/models/1391715638950494208' # replace with your model id
    model_evals = model.api_client.select_version('v1beta1').list_model_evaluations(parent=model.resource_name)

    #Get model id
    model_id = model.resource_name.split('/')[-1]

    #Get model name
    model_name = model.display_name

    #Get model version
    model_version = model.version_id
    logging.info(model_version)

    # convert the pager format into lists containing Json
    modelEvalJson= []
    for val in model_evals:
        #print(val.model_explanation)
        modelEvalJson.append(val.model_explanation)
    modelEvalJson = modelEvalJson[0] # keep only the json data

    # Filter the API response pager to keep only keys as feature_name and values as the coefficients
    # Extract values using regular expressions in 2 lists
    feature_names = re.findall(r'(?<=key: ").*?(?=")', str(modelEvalJson))
    values = re.findall(r"(?<=number_value: )[0-9]+\.[0-9]+", str(modelEvalJson))

    #DEBUG PRINT: print the extracted feature names and values
    logging.info(feature_names)
    logging.info(values)

    # Format data as rows for BigQuery insertion
    rows_to_insert = [
        dict(zip(['feature_names', 'values'], row))
        for row in zip(feature_names, values)
    ]

    # Component output
    model_explanation.metadata = {
        'model_id': model_id,
        'model_name': model_name,
        'model_version': model_version,
        'model_uri': f"https://{location}-aiplatform.googleapis.com/v1/{model.resource_name}/versions/{model.version_id}",
        'feature_names': feature_names,
        'values': values,
        }

