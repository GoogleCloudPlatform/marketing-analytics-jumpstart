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

import pytest
import os
from pytest_mock import MockerFixture
import pipelines.pipeline_ops as pl_ops
from pipelines.feature_engineering_pipelines import pipeline
import inspect
import logging
import shutil
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
@pytest.mark.feature_eng_pl
def test_compile_fe_pl(variables):

    my_pipeline_vars = variables['vertex_ai']['pipelines']['feature-creation']['execution']
    template_path = os.path.join(
        artifacts_path+'{}_pipeline.yaml'.format(inspect.currentframe().f_code.co_name))
    parameters_path = os.path.join(
        artifacts_path+'{}_parameters.yaml'.format(inspect.currentframe().f_code.co_name))

    pl_ops.compile_pipeline(
        pipeline_func=pipeline,
        template_path=template_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'])

    with open(template_path, encoding='utf-8') as fh:
        data = yaml.full_load(fh)

    assert (isinstance(data, dict))


@pytest.mark.inte
@pytest.mark.feature_eng_pl
@pytest.mark.pipeline_run
def test_run_fe_pl(variables):
    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['feature-creation']['execution']
    timestamp = str(int(datetime.now().timestamp()))

    template_path = os.path.join(
        artifacts_path+'{}.yaml'.format(inspect.currentframe().f_code.co_name))

    pl_ops.compile_pipeline(
        pipeline_func=pipeline,
        template_path=template_path,
        pipeline_name=my_pipeline_vars['name'],
        pipeline_parameters=my_pipeline_vars['pipeline_parameters'],
        pipeline_parameters_substitutions=my_pipeline_vars['pipeline_parameters_substitutions'])

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
        enable_caching=False,
        wait=True,
        experiment_name=my_pipeline_vars['experiment_name']
    )


@pytest.mark.inte
@pytest.mark.feature_eng_pl
def test_scheduler(variables):
    artifact_registry = variables['artifact_registry']['pipelines_repo']
    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['feature-creation']['execution']

    template_artifact_uri = f"https://{artifact_registry['region']}-kfp.pkg.dev/{artifact_registry['project_id']}/{artifact_registry['name']}/{my_pipeline_vars['name']}/latest"
    pl_ops.schedule_pipeline(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=my_pipeline_vars['name'],
        pipeline_template_uri=template_artifact_uri,
        pipeline_sa=generic_pipeline_vars['service_account'],
        pipeline_root=generic_pipeline_vars['root_path'],
        cron=my_pipeline_vars['schedule']['cron'],
        max_concurrent_run_count=my_pipeline_vars['schedule']['max_concurrent_run_count'],
        start_time=my_pipeline_vars['schedule']['start_time'],
        end_time=my_pipeline_vars['schedule']['end_time']
    )

    deleted_schedules = pl_ops.delete_schedules(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=my_pipeline_vars['name']
    )
    assert (len(deleted_schedules) == 1)
