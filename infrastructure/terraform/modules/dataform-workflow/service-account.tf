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

resource "google_service_account" "scheduler" {
  depends_on = [
    module.data_processing_project_services,
    null_resource.check_cloudscheduler_api,
    ]
  
  project      = null_resource.check_cloudscheduler_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  account_id   = "workflow-scheduler-${var.environment}"
  display_name = "Service Account to schedule Dataform workflows in ${var.environment}"
}

locals {
  scheduler_sa = "workflow-scheduler-${var.environment}@${module.data_processing_project_services.project_id}.iam.gserviceaccount.com"
  workflows_sa = "workflow-dataform-${var.environment}@${module.data_processing_project_services.project_id}.iam.gserviceaccount.com"
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
      sleep 3
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "scheduler service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.data_processing_project_services,
    null_resource.check_dataform_api
  ]
}

resource "google_project_iam_member" "scheduler-workflow-invoker" {
  depends_on = [
    module.data_processing_project_services,
    null_resource.check_cloudscheduler_api,
    null_resource.wait_for_scheduler_sa_creation
    ]

  project = null_resource.check_cloudscheduler_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  member  = "serviceAccount:${google_service_account.scheduler.email}"
  role    = "roles/workflows.invoker"
}

resource "google_service_account" "workflow-dataform" {
  depends_on = [
    module.data_processing_project_services,
    null_resource.check_workflows_api,
    ]
  
  project      = null_resource.check_workflows_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  account_id   = "workflow-dataform-${var.environment}"
  display_name = "Service Account to run Dataform workflows in ${var.environment}"
}

# Wait for the workflows service account to be created
resource "null_resource" "wait_for_workflows_sa_creation" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud iam service-accounts list --project=${module.data_processing_project_services.project_id} --filter="EMAIL:${local.workflows_sa} AND DISABLED:False" --format="table(EMAIL, DISABLED)" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 3
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "workflows service account was not created, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }

  depends_on = [
    module.data_processing_project_services,
    null_resource.check_dataform_api
  ]
}


resource "google_project_iam_member" "worflow-dataform-dataform-editor" {
  depends_on = [
    module.data_processing_project_services,
    null_resource.check_dataform_api,
    null_resource.wait_for_workflows_sa_creation
    ]

  project = null_resource.check_workflows_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  member  = "serviceAccount:${google_service_account.workflow-dataform.email}"
  role    = "roles/dataform.editor"
}