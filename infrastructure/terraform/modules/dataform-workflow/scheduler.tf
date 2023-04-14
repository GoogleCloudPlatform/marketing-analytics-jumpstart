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

resource "google_cloud_scheduler_job" "daily-dataform-increments" {
  project          = var.project_id
  name             = "daily-dataform-${var.environment}"
  description      = "Daily Dataform ${var.environment} environment incremental update"
  schedule         = var.daily_schedule
  time_zone        = "America/New_York"
  attempt_deadline = "320s"
  paused           = false

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.dataform-incremental-workflow.name}/executions"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }
}
