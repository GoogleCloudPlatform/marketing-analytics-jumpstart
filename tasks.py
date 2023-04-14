# Copyright 2021 Google LLC
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

# Invoke tasks - a Python-equivelant of a Makefile or Rakefile.
# http://www.pyinvoke.org/

# LINTING NOTE: invoke doesn't support annotations in task signatures.
# https://github.com/pyinvoke/invoke/issues/777
# Workaround: add "  # noqa: ANN001, ANN201"

import os
import sys
from typing import List
from invoke import task

import yaml
from pathlib import Path
from jinja2 import Template
from jinja2 import FileSystemLoader
from jinja2 import Environment

venv = "source ./venv/bin/activate"

GOOGLE_CLOUD_PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT")
REGION = os.environ.get("REGION", "us-central1")


@task
def apply_env_variables_procedures(c, env_name="prod"):
    current_path = Path(__file__).parent.resolve()
    conf = yaml.safe_load(Path.joinpath(current_path,"config", "{}.yaml".format(env_name)).read_text())
    procedure_dict = conf['bigquery']['procedure']

    # Locate file path for all templates to be used
    template_path = Path.joinpath(current_path,"sql","procedure")
    templateLoader = FileSystemLoader(searchpath=template_path)
    templateEnv = Environment(loader=templateLoader)
    
    # For each file name, apply the config values to the template
    for template_file in template_path.iterdir(): 
        if template_file.is_file() and template_file.resolve().suffix == '.sqlx':
            template = templateEnv.get_template(template_file.name)
            new_sql = template.render(procedure_dict[template_file.stem])
            rendered_sql_file = Path.joinpath(template_path, template_file.resolve().stem+".sql")
            with rendered_sql_file.open("w+", encoding ="utf-8") as f:
                f.write(new_sql)
            print("New SQL file rendered at {}".format(rendered_sql_file))
    
@task
def apply_env_variables_datasets(c, env_name="prod"):
    # Load configuration file according to environment name
    current_path = Path(__file__).parent.resolve()
    conf = yaml.safe_load(Path.joinpath(current_path,"config", "{}.yaml".format(env_name)).read_text())
    
    # Fetch all dataset configs <key,value> to be applied
    dataset_dict = conf['bigquery']['dataset']

    # Locate file path for all templates to be used
    template_path = Path.joinpath(current_path,"sql","schema","dataset")
    templateLoader = FileSystemLoader(searchpath=template_path)
    templateEnv = Environment(loader=templateLoader)
    
    # For each file name, apply the config values to the template
    for template_file in template_path.iterdir(): 
        if template_file.is_file() and template_file.resolve().suffix == '.sqlx':
            template = templateEnv.get_template(template_file.name)
            new_sql = template.render(dataset_dict[template_file.stem])
            rendered_sql_file = Path.joinpath(template_path, template_file.resolve().stem+".sql")
            with rendered_sql_file.open("w+", encoding ="utf-8") as f:
                f.write(new_sql)
            print("New SQL file rendered at {}".format(rendered_sql_file))


@task
def apply_env_variables_queries(c, env_name="prod"):
    # Load configuration file according to environment name
    current_path = Path(__file__).parent.resolve()
    conf = yaml.safe_load(Path.joinpath(current_path,"config", "{}.yaml".format(env_name)).read_text())
    
    # Fetch all query configs <key,value> to be applied
    query_dict = conf['bigquery']['query']

    # Locate file path for all templates to be used
    template_path = Path.joinpath(current_path,"sql","query")
    templateLoader = FileSystemLoader(searchpath=template_path)
    templateEnv = Environment(loader=templateLoader)
    
    # For each file name, apply the config values to the template
    for template_file in template_path.iterdir(): 
        if template_file.is_file() and template_file.resolve().suffix == '.sqlx':
            template = templateEnv.get_template(template_file.name)
            new_sql = template.render(query_dict[template_file.stem])
            rendered_sql_file = Path.joinpath(template_path, template_file.resolve().stem+".sql")
            with rendered_sql_file.open("w+", encoding ="utf-8") as f:
                f.write(new_sql)
            print("New SQL file rendered at {}".format(rendered_sql_file))

