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

locals {
  scheduler_sa = "workflow-scheduler-${var.property_id}@${module.data_processing_project_services.project_id}.iam.gserviceaccount.com"
  workflows_sa = "workflow-dataform-${var.property_id}@${module.data_processing_project_services.project_id}.iam.gserviceaccount.com"
}

module "scheduler" {
  source  = "terraform-google-modules/service-accounts/google//modules/simple-sa"
  version = "~> 4.0"

  project_id    = null_resource.check_cloudscheduler_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  name  = "workflow-scheduler-${var.property_id}"
  project_roles = [
    "roles/workflows.invoker"
  ]

  depends_on = [
    module.data_processing_project_services,
    null_resource.check_cloudscheduler_api,
  ]
}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_scheduler_service_account_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.scheduler
  ]
}

# Wait for the scheduler service account to be created
#while ! gcloud asset search-all-iam-policies --scope=projects/${module.data_processing_project_services.project_id} --flatten="policy.bindings[].members[]" --filter="policy.bindings.members~\"serviceAccount:\"" --format="value(policy.bindings.members.split(sep=\":\").slice(1))" | grep -i "${local.scheduler_sa}" && [ $COUNTER -lt $MAX_TRIES ]
resource "null_resource" "wait_for_scheduler_sa_creation" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud iam service-accounts list --project=${module.data_processing_project_services.project_id} --filter="EMAIL:${local.scheduler_sa} AND DISABLED:False" --format="table(EMAIL, DISABLED)" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 10
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "scheduler service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 120
    EOT
  }

  depends_on = [
    module.data_processing_project_services,
    time_sleep.wait_for_scheduler_service_account_role_propagation,
    null_resource.check_dataform_api,
    module.scheduler,
  ]
}

module "workflow-dataform" {
  source  = "terraform-google-modules/service-accounts/google//modules/simple-sa"
  version = "~> 4.0"

  project_id    = null_resource.check_workflows_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  name  = "workflow-dataform-${var.property_id}"
  project_roles = [
    "roles/dataform.editor"
  ]

  depends_on = [
    module.data_processing_project_services,
    null_resource.check_workflows_api,
    null_resource.check_dataform_api,
  ]
}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_workflow_dataform_service_account_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.workflow-dataform
  ]
}

# Wait for the workflows service account to be created
resource "null_resource" "wait_for_workflows_sa_creation" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud iam service-accounts list --project=${module.data_processing_project_services.project_id} --filter="EMAIL:${local.workflows_sa} AND DISABLED:False" --format="table(EMAIL, DISABLED)" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 10
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "workflows service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 120
    EOT
  }

  depends_on = [
    module.data_processing_project_services,
    null_resource.check_dataform_api,
    module.workflow-dataform,
    time_sleep.wait_for_workflow_dataform_service_account_role_propagation,
  ]
}
