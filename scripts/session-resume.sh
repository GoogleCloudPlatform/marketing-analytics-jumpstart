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

SOURCE_ROOT=$(pwd)
export TERRAFORM_RUN_DIR=${SOURCE_ROOT}/infrastructure/terraform

# Get terraform state Google Cloud project id
TF_STATE_PROJECT_ID="$(terraform -chdir="${TERRAFORM_RUN_DIR}" output -raw tf_state_project_id)"

section_open  "Setting the gcloud project id"
    gcloud config set project "${TF_STATE_PROJECT_ID}"
section_close

section_open "Setting Google Application Default Credentials"
    set_application_default_credentials "${SOURCE_ROOT}"
section_close

set +o nounset
set +o errexit
