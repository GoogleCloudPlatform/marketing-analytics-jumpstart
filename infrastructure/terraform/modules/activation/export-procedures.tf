# Copyright 2024 Google LLC
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

data "template_file" "purchase_propensity_csv_export_query" {
  template = file("${local.source_root_dir}/templates/activation_user_import/purchase_propensity_csv_export.sqlx")
  vars = {
    ga4_stream_id = var.ga4_stream_id
    export_bucket = module.pipeline_bucket.name
  }
}

resource "google_bigquery_routine" "export_purchase_propensity_procedure" {
  project         = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : var.project_id
  dataset_id      = module.bigquery.bigquery_dataset.dataset_id
  routine_id      = "export_purchase_propensity_predictions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.purchase_propensity_csv_export_query.rendered
  description     = "Export purchase propensity predictions as CSV for GA4 User Data Import"
  arguments {
    name      = "prediction_table_name"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "STRING" })
  }
}

data "template_file" "cltv_csv_export_query" {
  template = file("${local.source_root_dir}/templates/activation_user_import/cltv_csv_export.sqlx")
  vars = {
    ga4_stream_id = var.ga4_stream_id
    export_bucket = module.pipeline_bucket.name
  }
}

resource "google_bigquery_routine" "export_cltv_procedure" {
  project         = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : var.project_id
  dataset_id      = module.bigquery.bigquery_dataset.dataset_id
  routine_id      = "export_cltv_predictions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.cltv_csv_export_query.rendered
  description     = "Export customer liftime value predictions as CSV for GA4 User Data Import"
  arguments {
    name      = "prediction_table_name"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "STRING" })
  }
}

data "template_file" "audience_segmentation_csv_export_query" {
  template = file("${local.source_root_dir}/templates/activation_user_import/audience_segmentation_csv_export.sqlx")
  vars = {
    ga4_stream_id = var.ga4_stream_id
    export_bucket = module.pipeline_bucket.name
  }
}

resource "google_bigquery_routine" "export_audience_segmentation_procedure" {
  project         = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : var.project_id
  dataset_id      = module.bigquery.bigquery_dataset.dataset_id
  routine_id      = "export_audience_segmentation_predictions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.audience_segmentation_csv_export_query.rendered
  description     = "Export audience segmentation predictions as CSV for GA4 User Data Import"
  arguments {
    name      = "prediction_table_name"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "STRING" })
  }
}

data "template_file" "auto_audience_segmentation_csv_export_query" {
  template = file("${local.source_root_dir}/templates/activation_user_import/auto_audience_segmentation_csv_export.sqlx")
  vars = {
    ga4_stream_id = var.ga4_stream_id
    export_bucket = module.pipeline_bucket.name
  }
}

resource "google_bigquery_routine" "export_auto_audience_segmentation_procedure" {
  project         = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : var.project_id
  dataset_id      = module.bigquery.bigquery_dataset.dataset_id
  routine_id      = "export_auto_audience_segmentation_predictions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.auto_audience_segmentation_csv_export_query.rendered
  description     = "Export behavior based audience segmentation predictions as CSV for GA4 User Data Import"
  arguments {
    name      = "prediction_table_name"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "STRING" })
  }
}

data "template_file" "churn_propensity_csv_export_query" {
  template = file("${local.source_root_dir}/templates/activation_user_import/churn_propensity_csv_export.sqlx")
  vars = {
    ga4_stream_id = var.ga4_stream_id
    export_bucket = module.pipeline_bucket.name
  }
}

resource "google_bigquery_routine" "export_churn_propensity_procedure" {
  project         = null_resource.check_bigquery_api.id != "" ? module.project_services.project_id : var.project_id
  dataset_id      = module.bigquery.bigquery_dataset.dataset_id
  routine_id      = "export_churn_propensity_predictions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.churn_propensity_csv_export_query.rendered
  description     = "Export purchase propensity predictions as CSV for GA4 User Data Import"
  arguments {
    name      = "prediction_table_name"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "STRING" })
  }
}
