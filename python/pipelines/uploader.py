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

import logging, yaml,os
from pipelines.pipeline_ops import upload_pipeline_artefact_registry
from argparse import ArgumentParser, ArgumentTypeError


# Checks if a file exists and has the correct extension (.yaml by default).
def check_extention(file_path: str, type: str = '.yaml'):
    if os.path.exists(file_path):
        if not file_path.lower().endswith(type):
            raise ArgumentTypeError(f"File provided must be {type}: {file_path}")
    else:
        raise FileNotFoundError(f"{file_path} does not exist")
    return file_path

             
if __name__ == "__main__":
    """
    This Python script defines a command-line tool for uploading compiled Vertex AI pipelines to Artifact Registry. It takes the following arguments:
        -c: Path to the configuration YAML file (e.g., dev.yaml or prod.yaml). This file contains information about the Artifact Registry repository where the pipeline will be uploaded.
        -f: Path to the compiled pipeline YAML file. This file contains the pipeline definition.
        -d: (Optional) Description of the pipeline artifact.
        -t: (Optional) List of tags for the pipeline artifact.
    """
    logging.basicConfig(level=logging.INFO)
    
    parser = ArgumentParser()

    parser.add_argument("-c", "--config-file",
                        dest="config",
                        required=True,
                        type=check_extention,
                        help="path to config YAML file (dev.yaml or prod.yaml)")

    parser.add_argument("-f", '--pipeline-filename',
                    dest="filename",
                    required=True,
                    type=check_extention,
                    help='the compiled pipeline YAML filename')

    parser.add_argument("-d", '--description',
                    dest="description",
                    type=str,
                    default="",
                    help='the compiled pipeline YAML filename')

    parser.add_argument("-t", '--tags',
                    dest="tags",
                    type=str,
                    action='append',
                    default=['latest'],
                    help='list of tags for the artifact. e.g: -t latest -t v1')

    args = parser.parse_args()

    repo_params={}
    # Opens the configuration YAML file and extracts the parameters for the 
    # Artifact Registry repository.
    with open(args.config, encoding='utf-8') as fh:
        repo_params = yaml.full_load(fh)['artifact_registry']['pipelines_repo']

    # Calls the upload_pipeline_artefact_registry function from pipelines.pipeline_ops to 
    # upload the compiled pipeline to the specified Artifact Registry repository.
    upload_pipeline_artefact_registry(
        template_path=args.filename,
        project_id=repo_params['project_id'],
        region=repo_params['region'],
        repo_name=repo_params['name'],
        tags=args.tags,
        description=args.description)