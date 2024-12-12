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

locals {
  source_root_dir        = "../.."
  dashboard_dataset_name = "maj_dashboard"
  log_dataset_name       = "maj_logs"
  link_load_file         = "load_links.json"

  console        = "https://console.cloud.google.com"
  bq_console     = "${local.console}/bigquery"
  vertex_console = "${local.console}/vertex-ai"

  p_key                     = "project"
  mds_project_url           = "${local.p_key}=${var.mds_project_id}"
  feature_store_project_url = "${local.p_key}=${var.feature_store_project_id}"
  activation_project_url    = "${local.p_key}=${var.activation_project_id}"

  mds_dataform_repo = "marketing-analytics"

  purchase_propensity_dataset = "purchase_propensity"
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "17.0.0"

  disable_dependent_services  = false
  disable_services_on_destroy = false

  project_id = var.project_id

  activate_apis = [
    "cloudfunctions.googleapis.com",
    "bigquery.googleapis.com",
    "logging.googleapis.com",
    "bigquerystorage.googleapis.com",
    "storage.googleapis.com",
  ]
}

# This resource executes gcloud commands to check whether the BigQuery API is enabled.
# Since enabling APIs can take a few seconds, we need to make the deployment wait until the API is enabled before resuming.
resource "null_resource" "check_bigquery_api" {
  provisioner "local-exec" {
    command = <<-EOT
    COUNTER=0
    MAX_TRIES=100
    while ! gcloud services list --project=${module.project_services.project_id} | grep -i "bigquery.googleapis.com" && [ $COUNTER -lt $MAX_TRIES ]
    do
      sleep 6
      printf "."
      COUNTER=$((COUNTER + 1))
    done
    if [ $COUNTER -eq $MAX_TRIES ]; then
      echo "bigquery api is not enabled, terraform can not continue!"
      exit 1
    fi
    sleep 20
    EOT
  }
}

module "dashboard_bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "8.1.0"

  dataset_id                 = local.dashboard_dataset_name
  dataset_name               = local.dashboard_dataset_name
  description                = "providing links to looker dashboard"
  project_id                 = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : ""
  location                   = var.location
  delete_contents_on_destroy = true

  tables = [
    {
      table_id           = "resource_link",
      schema             = file("../../sql/schema/table/resource_link.json"),
      time_partitioning  = null,
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels             = {},
  }]
}

module "load_bucket" {
  source        = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version       = "6.1.0"
  project_id    = module.project_services.project_id
  name          = "maj-monitor-${module.project_services.project_id}"
  location      = var.location
  force_destroy = true
}

data "template_file" "resource_link_content" {
  template = file("${local.source_root_dir}/templates/monitoring_resource_link_template.csv")
  vars = {
    console        = local.console
    bq_console     = local.bq_console
    vertex_console = local.vertex_console

    mds_project           = var.mds_project_id
    feature_store_project = var.feature_store_project_id
    activation_project    = var.activation_project_id

    mds_project_url           = local.mds_project_url
    feature_store_project_url = local.feature_store_project_url
    activation_project_url    = local.activation_project_url

    mds_dataset_suffix     = var.mds_dataset_suffix
    mds_location           = var.mds_location
    mds_dataform_repo      = local.mds_dataform_repo
    mds_dataform_workspace = var.mds_dataform_workspace
  }
}

resource "google_storage_bucket_object" "resource_link_load_file" {
  name    = local.link_load_file
  bucket  = module.load_bucket.name
  content = data.template_file.resource_link_content.rendered
}

resource "google_bigquery_job" "monitor_resources_load" {
  job_id  = uuid()
  project = module.project_services.project_id
  load {
    source_uris = [
      "gs://${module.load_bucket.name}/${google_storage_bucket_object.resource_link_load_file.output_name}",
    ]
    destination_table {
      project_id = module.project_services.project_id
      dataset_id = module.dashboard_bigquery.bigquery_dataset.dataset_id
      table_id   = module.dashboard_bigquery.table_ids[0]
    }
    write_disposition = "WRITE_TRUNCATE"
  }
  location = var.location
  lifecycle {
    ignore_changes = [job_id]
  }
}

locals {
  dataform_log_table_id         = "dataform_googleapis_com_workflow_invocation_completion"
  vertex_pipelines_log_table_id = "aiplatform_googleapis_com_pipeline_job_events"
  dataflow_log_table_id         = "dataflow_googleapis_com_job_message"
  log_table_ids = [
    local.dataform_log_table_id,
    local.vertex_pipelines_log_table_id,
    local.dataflow_log_table_id
  ]
}

