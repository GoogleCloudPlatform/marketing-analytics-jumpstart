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

# This creates a Cloud Scheduler job that triggers the Dataform incremental workflow on a daily schedule. 
resource "google_cloud_scheduler_job" "daily-dataform-increments" {
  project     = module.data_processing_project_services.project_id
  name        = "daily-dataform-${var.property_id}"
  description = "Daily Dataform ${var.property_id} property export incremental update"
  # The schedule attribute specifies the schedule for the job. In this case, the job is scheduled to run daily at the specified times.
  schedule  = var.daily_schedule
  time_zone = var.time_zone
  # The attempt_deadline attribute specifies the maximum amount of time that the job will attempt to run before failing.
  # In this case, the job will attempt to run for a maximum of 5 minutes before failing.
  attempt_deadline = "320s"
  paused           = false

  retry_config {
    retry_count = 1
  }

  # The http_target attribute specifies the HTTP target for the job. In this case, the job is configured to send an HTTP POST request to the Cloud Workflows Executions API to trigger the Dataform incremental workflow.
  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${module.data_processing_project_services.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.dataform-incremental-workflow.name}/executions"

    oauth_token {
      service_account_email = module.scheduler.email
    }
  }
}
