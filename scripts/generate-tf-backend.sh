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

. scripts/common.sh

section_open "Check if the necessary dependencies are available: gcloud, terraform, poetry"
    check_exec_dependency "gcloud"
    check_exec_version "gcloud"
    check_exec_dependency "terraform"
    check_exec_version "terraform"
    check_exec_dependency "poetry"
    check_exec_version "poetry"
section_close

section_open "Check if the necessary variables are set: PROJECT_ID, GOOGLE_APPLICATION_CREDENTIALS"
    check_environment_variable "PROJECT_ID" "the Google Cloud project that Terraform will provision the resources in"
    check_environment_variable "GOOGLE_APPLICATION_CREDENTIALS" "the Google Cloud application credentials that Terraform will use"
section_close

section_open  "Setting the Google Cloud project to TF_STATE_PROJECT"
    set_environment_variable_if_not_set "TF_STATE_PROJECT" "${PROJECT_ID}"
    gcloud config set project "${TF_STATE_PROJECT}"
section_close

section_open "Creating the service account for Terraform: tf-service-account"
    TF_SERVICE_ACCOUNT_NAME=tf-service-account
    if gcloud iam service-accounts describe "${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com >/dev/null 2>&1; then
        echo "The ${TF_SERVICE_ACCOUNT_NAME} service account already exists."
    else
        gcloud iam service-accounts create "${TF_SERVICE_ACCOUNT_NAME}" \
            --display-name "Terraform admin account"
    fi
section_close

printf "$DIVIDER"
printf "You got the end the of your generate-tf-backend with everything working. \n"
printf "$DIVIDER"