module "log_export_bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "8.1.0"

  dataset_id                 = local.log_dataset_name
  dataset_name               = local.log_dataset_name
  description                = "Holds log exports"
  project_id                 = module.project_services.project_id
  location                   = var.location
  delete_contents_on_destroy = true

  tables = [for table_id in local.log_table_ids :
    {
      table_id = table_id,
      schema   = file("../../sql/schema/table/${table_id}.json"),
      time_partitioning = {
        type                     = "DAY",
        field                    = "timestamp",
        require_partition_filter = false,
        expiration_ms            = null,
      },
      range_partitioning = null,
      expiration_time    = null,
      clustering         = [],
      labels             = {},
  }]
}

resource "google_logging_project_sink" "mds_daily_execution" {
  name                   = "mds_execution_export"
  project                = var.mds_project_id
  filter                 = "resource.type=\"dataform.googleapis.com/Repository\""
  destination            = "bigquery.googleapis.com/projects/${module.log_export_bigquery.project}/datasets/${module.log_export_bigquery.bigquery_dataset.dataset_id}"
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_project_iam_member" "mds_daily_execution_member" {
  project = module.project_services.project_id
  role    = "roles/bigquery.dataEditor"
  member  = element(concat(google_logging_project_sink.mds_daily_execution[*].writer_identity, [""]), 0)
}

resource "google_logging_project_sink" "vertex_pipeline_execution" {
  name                   = "vertex_pipeline_execution_export"
  project                = var.feature_store_project_id
  filter                 = "jsonPayload.@type=\"type.googleapis.com/google.cloud.aiplatform.logging.PipelineJobLogEntry\" AND (jsonPayload.state=\"PIPELINE_STATE_SUCCEEDED\" OR \"PIPELINE_STATE_FAILED\" OR \"PIPELINE_STATE_CANCELLED\")"
  destination            = "bigquery.googleapis.com/projects/${module.log_export_bigquery.project}/datasets/${module.log_export_bigquery.bigquery_dataset.dataset_id}"
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_project_iam_member" "vertex_pipeline_execution_member" {
  project = module.project_services.project_id
  role    = "roles/bigquery.dataEditor"
  member  = element(concat(google_logging_project_sink.vertex_pipeline_execution[*].writer_identity, [""]), 0)
}

resource "google_logging_project_sink" "activation_pipeline_execution" {
  name                   = "activation_pipeline_execution_export"
  project                = var.activation_project_id
  filter                 = "resource.labels.job_name=\"activation-processing\" AND textPayload=\"Worker pool stopped.\""
  destination            = "bigquery.googleapis.com/projects/${module.log_export_bigquery.project}/datasets/${module.log_export_bigquery.bigquery_dataset.dataset_id}"
  unique_writer_identity = true
  bigquery_options {
    use_partitioned_tables = true
  }
}

resource "google_project_iam_member" "activation_pipeline_execution_member" {
  project = module.project_services.project_id
  role    = "roles/bigquery.dataEditor"
  member  = element(concat(google_logging_project_sink.activation_pipeline_execution[*].writer_identity, [""]), 0)
}

data "template_file" "looker_studio_dashboard_url" {
  template = file("${local.source_root_dir}/templates/looker_studio_create_dashboard_url_template.txt")
  vars = {
    mds_project                    = var.mds_project_id
    monitor_project                = module.project_services.project_id
    feature_store_project          = var.feature_store_project_id
    report_id                      = "f61f65fe-4991-45fc-bcdc-80593966f28c"
    mds_ga4_product_dataset        = "marketing_ga4_v1_${var.mds_dataset_suffix}"
    mds_ga4_base_dataset           = "marketing_ga4_base_${var.mds_dataset_suffix}"
    mds_ads_product_dataset        = "marketing_ads_v1_${var.mds_dataset_suffix}"
    logs_dataset                   = module.log_export_bigquery.bigquery_dataset.dataset_id
    aggregated_vbb_dataset         = "aggregated_vbb"
    aggregated_predictions_dataset = "aggregated_predictions"
    gemini_insights_dataset        = "gemini_insights"
    dataform_log_table_id          = local.dataform_log_table_id
    vertex_pipelines_log_table_id  = local.vertex_pipelines_log_table_id
    dataflow_log_table_id          = local.dataflow_log_table_id
  }
}

data "template_file" "purchase_propensity_prediction_stats_query" {
  template = file("${local.source_root_dir}/templates/purchase_propensity_smart_bidding_view.sql.tpl")
  vars = {
    project_id                  = var.feature_store_project_id
    purchase_propensity_dataset = local.purchase_propensity_dataset
    activation_dataset          = "activation"
  }
}

data "google_bigquery_dataset" "purchase_propensity_dataset" {
  dataset_id = local.purchase_propensity_dataset
  project    = var.feature_store_project_id
}

resource "google_bigquery_table" "purchase_propensity_prediction_stats" {
  project             = var.feature_store_project_id
  dataset_id          = data.google_bigquery_dataset.purchase_propensity_dataset.dataset_id
  table_id            = "purchase_propensity_prediction_stats"
  deletion_protection = false

  view {
    query          = data.template_file.purchase_propensity_prediction_stats_query.rendered
    use_legacy_sql = false
  }
}
