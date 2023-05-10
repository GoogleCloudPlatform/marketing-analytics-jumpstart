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

section_open "Check if the necessary dependencies are available: gcloud, gsutil, terraform, poetry"
    check_exec_dependency "gcloud"
    check_exec_version "gcloud"
    check_exec_dependency "gsutil"
    check_exec_version "gsutil"
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

section_open  "Check and set the LOCATION variable"
    set_environment_variable_if_not_set "LOCATION" "us-central1"
section_close

section_open  "Check and set the TF_STATE_BUCKET variable"
    set_environment_variable_if_not_set "TF_STATE_BUCKET" "${TF_STATE_PROJECT}-terraform-state"
section_close

section_open "Creating the service account for Terraform: tf-service-account"
    TF_SERVICE_ACCOUNT_NAME=tf-service-account
    if gcloud iam service-accounts describe "${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com >/dev/null 2>&1; then
        printf "The ${TF_SERVICE_ACCOUNT_NAME} service account already exists. \n"
    else
        gcloud iam service-accounts create "${TF_SERVICE_ACCOUNT_NAME}" \
            --display-name "Terraform admin account"
    fi
section_close

section_open "Granting the service account permission to view the Admin Project"
    gcloud projects add-iam-policy-binding "${TF_STATE_PROJECT}" \
        --member serviceAccount:"${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com \
        --role roles/viewer
section_close

section_open "Granting the service account permission to manage Cloud Storage"
    gcloud projects add-iam-policy-binding "${TF_STATE_PROJECT}" \
        --member serviceAccount:"${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com \
        --role roles/storage.admin
section_close

section_open "Enable the Cloud Resource Manager API with"
    gcloud services enable cloudresourcemanager.googleapis.com
section_close

section_open "Creating a new Google Cloud Storage bucket to store the Terraform state in ${TF_STATE_PROJECT} project, bucket: ${TF_STATE_BUCKET}"
    if gsutil ls -b gs://"${TF_STATE_BUCKET}" >/dev/null 2>&1; then
        printf "The ${TF_STATE_BUCKET} Google Cloud Storage bucket already exists. \n"
    else
        gsutil mb -p "${TF_STATE_PROJECT}" --pap enforced -l "${LOCATION}" -b on gs://"${TF_STATE_BUCKET}"
        gsutil versioning set on gs://"${TF_STATE_BUCKET}"
    fi
section_close

section_open "Creating terraform backend.tf configuration file"
    TERRAFORM_RUN_DIR="infrastructure/terraform"
    create_terraform_backend_config_file "${TERRAFORM_RUN_DIR}" "${TF_STATE_BUCKET}"
section_close

printf "$DIVIDER"
printf "You got the end the of your generate-tf-backend with everything working. \n"
printf "$DIVIDER"