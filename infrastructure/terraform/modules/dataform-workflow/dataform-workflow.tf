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
  tagList    = join("\n", formatlist("            - %s", var.includedTags))
  tagSection = length(var.includedTags) == 0 ? "" : "\n            includedTags:\n${local.tagList}"

  adsDataVariable = jsonencode(var.source_ads_export_data)
}
resource "google_workflows_workflow" "dataform-incremental-workflow" {
  project         = var.project_id
  name            = "dataform-${var.environment}-incremental"
  region          = var.region
  description     = "Dataform incremental workflow for ${var.environment} environment"
  service_account = google_service_account.workflow-dataform.email
  source_contents = <<-EOF
main:
  steps:
  - init:
      assign:
      - repository: ${var.dataform_repository_id}
  - createCompilationResult:
      call: http.post
      args:
        url: $${"https://dataform.googleapis.com/v1beta1/" + repository + "/compilationResults"}
        auth:
          type: OAuth2
        body:
          gitCommitish: ${var.gitCommitish}
          codeCompilationConfig:
            defaultDatabase: ${var.destination_bigquery_project_id}
            defaultLocation: ${var.destination_bigquery_dataset_location}
            vars:
              env: ${var.environment}
              ga4_export_project: ${var.source_ga4_export_project_id}
              ga4_export_dataset: ${var.source_ga4_export_dataset}
              ads_export_data: '${local.adsDataVariable}'
      result: compilationResult
  - createWorkflowInvocation:
      call: http.post
      args:
        url: $${"https://dataform.googleapis.com/v1beta1/" + repository + "/workflowInvocations"}
        auth:
          type: OAuth2
        headers:
          User-Agent: "cloud-solutions/marketing-analytics-jumpstart-usage-v1"
        body:
          compilationResult: $${compilationResult.body.name}
          invocationConfig:${local.tagSection}
            transitiveDependenciesIncluded: true
      result: workflowInvocation
  - complete:
      return: $${workflowInvocation.body.name}
EOF
}
