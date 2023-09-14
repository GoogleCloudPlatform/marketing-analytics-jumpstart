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

@component(base_image=base_image)
def get_latest_model_simple(
    project: str,
    location: str,
    model_name: str,
    model: Output[VertexModel]
) -> None:

    import google.cloud.aiplatform as aiplatform
    aiplatform.init(project=project, location=location)

    models = aiplatform.Model.list(filter=f"display_name={model_name}", order_by=f"create_time desc")
    if models:
        m = models[0]
        model.uri = f"https://{location}-aiplatform.googleapis.com/v1/{m.resource_name}/versions/{m.version_id}"
        model.metadata = {
            'resourceName': m.resource_name,
            'version': m.version_id,
        }
        model.schema_title = 'google.VertexModel'

    else:
        raise Exception(f'Model name [{model_name}] not found!')

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
    """
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

    number_of_models_considered: int= 1

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

    model= models_versions_to_compare[0]

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
        bigquery_destination_prefix=f"bq://{bigquery_destination_prefix}_{timestamp}",
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
    destination_table.metadata["predictions_column"] = "prediction"

    if dst_table_expiration_hours > 0:
        client = bigquery.Client(project=model.project)
        table = client.get_table(destination_table.metadata["table_id"])
        expiration = datetime.now(timezone.utc) + timedelta(
            hours=dst_table_expiration_hours
        )
        table.expires = expiration
        client.update_table(table, ["expires"])

    logging.info(batch_prediction_job.to_dict())
    