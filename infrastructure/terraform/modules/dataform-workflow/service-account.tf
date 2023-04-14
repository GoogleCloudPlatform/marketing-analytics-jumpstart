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
  project      = var.project_id
  account_id   = "workflow-scheduler-${var.environment}"
  display_name = "Service Account to schedule Dataform workflows in ${var.environment}"
}

resource "google_project_iam_member" "scheduler-workflow-invoker" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.scheduler.email}"
  role    = "roles/workflows.invoker"
}

resource "google_service_account" "workflow-dataform" {
  project      = var.project_id
  account_id   = "workflow-dataform-${var.environment}"
  display_name = "Service Account to run Dataform workflows in ${var.environment}"
}

resource "google_project_iam_member" "worflow-dataform-dataform-editor" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.workflow-dataform.email}"
  role    = "roles/dataform.editor"
}