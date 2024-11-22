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

# This resources creates a workflow that runs the Dataform incremental pipeline.
resource "google_workflows_workflow" "dataform-incremental-workflow" {
  project         = null_resource.check_workflows_api.id != "" ? module.data_processing_project_services.project_id : var.project_id
  name            = "dataform-${var.property_id}-incremental"
  region          = var.region
  description     = "Dataform incremental workflow for ${var.property_id} ga4 property"
  service_account = module.workflow-dataform.email
  # The source code includes the following steps:
  # Init: This step initializes the workflow by assigning the value of the dataform_repository_id variable to the repository variable.
  # Create Compilation Result: This step creates a compilation result for the Dataform repository. The compilation result includes the git commit hash and the code compilation configuration.
  # Create Workflow Invocation: This step creates a workflow invocation for the compilation result. The workflow invocation includes the compilation result and the invocation configuration. The invocation configuration specifies the tags that will be used to filter the Dataform files that are included in the workflow.
  # Complete: This step completes the workflow by returning the name of the workflow invocation.
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
              ga4_property_id: '${var.property_id}'
              ga4_export_project: ${var.source_ga4_export_project_id}
              ga4_export_dataset: ${var.source_ga4_export_dataset}
              ga4_incremental_processing_days_back: '${var.ga4_incremental_processing_days_back}'
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
