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

ERR_VARIABLE_NOT_DEFINED=2
ERR_MISSING_DEPENDENCY=3

CYAN='\033[0;36m'
BCYAN='\033[1;36m'
NC='\033[0m' # No Color
DIVIDER=$(printf %"$(tput cols)"s | tr " " "*")
DIVIDER+="\n"

get_project_id() {
    local __resultvar=$1
    VALUE=$(gcloud config get-value project | xargs)
    eval $__resultvar="'$VALUE'"
}

get_project_number() {
    local __resultvar=$1
    local PRO=$2
    VALUE=$(gcloud projects list --filter="project_id=$PRO" --format="value(PROJECT_NUMBER)" | xargs)
    eval $__resultvar="'$VALUE'"
}

# DISPLAY HELPERS

section_open() {
    section_description=$1
    printf "$DIVIDER"
    printf "${CYAN}$section_description${NC} \n"
    printf "$DIVIDER"
}

section_close() {
    printf "$DIVIDER"
    printf "${CYAN}$section_description ${BCYAN}- done${NC}\n"
    printf "\n\n"
}

check_exec_dependency() {
  EXECUTABLE_NAME="${1}"

  if ! command -v "${EXECUTABLE_NAME}" >/dev/null 2>&1; then
    echo "[ERROR]: ${EXECUTABLE_NAME} command is not available, but it's needed. Make it available in PATH and try again. Terminating..."
    exit ${ERR_MISSING_DEPENDENCY}
  fi

  unset EXECUTABLE_NAME
}

check_exec_version() {
  EXECUTABLE_NAME="${1}"

  if ! "${EXECUTABLE_NAME}" --version 2>&1; then
    echo "[ERROR]: ${EXECUTABLE_NAME} command is not available, but it's needed. Make it available in PATH and try again. Terminating..."
    exit ${ERR_MISSING_DEPENDENCY}
  fi

  unset EXECUTABLE_NAME
}

check_environment_variable() {
  _VARIABLE_NAME=$1
  _ERROR_MESSAGE=$2
  _VARIABLE_VALUE="${!_VARIABLE_NAME:-}"
  if [ -z "${_VARIABLE_VALUE}" ]; then
    echo "[ERROR]: ${_VARIABLE_NAME} environment variable that points to ${_ERROR_MESSAGE} is not defined. Terminating..."
    exit ${ERR_VARIABLE_NOT_DEFINED}
  fi
  unset _VARIABLE_NAME
  unset _ERROR_MESSAGE
  unset _VARIABLE_VALUE
}

set_environment_variable_if_not_set() {
  _VARIABLE_NAME=$1
  _VALUE_TO_SET=$2
  _VARIABLE_VALUE="${!_VARIABLE_NAME:-}"
  if [ -z "${_VARIABLE_VALUE}" ]; then
    export "${_VARIABLE_NAME}"="${_VALUE_TO_SET}"
  fi
  unset _VARIABLE_NAME
  unset _VALUE_TO_SET
  unset _VARIABLE_VALUE
}

run_terraform() {
  _TERRAFORM_RUN_DIR=$1
  terraform -chdir="${_TERRAFORM_RUN_DIR}" version
  terraform -chdir="${_TERRAFORM_RUN_DIR}" init -input=false
  terraform -chdir="${_TERRAFORM_RUN_DIR}" validate
  terraform -chdir="${_TERRAFORM_RUN_DIR}" apply -input=false -auto-approve
  unset _TERRAFORM_RUN_DIR
}

create_terraform_variables_file() {
  _TERRAFORM_RUN_DIR=$1
  _TERRAFORM_VARIABLE_FILE_PATH=${_TERRAFORM_RUN_DIR}/terraform.tfvars
  echo "Generate the terraform variables in ${_TERRAFORM_VARIABLE_FILE_PATH}"
  if [ -f "${_TERRAFORM_VARIABLE_FILE_PATH}" ]; then
    echo "The ${_TERRAFORM_VARIABLE_FILE_PATH} file already exists."
  else
    envsubst < "${_TERRAFORM_RUN_DIR}/terraform.tfvars.template" > "${_TERRAFORM_VARIABLE_FILE_PATH}"
  fi

  unset _TERRAFORM_RUN_DIR
  unset _TERRAFORM_VARIABLE_FILE_PATH
}

create_terraform_backend_config_file() {
  _TERRAFORM_RUN_DIR=$1
  _TF_STATE_BUCKET=$2
  _TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH="${_TERRAFORM_RUN_DIR}/backend.tf"
  echo "Generating the Terraform backend configuration file: ${_TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}"
  if [ -f "${_TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}" ]; then
    echo "The ${_TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH} file already exists."
  else
    tee "${_TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}" <<EOF
terraform {
  backend "gcs" {
    bucket = "${_TF_STATE_BUCKET}"
    prefix = "state"
  }
}
EOF
  fi
  unset _TERRAFORM_RUN_DIR
  unset _TF_STATE_BUCKET
  unset _TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH
}

set_application_default_credentials() {
  _SOURCE_ROOT=$1
  _CREDENTIAL_FILE_DIR="${_SOURCE_ROOT}/.credentials"
  _CREDENTIAL_FILE_PATH="${_CREDENTIAL_FILE_DIR}/application_default_credentials.json"
  if [ ! -f "${_CREDENTIAL_FILE_PATH}" ]; then
    _AUTH_OUTPUT=$( gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/analytics,https://www.googleapis.com/auth/analytics.edit,https://www.googleapis.com/auth/analytics.provision,https://www.googleapis.com/auth/analytics.readonly,https://www.googleapis.com/auth/accounts.reauth" 2>&1 | tee /dev/tty )
    _CRED_PATH=$( echo ${_AUTH_OUTPUT} | cut -d "[" -f2 | cut -d "]" -f1 )
    mkdir -p "${_CREDENTIAL_FILE_DIR}" && cp "${_CRED_PATH}" "${_CREDENTIAL_FILE_PATH}"
    unset _CRED_PATH
    unset _AUTH_OUTPUT
  fi
  export GOOGLE_APPLICATION_CREDENTIALS="${_CREDENTIAL_FILE_PATH}"
  unset _CREDENTIAL_FILE_PATH
  unset _CREDENTIAL_FILE_DIR
  unset _SOURCE_ROOT
}
