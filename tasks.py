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

# The marketing analytics jumpstart uses the python pyinvoke 
# library to automate tasks such as applying configuration parameters 
# to all procedures, datasets, queries, and tables. This allows the user 
# to easily generate new SQL files for each template without having to 
# manually apply the configuration parameters. The pyinvoke library also 
# provides a number of other tasks that can be used to automate other 
# common tasks, such as running linting checks, applying fixes, and 
# running unit tests.

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
import re


GOOGLE_CLOUD_PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT")
REGION = os.environ.get("REGION", "us-central1")

@task
def apply_config_parameters_to_all_procedures(c, env_name="prod"):
    """
    Applies parameters from a configuration file to .sqlx stored procedure template files,
    generating new .sql files for each template.

    Args:
        c (object): An object providing context for task execution (e.g., task runner).
        env_name (str, optional): Name of the environment to use for configuration. Defaults to "prod".

    Raises:
        FileNotFoundError: If the specified configuration file is not found.
        ValueError: If the configuration file is invalid or missing required keys.
        TemplateError: If an error occurs during template rendering.

    Example usage:
        apply_config_parameters_to_all_procedures(my_task_context, env_name="dev")
    
    Customization:
        1) Add a new parameter to .sqlx template file: Add the placeholder: 
            a) Insert the new parameter's placeholder within the template file, surrounded 
            by Jinja2's delimiters (e.g., {{ new_parameter }}) where you want its value to appear 
            in the rendered output.
            b) Add a new key-value pair for the new parameter under the appropriate section of 
            your config.yaml.tftpl YAML configuration file. Ensure the key matches the placeholder 
            name in the template.
            c) No code changes required: The existing code already retrieves configuration values 
            and renders them into templates, so it should handle the new parameter without modification.
    """
    # Load configuration file according to environment name
    current_path = Path(__file__).parent.resolve()
    conf = yaml.safe_load(Path.joinpath(current_path,"config", "{}.yaml".format(env_name)).read_text())

    # Fetch all procedure configs <key,value> to be applied
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
def apply_config_parameters_to_all_datasets(c, env_name="prod"):
    """
    Applies parameters from a configuration file to .sqlx dataset template files,
    generating new .sql files for each template.

    Args:
        c (object): An object providing context for task execution (e.g., task runner).
        env_name (str, optional): Name of the environment to use for configuration. Defaults to "prod".

    Raises:
        FileNotFoundError: If the specified configuration file is not found.
        ValueError: If the configuration file is invalid or missing required keys.
        TemplateError: If an error occurs during template rendering.

    Example usage:
        apply_config_parameters_to_all_datasets(my_task_context, env_name="dev")
    
    Customization:
        1) Add a new parameter to .sqlx template file: Add the placeholder: 
            a) Insert the new parameter's placeholder within the template file, surrounded 
            by Jinja2's delimiters (e.g., {{ new_parameter }}) where you want its value to appear 
            in the rendered output.
            b) Add a new key-value pair for the new parameter under the appropriate section of 
            your config.yaml.tftpl YAML configuration file. Ensure the key matches the placeholder 
            name in the template.
            c) No code changes required: The existing code already retrieves configuration values 
            and renders them into templates, so it should handle the new parameter without modification.
    """
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
def apply_config_parameters_to_all_queries(c, env_name="prod"):
    """
    Applies parameters from a configuration file to .sqlx query template files,
    generating new .sql files for each template.

    Args:
        c (object): An object providing context for task execution (e.g., task runner).
        env_name (str, optional): Name of the environment to use for configuration. Defaults to "prod".

    Raises:
        FileNotFoundError: If the specified configuration file is not found.
        ValueError: If the configuration file is invalid or missing required keys.
        TemplateError: If an error occurs during template rendering.

    Example usage:
        apply_config_parameters_to_all_queries(my_task_context, env_name="dev")
    
    Customization:
        1) Add a new parameter to .sqlx template file: Add the placeholder: 
            a) Insert the new parameter's placeholder within the template file, surrounded 
            by Jinja2's delimiters (e.g., {{ new_parameter }}) where you want its value to appear 
            in the rendered output.
            b) Add a new key-value pair for the new parameter under the appropriate section of 
            your config.yaml.tftpl YAML configuration file. Ensure the key matches the placeholder 
            name in the template.
            c) No code changes required: The existing code already retrieves configuration values 
            and renders them into templates, so it should handle the new parameter without modification.
    """
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
def apply_config_parameters_to_all_tables(c, env_name="prod"):
    """
    Applies parameters from a configuration file and table schemas to .sqlx table template files,
    generating new .sql files for each template.

    Args:
        c (object): An object providing context for task execution (e.g., task runner).
        env_name (str, optional): Name of the environment to use for configuration. Defaults to "prod".

    Raises:
        FileNotFoundError: If specified configuration or schema files are not found.
        ValueError: If configuration or schema files are invalid or missing required keys.
        TemplateError: If an error occurs during template rendering.
        JSONDecodeError: If a schema file cannot be parsed as JSON.

    Example usage:
        apply_config_parameters_to_all_tables(my_task_context, env_name="dev")
    """
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
def require_venv(c, test_requirements=False):  # noqa: ANN001, ANN201
    """(Check) Require that virtualenv is setup, requirements installed"""
    c.run("curl -sSL https://install.python-poetry.org | python3 -")
    c.run(f"poetry install")
    if test_requirements:
        c.run(f"poetry install --with test")


@task
def setup_poetry_test(c):  # noqa: ANN001, ANN201
    """(Check) Require that virtualenv is setup, requirements (incl. test) installed"""
    require_venv(c, test_requirements=True)


@task
def setup_poetry_config(c):  # noqa: ANN001, ANN201
    """Create virtualenv, and install requirements, with output"""
    require_venv(c, test_requirements=False)


@task(pre=[require_venv])
def lint(c):  # noqa: ANN001, ANN201
    """Run linting checks"""
    local_names = _determine_local_import_names(".")
    c.run(
        "poetry run flake8 --exclude .venv "
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


@task(pre=[setup_poetry_config])
def fix(c):  # noqa: ANN001, ANN201
    """Apply linting fixes"""
    c.run("poetry run black *.py **/*.py --force-exclude .venv")
    c.run("poetry run isort --profile google *.py **/*.py")


@task(pre=[setup_poetry_test])
def test(c):  # noqa: ANN001, ANN201
    """Run unit tests"""
    c.run("poetry run pytest python/")


@task(pre=[setup_poetry_test])
def system_test(c):  # noqa: ANN001, ANN201
    """Run system tests"""
    c.run("poetry run pytest python/")
