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

import importlib, yaml, logging
from pipelines.pipeline_ops import compile_pipeline, compile_automl_tabular_pipeline

from argparse import ArgumentParser
'''
example:
python -m pipelines.compiler -c ../config/conf.yaml -p train_pipeline -o my_comp_pl.yaml
'''

# config path : pipeline module and function name
pipelines_list = {
    'vertex_ai.pipelines.feature-creation-auto-audience-segmentation.execution': "pipelines.feature_engineering_pipelines.auto_audience_segmentation_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-audience-segmentation.execution': "pipelines.feature_engineering_pipelines.audience_segmentation_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-purchase-propensity.execution': "pipelines.feature_engineering_pipelines.purchase_propensity_feature_engineering_pipeline",
    'vertex_ai.pipelines.feature-creation-customer-ltv.execution': "pipelines.feature_engineering_pipelines.customer_lifetime_value_feature_engineering_pipeline",
    'vertex_ai.pipelines.auto_segmentation.training': "pipelines.auto_segmentation_pipelines.training_pl",
    'vertex_ai.pipelines.auto_segmentation.prediction': "pipelines.auto_segmentation_pipelines.prediction_pl",
    'vertex_ai.pipelines.segmentation.training': "pipelines.segmentation_pipelines.training_pl",
    'vertex_ai.pipelines.segmentation.prediction': "pipelines.segmentation_pipelines.prediction_pl",
    'vertex_ai.pipelines.propensity.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.propensity.prediction': "pipelines.tabular_pipelines.prediction_binary_classification_pl",
    'vertex_ai.pipelines.propensity_clv.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.clv.training': None, # tabular workflows pipelines is precompiled
    'vertex_ai.pipelines.clv.prediction':  "pipelines.tabular_pipelines.prediction_binary_classification_regression_pl",
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


    parser.add_argument("-o", '--output-file',
                    dest="output",
                    required=True,
                    help='the compiled pipeline output filename')

    args = parser.parse_args()

   

    pipeline_params={}
    with open(args.config, encoding='utf-8') as fh:
        pipeline_params = yaml.full_load(fh)
        for i in args.pipeline.split('.'):
            print(i)
            pipeline_params = pipeline_params[i]

    logging.info(pipeline_params)
    
    if pipeline_params['type'] == 'tabular-workflows':
        compile_automl_tabular_pipeline(
            template_path = args.output,
            parameters_path="params.yaml", 
            pipeline_name=pipeline_params['name'],
            pipeline_parameters=pipeline_params['pipeline_parameters'],
            pipeline_parameters_substitutions= pipeline_params['pipeline_parameters_substitutions'],
            exclude_features = pipeline_params['exclude_features'],
            enable_caching=False,
            )
    else:    
        module_name = '.'.join(pipelines_list[args.pipeline].split('.')[:-1])
        function_name = pipelines_list[args.pipeline].split('.')[-1]
        compile_pipeline(
            pipeline_func = getattr(importlib.import_module(module_name),function_name),
            template_path = args.output,
            pipeline_name = pipeline_params['name'],
            pipeline_parameters = pipeline_params['pipeline_parameters'],
            pipeline_parameters_substitutions = pipeline_params['pipeline_parameters_substitutions'],
            enable_caching=False,
            type_check=False,
        )