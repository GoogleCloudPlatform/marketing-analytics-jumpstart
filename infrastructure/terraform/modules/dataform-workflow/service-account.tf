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

  project_id    = module.data_processing_project_services.project_id
  name  = "workflow-scheduler-${var.property_id}"
  display_name = "Service Account to schedule Dataform workflows in ${var.property_id}"
  project_roles = [
    "roles/workflows.invoker"
  ]

  depends_on = [time_sleep.wait_for_project_services_activation]  
}

module "workflow-dataform" {
  source  = "terraform-google-modules/service-accounts/google//modules/simple-sa"
  version = "~> 4.0"

  project_id    = module.data_processing_project_services.project_id
  name  = "workflow-dataform-${var.property_id}"
  display_name = "Service Account to run Dataform workflows in ${var.property_id}"
  project_roles = [
    "roles/dataform.editor"
  ]

  depends_on = [time_sleep.wait_for_project_services_activation]
}

# Propagation time for change of access policy typically takes 2 minutes
# according to https://cloud.google.com/iam/docs/access-change-propagation
# this wait make sure the policy changes are propagated before proceeding
# with the build
resource "time_sleep" "wait_for_service_account_role_propagation" {
  create_duration = "120s"
  depends_on = [
    module.scheduler,
    module.workflow-dataform
  ]
}
