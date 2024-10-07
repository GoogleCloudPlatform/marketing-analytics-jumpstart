#!/usr/bin/env sh

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
#set -x

. scripts/common.sh

section_open  "Setting the gcloud project id"
    # Ask user to input the project id
    echo "Input the GCP Project Id where you want to deploy Marketing Analytics Jumpstart:"
    read TF_STATE_PROJECT_ID
    # Set the project id to the environment variable
    export TF_STATE_PROJECT_ID
    # Set the project id to the environment variable
    export GOOGLE_CLOUD_PROJECT=${TF_STATE_PROJECT_ID}
    # Set the project id to the environment variable
    export GOOGLE_CLOUD_QUOTA_PROJECT=$GOOGLE_CLOUD_PROJECT
    # Set the project id to the environment variable
    export PROJECT_ID=$GOOGLE_CLOUD_PROJECT
    # Disable prompts
    gcloud config set disable_prompts true
    # Set the project id to the gcloud configuration
    gcloud config set project "${TF_STATE_PROJECT_ID}"
section_close

section_open "Enable all the required APIs"
    enable_all_apis
section_close

section_open "Authenticate to Google Cloud Project"
    gcloud auth login --project "${TF_STATE_PROJECT_ID}"
    echo "Close the browser tab that was open and press any key to continue.."
    read moveon
section_close

section_open "Setting Google Application Default Credentials"
    gcloud config set disable_prompts false
    gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/accounts.reauth"
    echo "Close the browser tab that was open and press any key to continue.."
    read moveon
    CREDENTIAL_FILE=`gcloud auth application-default set-quota-project "${PROJECT_ID}" 2>&1 | grep -e "Credentials saved to file:" | cut -d "[" -f2 | cut -d "]" -f1`
    export GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIAL_FILE}
section_close

section_open "Check OS system"
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     machine=Linux;;
        Darwin*)    machine=Mac;;
        CYGWIN*)    machine=Cygwin;;
        MINGW*)     machine=MinGw;;
        MSYS_NT*)   machine=Git;;
        *)          machine="UNKNOWN:${unameOut}"
    esac
    echo ${machine}
section_close

section_open "Configuring environment"
    SOURCE_ROOT=$(pwd)
    cd ${SOURCE_ROOT}

    # Install python3.10
    sudo chown -R ctimoteo /usr/local/sbin
    chmod u+w /usr/local/sbin
    if [ $machine == "Linux" ]; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -o=Dpkg::Use-Pty=0 install python3.10 --assume-yes
    elif [ $machine == "Darwin" ]; then
        brew install python@3.10
    fi
    CLOUDSDK_PYTHON=python3.10

    # Install pipx
    if [ $machine == "Linux" ]; then
        sudo apt update
        sudo apt install pipx
    elif [ $machine == "Darwin" ]; then
        brew install pipx
    fi
    pipx ensurepath
    
    #pip3 install poetry
    pipx install poetry
    export PATH="$HOME/.local/bin:$PATH"
    poetry env use python3.10
    poetry --version

    # Install tfenv
    if [ ! -d ~/.tfenv ]; then
        git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
        echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
        echo 'export PATH=$PATH:$HOME/.tfenv/bin' >> ~/.bashrc
    fi
    export PATH="$PATH:$HOME/.tfenv/bin"

    # Install terraform version
    tfenv install 1.5.7
    tfenv use 1.5.7
    terraform --version

    # Generate TF backend
    . scripts/generate-tf-backend.sh 
section_close

section_open "Preparing Terraform Environment File"
    TERRAFORM_RUN_DIR=${SOURCE_ROOT}/infrastructure/terraform
    if [ ! -f $TERRAFORM_RUN_DIR/terraform.tfvars ]; then
        . scripts/set-env.sh
        sudo apt-get -qq -o=Dpkg::Use-Pty=0 install gettext
        envsubst < "${SOURCE_ROOT}/infrastructure/cloudshell/terraform-template.tfvars" > "${TERRAFORM_RUN_DIR}/terraform.tfvars"
    fi
section_close

section_open "Deploying Terraform Infrastructure Resources"
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="$PATH:$HOME/.tfenv/bin"
    terraform -chdir="${TERRAFORM_RUN_DIR}" init
    terraform -chdir="${TERRAFORM_RUN_DIR}" apply
section_close

#set +x
set +o nounset
set +o errexit
