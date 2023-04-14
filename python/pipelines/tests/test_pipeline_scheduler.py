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
import inspect
import logging
import shutil
from datetime import datetime
import yaml

artifacts_path = os.path.join(os.path.dirname(__file__), './artifacts/')

data_path = os.path.join(os.path.dirname(__file__), './test_data/')
test_pipeline_file = os.path.join(data_path+'hello_world.yaml')


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

@pytest.mark.inte
@pytest.mark.schedule
def test_scheduler(variables):

    generic_pipeline_vars = variables['vertex_ai']['pipelines']
    my_pipeline_vars = variables['vertex_ai']['pipelines']['feature-creation']['execution']
    artifact_registry = variables['artifact_registry']['pipelines_repo']

    template_artifact_uri = f"https://{artifact_registry['region']}-kfp.pkg.dev/{artifact_registry['project_id']}/{artifact_registry['name']}/{my_pipeline_vars['name']}/latest"

    with open(test_pipeline_file, 'r') as file:
        pl_conf = yaml.safe_load(file)

    pl_name = pl_ops.upload_pipeline_artefact_registry(template_path=test_pipeline_file,
                                                       project_id=artifact_registry['project_id'],
                                                       region=artifact_registry['region'],
                                                       repo_name=artifact_registry['name'],
                                                       tags=['latest'],
                                                       description=None)
    assert (pl_name == pl_conf['pipelineInfo']['name'])

    for i in range(0, 2):
        schedule = pl_ops.schedule_pipeline(
            project_id=generic_pipeline_vars['project_id'],
            region=generic_pipeline_vars['region'],
            pipeline_name=pl_name,
            pipeline_template_uri=template_artifact_uri,
            pipeline_sa=generic_pipeline_vars['service_account'],
            pipeline_root=generic_pipeline_vars['root_path'],
            cron=my_pipeline_vars['schedule']['cron'],
            max_concurrent_run_count=my_pipeline_vars['schedule']['max_concurrent_run_count'],
            start_time=my_pipeline_vars['schedule']['start_time'],
            end_time=my_pipeline_vars['schedule']['end_time']
        )
        assert (schedule['state'] == 'ACTIVE')

    s = pl_ops.get_schedules(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=pl_name,
    )
    assert (len(s) == 1)

    pl_ops.pause_schedule(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=pl_name)
    s = pl_ops.get_schedules(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=pl_name,
    )
    logging.info(s)
    assert (s[0]['state'] == 'PAUSED')

    deleted_schedules = pl_ops.delete_schedules(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=pl_name,
    )
    assert (len(deleted_schedules) == 1)

    s = pl_ops.get_schedules(
        project_id=generic_pipeline_vars['project_id'],
        region=generic_pipeline_vars['region'],
        pipeline_name=pl_name,
    )
    assert (s is None)

    try:
        pl_ops.delete_pipeline_artefact_registry(
            project_id=artifact_registry['project_id'],
            region=artifact_registry['region'],
            repo_name=artifact_registry['name'],
            package_name=pl_name)
    except KeyError as e:
        if e.args[0] == 'done':
            pass
        else:
            raise KeyError(e)
