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

from typing import Callable
import pytest
import os
from pytest_mock import MockerFixture
from pipelines.tabular_pipelines import prediction_binary_classification_pl, prediction_regression_pl
import pipelines.pipeline_ops as pl_ops
import inspect
import logging
from datetime import datetime
import yaml

artifacts_path = os.path.join(os.path.dirname(__file__), './artifacts/')


@pytest.fixture(scope="session", autouse=True)
def test_setup():
    # SETUP

    if not os.path.exists(artifacts_path):
        os.makedirs(artifacts_path)

    yield "testing..."

    # TEARDOWN
    # try:
    #    shutil.rmtree(artifacts_path)
    # except OSError as e:
    #    print("Error: %s - %s." % (e.filename, e.strerror))


# ------------------------------------------------------------------------------------------------------------------------

@pytest.mark.unit
@pytest.mark.training_pl
def test_compile_propensity_training_pl(variables):

    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['training']
    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    template_path, params = pl_ops.compile_automl_tabular_pipeline(
        template_path=template_path,
        parameters_path=parameters_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'],
        exclude_features=my_pipeline_vars['exclude_features'])

    with open(template_path, encoding='utf-8') as fh:
        data = yaml.full_load(fh)

    assert (isinstance(data, dict))


@pytest.mark.inte
@pytest.mark.training_pl
@pytest.mark.pipeline_run
def test_run_propensity_training_pl(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    timestamp = str(int(datetime.now().timestamp()))
    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['training']

    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    template_path, params = pl_ops.compile_automl_tabular_pipeline(
        template_path=template_path,
        parameters_path=parameters_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'],
        exclude_features=my_pipeline_vars['exclude_features'])

    import pprint
    import json
    pp = pprint.PrettyPrinter(indent=4)
    pp.pprint(params)
    print(json.dumps(params))

    pl_ops.run_pipeline(
        job_id='{}{}-{}'.format(my_pipeline_vars['job_id_prefix'],
                                inspect.currentframe().f_code.co_name.replace("_", "-"), timestamp),
        project_id=generic_pipeline_vars['project_id'],
        pipeline_root=generic_pipeline_vars['root_path'],
        template_path=template_path,
        location=generic_pipeline_vars['region'],
        service_account=generic_pipeline_vars['service_account'],
        pipeline_parameters=None,
        pipeline_parameters_substitutions=None,
        enable_caching=True,
        wait=True,
        experiment_name=my_pipeline_vars['experiment_name']
    )


@pytest.mark.unit
@pytest.mark.training_pl
def test_compile_clv_training_pl(variables):

    my_pipeline_vars = variables['vertex_ai']['pipelines']['clv']['training']
    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    template_path, params = pl_ops.compile_automl_tabular_pipeline(
        template_path=template_path,
        parameters_path=parameters_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'],
        exclude_features=my_pipeline_vars['exclude_features'])

    with open(template_path, encoding='utf-8') as fh:
        data = yaml.full_load(fh)

    assert (isinstance(data, dict))


@pytest.mark.inte
@pytest.mark.training_pl
@pytest.mark.pipeline_run
def test_run_clv_training_pl(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    timestamp = str(int(datetime.now().timestamp()))
    my_pipeline_vars = variables['vertex_ai']['pipelines']['clv']['training']

    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    template_path, params = pl_ops.compile_automl_tabular_pipeline(
        template_path=template_path,
        parameters_path=parameters_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'],
        exclude_features=my_pipeline_vars['exclude_features'])

    import pprint
    import json
    pp = pprint.PrettyPrinter(indent=4)
    pp.pprint(params)
    print(json.dumps(params))

    pl_ops.run_pipeline(
        job_id='{}{}-{}'.format(my_pipeline_vars['job_id_prefix'],
                                inspect.currentframe().f_code.co_name.replace("_", "-"), timestamp),
        project_id=generic_pipeline_vars['project_id'],
        pipeline_root=generic_pipeline_vars['root_path'],
        template_path=template_path,
        location=generic_pipeline_vars['region'],
        service_account=generic_pipeline_vars['service_account'],
        pipeline_parameters=None,
        pipeline_parameters_substitutions=None,
        enable_caching=True,
        wait=True,
        experiment_name=my_pipeline_vars['experiment_name']
    )


def compile_tabular_pl(template_path: str, my_pipeline_vars: dict, pipeline_func: Callable):
    pl_ops.compile_pipeline(
        pipeline_func=pipeline_func,
        template_path=template_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'])

    with open(template_path, encoding='utf-8') as fh:
            data = yaml.full_load(fh)

    assert (isinstance(data, dict))


@pytest.mark.unit
@pytest.mark.prediction_pl
def test_compile_propensity_pred_pl(variables):

    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['prediction']
    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    compile_tabular_pl(template_path, my_pipeline_vars, prediction_binary_classification_pl )


@pytest.mark.unit
@pytest.mark.prediction_pl
def test_compile_clv_pred_pl(variables):

    my_pipeline_vars = variables['vertex_ai']['pipelines']['clv']['prediction']
    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    compile_tabular_pl(template_path, my_pipeline_vars, prediction_regression_pl)


def run_tabular_prediction_pl(generic_pipeline_vars: dict, my_pipeline_vars: dict, pipeline_func: Callable):
    timestamp = str(int(datetime.now().timestamp()))

    template_path = os.path.join(
        artifacts_path+'{}.yaml'.format(inspect.currentframe().f_code.co_name))
    pl_ops.compile_pipeline(
        pipeline_func=pipeline_func,
        template_path=template_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'])

    logging.info(my_pipeline_vars['pipeline_parameters'])

    pl_ops.run_pipeline(
        job_id='{}{}-{}'.format(my_pipeline_vars['job_id_prefix'],
                                inspect.currentframe().f_code.co_name.replace("_", "-"), timestamp),
        project_id=generic_pipeline_vars['project_id'],
        pipeline_root=generic_pipeline_vars['root_path'],
        template_path=template_path,
        location=generic_pipeline_vars['region'],
        service_account=generic_pipeline_vars['service_account'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'],
        enable_caching=True,
        wait=True,
        experiment_name=my_pipeline_vars['experiment_name']
    )


@pytest.mark.inte
@pytest.mark.prediction_pl
@pytest.mark.pipeline_run
@pytest.mark.current
def test_run_propensity_pred_pl(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['propensity']['prediction']
    run_tabular_prediction_pl(generic_pipeline_vars, my_pipeline_vars, prediction_binary_classification_pl)


@pytest.mark.inte
@pytest.mark.clv_pl
@pytest.mark.pipeline_run
def test_run_clv_pred_pl(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['clv']['prediction']
    run_tabular_prediction_pl(generic_pipeline_vars, my_pipeline_vars, prediction_regression_pl)
