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

# Check if the necessary dependencies are available
check_exec_dependency "gcloud"
check_exec_dependency "envsubst"

# Check if the necessary variables are set
check_environment_variable "PROJECT_ID" "the Google Cloud project that Terraform will provision the resources in"
check_environment_variable "GOOGLE_APPLICATION_CREDENTIALS" "the Google Cloud application credentials that Terraform will use"

set_environment_variable_if_not_set "TF_STATE_PROJECT" "${PROJECT_ID}"

echo "Setting the Google Cloud project to ${TF_STATE_PROJECT}"
gcloud config set project "${TF_STATE_PROJECT}"

echo "Creating the service account for Terraform"
TF_SERVICE_ACCOUNT_NAME=tf-service-account
if gcloud iam service-accounts describe "${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com >/dev/null 2>&1; then
    echo "The ${TF_SERVICE_ACCOUNT_NAME} service account already exists."
else
    gcloud iam service-accounts create "${TF_SERVICE_ACCOUNT_NAME}" \
        --display-name "Terraform admin account"
fi

echo "Granting the service account permission to view the Admin Project"
gcloud projects add-iam-policy-binding "${TF_STATE_PROJECT}" \
    --member serviceAccount:"${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com \
    --role roles/viewer

echo "Granting the service account permission to manage Cloud Storage"
gcloud projects add-iam-policy-binding "${TF_STATE_PROJECT}" \
    --member serviceAccount:"${TF_SERVICE_ACCOUNT_NAME}"@"${TF_STATE_PROJECT}".iam.gserviceaccount.com \
    --role roles/storage.admin

echo "Enable the Cloud Resource Manager API with"
gcloud services enable cloudresourcemanager.googleapis.com