@task
def apply_env_variables_tables(c, env_name="prod"):
    import json
    # Load configuration file according to environment name
    current_path = Path(__file__).parent.resolve()
    conf = yaml.safe_load(Path.joinpath(current_path,"config", "{}.yaml".format(env_name)).read_text())
    
    # Fetch all query configs <key,value> to be applied
    query_dict = conf['bigquery']['table']

    # Locate file path for all templates to be used
    template_path = Path.joinpath(current_path,"sql","table")
    templateLoader = FileSystemLoader(searchpath=template_path)
    templateEnv = Environment(loader=templateLoader)

    # Locate file path for all table schemas to be used
    schema_path = Path.joinpath(current_path,"sql","schema","table")

    # Open the file in read-only mode
    for template_file in template_path.iterdir(): 
        if template_file.is_file() and template_file.resolve().suffix == '.sqlx':
            for schema_file in schema_path.iterdir():
                if schema_file.is_file() and schema_file.resolve().suffix == '.json' and template_file.resolve().stem == schema_file.resolve().stem: 
                    with schema_file.open("r", encoding="utf-8") as f:
                        table_schema = str(f.read())
                    table_schema_dict = json.loads(table_schema)
                    columns_str = ""
                    for row in table_schema_dict:
                        columns_str+=(row['name'] + ' ' + row['type'] + ' ' + """OPTIONS (description = '""" + row['description'] + """'), """)
                    config_dict = {"columns": columns_str, **query_dict[template_file.stem]}
                    template = templateEnv.get_template(template_file.name)
                    new_sql = template.render(config_dict)
                    rendered_sql_file = Path.joinpath(template_path, template_file.resolve().stem+".sql")
                    with rendered_sql_file.open("w+", encoding ="utf-8") as f:
                        f.write(new_sql)
                    print("New SQL file rendered at {}".format(rendered_sql_file))


@task
def require_project(c):  # noqa: ANN001, ANN201
    """(Check) Require GOOGLE_CLOUD_PROJECT be defined"""
    if GOOGLE_CLOUD_PROJECT is None:
        print("GOOGLE_CLOUD_PROJECT not defined. Required for task")
        sys.exit(1)


@task
def require_venv(c, test_requirements=False, quiet=True):  # noqa: ANN001, ANN201
    """(Check) Require that virtualenv is setup, requirements installed"""

    c.run("python3.7 -m venv venv")
    quiet_param = " -q" if quiet else ""

    with c.prefix(venv):
        c.run(f"pip install -r requirements.txt {quiet_param}")

        if test_requirements:
            c.run(f"pip install -r requirements-dev.txt {quiet_param}")


@task
def require_venv_test(c):  # noqa: ANN001, ANN201
    """(Check) Require that virtualenv is setup, requirements (incl. test) installed"""
    require_venv(c, test_requirements=True)


@task
def setup_virtualenv(c):  # noqa: ANN001, ANN201
    """Create virtualenv, and install requirements, with output"""
    require_venv(c, test_requirements=True, quiet=False)


@task(pre=[require_venv])
def start(c):  # noqa: ANN001, ANN201
    """Start the web service"""
    with c.prefix(venv):
        c.run("python app.py")


@task(pre=[require_venv])
def dev(c):  # noqa: ANN001, ANN201
    """Start the web service in a development environment, with fast reload"""
    with c.prefix(venv):
        c.run("FLASK_ENV=development python app.py")


@task(pre=[require_venv])
def lint(c):  # noqa: ANN001, ANN201
    """Run linting checks"""
    with c.prefix(venv):
        local_names = _determine_local_import_names(".")
        c.run(
            "flake8 --exclude venv "
            "--max-line-length=88 "
            "--import-order-style=google "
            f"--application-import-names {','.join(local_names)} "
            "--ignore=E121,E123,E126,E203,E226,E24,E266,E501,E704,W503,W504,I202"
        )


def _determine_local_import_names(start_dir: str) -> List[str]:
    """Determines all import names that should be considered "local".
    This is used when running the linter to insure that import order is
    properly checked.
    """
    file_ext_pairs = [os.path.splitext(path) for path in os.listdir(start_dir)]
    return [
        basename
        for basename, extension in file_ext_pairs
        if extension == ".py"
        or os.path.isdir(os.path.join(start_dir, basename))
        and basename not in ("__pycache__")
    ]


@task(pre=[require_venv])
def fix(c):  # noqa: ANN001, ANN201
    """Apply linting fixes"""
    with c.prefix(venv):
        c.run("black *.py **/*.py --force-exclude venv")
        c.run("isort --profile google *.py **/*.py")


@task(pre=[require_project])
def build(c):  # noqa: ANN001, ANN201
    """Build the service into a container image"""
    c.run(
        f"gcloud builds submit --pack "
        f"image={REGION}-docker.pkg.dev/{GOOGLE_CLOUD_PROJECT}/samples/microservice-template:manual"
    )


@task(pre=[require_project])
def deploy(c):  # noqa: ANN001, ANN201
    """Deploy the container into Cloud Run (fully managed)"""
    c.run(
        "gcloud run deploy microservice-template "
        f"--image {REGION}-docker.pkg.dev/{GOOGLE_CLOUD_PROJECT}/samples/microservice-template:manual "
        f"--platform managed --region {REGION}"
    )


@task(pre=[require_venv_test])
def test(c):  # noqa: ANN001, ANN201
    """Run unit tests"""
    with c.prefix(venv):
        c.run("pytest test/test_app.py")


@task(pre=[require_venv_test])
def system_test(c):  # noqa: ANN001, ANN201
    """Run system tests"""
    with c.prefix(venv):
        c.run("pytest test/test_system.py")

## commands list:
# 1. To apply Jinja2 template over the right files.
# 2. To run unit testing
# 3. To run static check on SQL code