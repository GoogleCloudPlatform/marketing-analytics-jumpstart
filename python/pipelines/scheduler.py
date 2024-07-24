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

import logging
import os
from argparse import ArgumentParser, ArgumentTypeError

import yaml

from pipelines.pipeline_ops import pause_schedule, schedule_pipeline, delete_schedules

# Ensures that the provided file path is a valid YAML file.
def check_extention(file_path: str, type: str = '.yaml'):
    if os.path.exists(file_path):
        if not file_path.lower().endswith(type):
            raise ArgumentTypeError(f"File provited must be {type}: {file_path}")
    else:
        raise FileNotFoundError(f"{file_path} does not exist")
    return file_path

# config path : pipeline module and function name
pipelines_list = {
    'vertex_ai.pipelines.feature-creation-auto-audience-segmentation.execution': "pipelines.feature_engineering_pipelines.auto_audience_segmentation_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-aggregated-value-based-bidding.execution': "pipelines.feature_engineering_pipelines.aggregated_value_based_bidding_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-audience-segmentation.execution': "pipelines.feature_engineering_pipelines.audience_segmentation_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-purchase-propensity.execution': "pipelines.feature_engineering_pipelines.purchase_propensity_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-churn-propensity.execution': "pipelines.feature_engineering_pipelines.churn_propensity_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-customer-ltv.execution': "pipelines.feature_engineering_pipelines.customer_lifetime_value_feature_engineering_pipeline",
    'vertex_ai.pipelines.purchase_propensity.training': None,  # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.purchase_propensity.prediction': "pipelines.tabular_pipelines.prediction_binary_classification_pl",
    'vertex_ai.pipelines.churn_propensity.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.churn_propensity.prediction': "pipelines.tabular_pipelines.prediction_binary_classification_pl",
    'vertex_ai.pipelines.segmentation.training': "pipelines.segmentation_pipelines.training_pl",
    'vertex_ai.pipelines.segmentation.prediction': "pipelines.segmentation_pipelines.prediction_pl",
    'vertex_ai.pipelines.auto_segmentation.training': "pipelines.auto_segmentation_pipelines.training_pl",
    'vertex_ai.pipelines.auto_segmentation.prediction': "pipelines.auto_segmentation_pipelines.prediction_pl",
    'vertex_ai.pipelines.propensity_clv.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.clv.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.clv.prediction':  "pipelines.tabular_pipelines.prediction_binary_classification_regression_pl",
    'vertex_ai.pipelines.value_based_bidding.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.value_based_bidding.explanation': "pipelines.tabular_pipelines.explanation_tabular_workflow_regression_pl",
    'vertex_ai.pipelines.reporting_preparation.execution': "pipelines.feature_engineering_pipelines.reporting_preparation_pl",
    'vertex_ai.pipelines.gemini_insights.execution': "pipelines.feature_engineering_pipelines.gemini_insights_pl",
} # key should match pipeline names as in the config.yaml files for automatic compilation

if __name__ == "__main__":
    """
    This Python code defines a script for scheduling and deleting Vertex AI pipelines. It uses the pipelines_list dictionary 
    to map pipeline names to their corresponding module and function names. this script provides a convenient way to schedule 
    and delete Vertex AI pipelines schedules from the command line. 
    The script takes the following arguments:
        -c: Path to the configuration YAML file.
        -p: Pipeline key name as it is in the config.yaml file.
        -i: The compiled pipeline input filename.
        -d: (Optional) Flag to delete the scheduled pipeline.
    """
    logging.basicConfig(level=logging.INFO)
    
    parser = ArgumentParser()

    parser.add_argument("-c", "--config-file",
                        dest="config",
                        required=True,
                        help="path to config YAML file (config.yaml)")

    parser.add_argument("-p", '--pipeline-config-name',
                        dest="pipeline",
                        required=True,
                        choices=list(pipelines_list.keys()),
                        help='Pipeline key name as it is in config.yaml')
    
    parser.add_argument("-i", '--input-file',
                    dest="input",
                    required=True,
                    help='the compiled pipeline input filename')
    
    parser.add_argument("-d", '--delete',
                        dest="delete",
                        required=False,
                        action='store_true',
                        help='if flag is set- delete scheduled pipeline')

    args = parser.parse_args()


    # Reads the configuration YAML file and extracts the relevant parameters for the pipeline 
    # and the artifact registry. It then checks if the pipeline name is valid and retrieves 
    # the corresponding module and function name from the pipelines_list dictionary.
    repo_params = {}
    with open(args.config, encoding='utf-8') as fh:
        params = yaml.full_load(fh)

    repo_params = params['artifact_registry']['pipelines_repo']
    generic_pipeline_vars = params['vertex_ai']['pipelines']

    my_pipeline_vars=params
    with open(args.config, encoding='utf-8') as fh:
        for i in args.pipeline.split('.'):
            my_pipeline_vars = my_pipeline_vars[i]

    if my_pipeline_vars['name'] is None:
        raise Exception("No pipeline display_name provided for deleting schedules.")

    template_artifact_uri = f"https://{repo_params['region']}-kfp.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{my_pipeline_vars['name']}/latest"

    if args.delete:
        # If the -d flag is set, the script calls the delete_schedules function to delete the 
        # scheduled pipeline.
        logging.info(f"Deleting scheduler for {args.pipeline}")
        delete_schedules(project_id=generic_pipeline_vars['project_id'],
                        region=generic_pipeline_vars['region'],
                        pipeline_name=my_pipeline_vars['name'])
    else:
        logging.info(f"Creating scheduler for {args.pipeline}")
        # Creates a new schedule for the pipeline and returns the schedule object. 
        # If the schedule is successfully created, the script checks if the pipeline is supposed 
        # to be paused and calls the pause_schedule function to pause it.
        schedule = schedule_pipeline(
                    project_id=generic_pipeline_vars['project_id'],
                    region=generic_pipeline_vars['region'],
                    template_path = args.input,
                    pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
                    pipeline_parameters_substitutions= my_pipeline_vars['pipeline_parameters_substitutions'],
                    pipeline_sa=generic_pipeline_vars['service_account'],
                    pipeline_name=my_pipeline_vars['name'],
                    pipeline_root=generic_pipeline_vars['root_path'],
                    cron=my_pipeline_vars['schedule']['cron'],
                    max_concurrent_run_count=my_pipeline_vars['schedule']['max_concurrent_run_count'],
                    start_time=my_pipeline_vars['schedule']['start_time'],
                    end_time=my_pipeline_vars['schedule']['end_time']
        )

        if my_pipeline_vars['schedule']['state'] == 'PAUSED':
            logging.info(f"Pausing scheduler for {args.pipeline}")
            pause_schedule(
                project_id=generic_pipeline_vars['project_id'],
                region=generic_pipeline_vars['region'],
                pipeline_name=my_pipeline_vars['name'])
