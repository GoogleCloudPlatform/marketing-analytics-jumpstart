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
    'vertex_ai.pipelines.feature-creation-customer-ltv.execution': "pipelines.feature_engineering_pipelines.customer_lifetime_value_feature_engineering_pipeline",
    'vertex_ai.pipelines.propensity.training': None,  # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.propensity.prediction': "pipelines.tabular_pipelines.prediction_binary_classification_pl",
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
} # key should match pipeline names as in the config.yaml files for automatic compilation

if __name__ == "__main__":
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
        logging.info(f"Deleting scheduler for {args.pipeline}")
        delete_schedules(project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=my_pipeline_vars['name'])
    else:
        logging.info(f"Creating scheduler for {args.pipeline}")
        schedule = schedule_pipeline(
            project_id=generic_pipeline_vars['project_id'],
            region=generic_pipeline_vars['region'],
            template_path = args.input,
            pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
            pipeline_parameters_substitutions= my_pipeline_vars['pipeline_parameters_substitutions'],
            pipeline_name=my_pipeline_vars['name'],
            pipeline_template_uri=template_artifact_uri,
            pipeline_sa=generic_pipeline_vars['service_account'],
            pipeline_root=generic_pipeline_vars['root_path'],
            cron=my_pipeline_vars['schedule']['cron'],
            max_concurrent_run_count=my_pipeline_vars['schedule']['max_concurrent_run_count'],
            start_time=my_pipeline_vars['schedule']['start_time'],
            end_time=my_pipeline_vars['schedule']['end_time']
        )

        #if schedule is None or schedule.state != 'ACTIVE':
        #    raise Exception(f"Scheduling pipeline failed {schedule}")

        if my_pipeline_vars['schedule']['state'] == 'PAUSED':
            logging.info(f"Pausing scheduler for {args.pipeline}")
            pause_schedule(
                project_id=generic_pipeline_vars['project_id'],
                region=generic_pipeline_vars['region'],
                pipeline_name=my_pipeline_vars['name'])
