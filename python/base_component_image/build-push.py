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

import docker, os, yaml
from argparse import ArgumentParser, ArgumentTypeError


def run(
        dockerfile_path: str, 
        tag: str, 
        nocache: bool =False, 
        quiet: bool =True):
    """
    This function builds and pushes a Docker image to a specified repository.

    Args:
        dockerfile_path (str): The path to the Dockerfile.
        tag (str): The tag for the Docker image.
        nocache (bool, optional): Whether to disable the Docker cache. Defaults to False.
        quiet (bool, optional): Whether to suppress output from the Docker build process. Defaults to True.

    Raises:
        FileNotFoundError: If the Dockerfile does not exist.
        ArgumentTypeError: If the Dockerfile path is not a string or the tag is not a string.
    """

    client = docker.from_env()
    client.images.build(path = dockerfile_path, tag=tag, nocache=nocache, quiet=quiet)
    client.images.push(repository=tag)


def check_extention(
        file_path: str, 
        type: str = '.yaml'):
    """
    This function checks if a file exists and has the specified extension.

    Args:
        file_path (str): The path to the file.
        type (str, optional): The file extension to check for. Defaults to '.yaml'.

    Returns:
        str: The file path if it exists and has the specified extension.

    Raises:
        FileNotFoundError: If the file does not exist.
        ArgumentTypeError: If the file path is not a string or the type is not a string.
    """
    if not isinstance(file_path, str):
        raise ArgumentTypeError("file_path must be a string")

    if not isinstance(type, str):
        raise ArgumentTypeError("type must be a string")
    
    if os.path.exists(file_path):
        if not file_path.lower().endswith(type):
            raise ArgumentTypeError(f"File provited must be {type}: {file_path}")
    else:
        raise FileNotFoundError(f"{file_path} does not exist")
    
    return file_path


if __name__ == "__main__":
    """
    Script that builds and pushes a Docker image to a specified repository. It takes the following arguments:

    Args:
        -c: Path to the configuration YAML file.
        -p: Path to the Dockerfile.
        -nc: Whether to disable the Docker cache (optional, defaults to False).
    """
    
    parser = ArgumentParser()
    
    parser.add_argument("-c", "--config-file",
                    dest="config",
                    required=True,
                    type=check_extention,
                    help="path to config YAML file (dev.yaml or prod.yaml)")

    parser.add_argument("-p", "--dockerfile-path",
                        dest="path",
                        default=os.path.dirname(__file__), #assumes the docker file is in the same path as this script
                        type=str,
                        help="path to Dockerfile")

    parser.add_argument("-nc", '--nocache',
                    dest="nocache",
                    type=bool,
                    default=False,
                    help='Option to disable cache. False is default')

    args = parser.parse_args()

    repo_params={}
    components_params={}
    with open(args.config, encoding='utf-8') as fh:
        configs = yaml.full_load(fh)

    components_params = configs['vertex_ai']['components']
    repo_params = configs['artifact_registry']['pipelines_docker_repo']

    tag =  f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{components_params['base_image_name']}:{components_params['base_image_tag']}"
    
    # This script provides a convenient way to build and push Docker images for Vertex AI pipelines.
    if True:
        import os
        os.system(f"cd '{args.path}' && gcloud builds submit --project={repo_params['project_id']} --region={repo_params['region']} --tag {tag}")
    else:
        run(args.path, tag, args.nocache)
