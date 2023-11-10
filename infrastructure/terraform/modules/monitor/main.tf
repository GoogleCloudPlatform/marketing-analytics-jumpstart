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
  source_root_dir = "../.."
  dataset_name    = "maj_dashboard"
  link_load_file  = "load_links.json"

  base_url          = "https://console.cloud.google.com"
  bq_base_url       = "${local.base_url}/bigquery"
  vertex_base_url   = "${local.base_url}/vertex-ai"
  dataflow_base_url = "${local.base_url}/dataflow"
  dataform_base_url = "${local.bq_base_url}/dataform"

  p_key                = "project"
  ws_key               = "ws"
  ws_value_for_dataset = "!1m4!1m3!3m2"
  ws_value_for_table   = "!1m5!1m4!4m3"
  first_separator      = "!1s"
  second_separator     = "!2s"
  third_separator      = "!3s"

  mds_project_url_param           = "${local.p_key}=${var.mds_project_id}"
  feature_store_project_url_param = "${local.p_key}=${var.feature_store_project_id}"
  activation_project_url_param    = "${local.p_key}=${var.activation_project_id}"

  mds_dataset_url_base           = "${local.bq_base_url}?${local.mds_project_url_param}&${local.ws_key}=${local.ws_value_for_dataset}${local.first_separator}${var.mds_project_id}${local.second_separator}"
  feature_store_dataset_url_base = "${local.bq_base_url}?${local.feature_store_project_url_param}&${local.ws_key}=${local.ws_value_for_dataset}${local.first_separator}${var.feature_store_project_id}${local.second_separator}"
  activation_dataset_url_base    = "${local.bq_base_url}?${local.activation_project_url_param}&${local.ws_key}=${local.ws_value_for_dataset}${local.first_separator}${var.activation_project_id}${local.second_separator}"

  mds_table_url_base = "${local.bq_base_url}?${local.mds_project_url_param}&${local.ws_key}=${local.ws_value_for_table}${local.first_separator}${var.mds_project_id}${local.second_separator}marketing_ga4_v1_${var.mds_dataset_suffix}${local.third_separator}"

  dataform_repository_url_base = "${local.dataform_base_url}/locations/${var.mds_location}/repositories/marketing-analytics"
  dataform_graph_url           = "${local.dataform_repository_url_base}/workspaces/${var.mds_dataform_workspace}/actions?${local.mds_project_url_param}"
  dataform_workflows_url       = "${local.dataform_repository_url_base}/details/workflows?${local.mds_project_url_param}"

  vertex_pipelines_url_base = "${local.vertex_base_url}/pipelines"
  vertex_pipelines_url      = "${local.vertex_pipelines_url_base}/templates?${local.feature_store_project_url_param}"
  vertex_pipelines_runs_url = "${local.vertex_pipelines_url_base}/runs?${local.feature_store_project_url_param}"
  vertex_models_url         = "${local.vertex_base_url}/models?${local.feature_store_project_url_param}"

  activation_pipelines_runs_url = "${local.dataflow_base_url}/jobs?${local.activation_project_url_param}"
}

module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "~> 5.4"

  dataset_id                 = local.dataset_name
  dataset_name               = local.dataset_name
  description                = "providing links to looker dashboard"
  project_id                 = var.project_id
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
  version       = "~> 3.4.1"
  project_id    = var.project_id
  name          = "maj-monitor-${var.project_id}"
  location      = var.location
  force_destroy = true
}

data "template_file" "resource_link_content" {
  template = file("${local.source_root_dir}/templates/monitoring_resource_link_template.tpl")
  vars = {
    mds_dataset_url_base           = local.mds_dataset_url_base
    mds_dataset_suffix             = var.mds_dataset_suffix
    dataform_graph_url             = local.dataform_graph_url
    feature_store_dataset_url_base = local.feature_store_dataset_url_base
    vertex_pipelines_url           = local.vertex_pipelines_url
    vertex_models_url              = local.vertex_models_url
    mds_table_url_base             = local.mds_table_url_base
    activation_dataset_url_base    = local.activation_dataset_url_base
    dataform_workflows_url         = local.dataform_workflows_url
    vertex_pipelines_runs_url      = local.vertex_pipelines_runs_url
    activation_pipelines_runs_url  = local.activation_pipelines_runs_url
  }
}
resource "google_storage_bucket_object" "resource_link_load_file" {
  name    = local.link_load_file
  bucket  = module.load_bucket.name
  content = data.template_file.resource_link_content.rendered
}

resource "google_bigquery_job" "monitor_resources_load" {
  job_id  = uuid()
  project = var.project_id
  load {
    source_uris = [
      "gs://${module.load_bucket.name}/${google_storage_bucket_object.resource_link_load_file.output_name}",
    ]
    destination_table {
      project_id = var.project_id
      dataset_id = module.bigquery.bigquery_dataset.dataset_id
      table_id   = module.bigquery.table_ids[0]
    }
    write_disposition = "WRITE_TRUNCATE"
  }
  location = var.location
}