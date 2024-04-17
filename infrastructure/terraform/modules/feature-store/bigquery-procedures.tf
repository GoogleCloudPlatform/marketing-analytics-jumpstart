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

data "local_file" "audience_segmentation_inference_preparation_file" {
  filename = "${local.sql_dir}/procedure/audience_segmentation_inference_preparation.sql"
}

resource "google_bigquery_routine" "audience_segmentation_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "audience_segmentation_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.audience_segmentation_inference_preparation_file.content
  description     = "Procedure that prepares features for Audience Segmentation model inference. User-per-day granularity level features. Run this procedure every time before Audience Segmentation model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


data "local_file" "aggregated_value_based_bidding_training_preparation_file" {
  filename = "${local.sql_dir}/procedure/aggregated_value_based_bidding_training_preparation.sql"
}

resource "google_bigquery_routine" "aggregated_value_based_bidding_training_preparation" {
  project = var.project_id
  dataset_id = google_bigquery_dataset.aggregated_vbb.dataset_id
  routine_id = "aggregated_value_based_bidding_training_preparation"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = data.local_file.aggregated_value_based_bidding_training_preparation_file.content
  description = "Procedure that prepares features for Aggregated VBB model training."
}


# Terraform data source for the procedure. The file contains the procedure definition.
data "local_file" "aggregated_value_based_bidding_explanation_preparation_file" {
  filename = "${local.sql_dir}/procedure/aggregated_value_based_bidding_explanation_preparation.sql"
}

# Terraform procedure resource. This resource will create a BigQuery procedure in the dataset specified.
resource "google_bigquery_routine" "aggregated_value_based_bidding_explanation_preparation" {
  project = var.project_id
  dataset_id = google_bigquery_dataset.aggregated_vbb.dataset_id
  routine_id = "aggregated_value_based_bidding_explanation_preparation"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = data.local_file.aggregated_value_based_bidding_explanation_preparation_file.content
  description = "Procedure that prepares features for Aggregated VBB model explanation."
}


data "local_file" "auto_audience_segmentation_inference_preparation_file" {
  filename = "${local.sql_dir}/procedure/auto_audience_segmentation_inference_preparation.sql"
}

resource "google_bigquery_routine" "auto_audience_segmentation_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.auto_audience_segmentation.dataset_id
  routine_id      = "auto_audience_segmentation_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.auto_audience_segmentation_inference_preparation_file.content
  description     = "Procedure that prepares features for Auto Audience Segmentation model inference. User-per-day granularity level features. Run this procedure every time before Auto Audience Segmentation model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


data "local_file" "audience_segmentation_training_preparation_file" {
  filename = "${local.sql_dir}/procedure/audience_segmentation_training_preparation.sql"
}

resource "google_bigquery_routine" "audience_segmentation_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "audience_segmentation_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.audience_segmentation_training_preparation_file.content
  description     = "Procedure that prepares features for Audience Segmentation model training. User-per-day granularity level features. Run this procedure every time before Audience Segmentation model train."
  arguments {
    name      = "start_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "train_split_end_number"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
  arguments {
    name      = "validation_split_end_number"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}

data "local_file" "auto_audience_segmentation_training_preparation_file" {
  filename = "${local.sql_dir}/procedure/auto_audience_segmentation_training_preparation.sql"
}

resource "google_bigquery_routine" "auto_audience_segmentation_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.auto_audience_segmentation.dataset_id
  routine_id      = "auto_audience_segmentation_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.auto_audience_segmentation_training_preparation_file.content
  description     = "Procedure that prepares features for Auto Audience Segmentation model training. User-per-day granularity level features. Run this procedure every time before Auto Audience Segmentation model train."
  arguments {
    name      = "DATE_START"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "DATE_END"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "LOOKBACK_DAYS"
    mode      = "IN"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "customer_lifetime_value_inference_preparation_file" {
  filename = "${local.sql_dir}/procedure/customer_lifetime_value_inference_preparation.sql"
}

resource "google_bigquery_routine" "customer_lifetime_value_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "customer_lifetime_value_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.customer_lifetime_value_inference_preparation_file.content
  description     = "Procedure that prepares features for CLTV model inference. User-per-day granularity level features. Run this procedure every time before running CLTV model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


data "local_file" "customer_lifetime_value_label_file" {
  filename = "${local.sql_dir}/procedure/customer_lifetime_value_label.sql"
}

resource "google_bigquery_routine" "customer_lifetime_value_label" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "customer_lifetime_value_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.customer_lifetime_value_label_file.content
  description     = "User-per-day granularity level label. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}

data "local_file" "customer_lifetime_value_training_preparation_file" {
  filename = "${local.sql_dir}/procedure/customer_lifetime_value_training_preparation.sql"
}

resource "google_bigquery_routine" "customer_lifetime_value_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "customer_lifetime_value_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.customer_lifetime_value_training_preparation_file.content
  description     = "Procedure that prepares features for CLTV model training. User-per-day granularity level features. Run this procedure every time before CLTV model train."
  arguments {
    name      = "start_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "train_split_end_number"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
  arguments {
    name      = "validation_split_end_number"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "purchase_propensity_inference_preparation_file" {
  filename = "${local.sql_dir}/procedure/purchase_propensity_inference_preparation.sql"
}

resource "google_bigquery_routine" "purchase_propensity_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "purchase_propensity_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.purchase_propensity_inference_preparation_file.content
  description     = "Procedure that prepares features for Purchase Propensity model inference. User-per-day granularity level features. Run this procedure every time before Purchase Propensity model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


data "local_file" "purchase_propensity_label_file" {
  filename = "${local.sql_dir}/procedure/purchase_propensity_label.sql"
}

resource "google_bigquery_routine" "purchase_propensity_label" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.purchase_propensity_label_file.content
  description     = "User-per-day granularity level labels. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "purchase_propensity_training_preparation_file" {
  filename = "${local.sql_dir}/procedure/purchase_propensity_training_preparation.sql"
}

resource "google_bigquery_routine" "purchase_propensity_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "purchase_propensity_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.purchase_propensity_training_preparation_file.content
  description     = "Procedure that prepares features for Purchase Propensity model training. User-per-day granularity level features. Run this procedure every time before Purchase Propensity model train."
  arguments {
    name      = "start_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "train_split_end_number"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
  arguments {
    name      = "validation_split_end_number"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_dimensions_file" {
  filename = "${local.sql_dir}/procedure/user_dimensions.sql"
}

resource "google_bigquery_routine" "user_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_dimensions_file.content
  description     = "User-per-day granularity level dimensions. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_lifetime_dimensions_file" {
  filename = "${local.sql_dir}/procedure/user_lifetime_dimensions.sql"
}

resource "google_bigquery_routine" "user_lifetime_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_lifetime_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_lifetime_dimensions_file.content
  description     = "User-per-day granularity level dimensions. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_lookback_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_lookback_metrics.sql"
}

resource "google_bigquery_routine" "user_lookback_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_lookback_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_lookback_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily. Metrics calculated using a rolling window operation."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_rolling_window_lifetime_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_rolling_window_lifetime_metrics.sql"
}

resource "google_bigquery_routine" "user_rolling_window_lifetime_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_rolling_window_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_rolling_window_lifetime_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily. Metrics calculated using a rolling window operation."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_rolling_window_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_rolling_window_metrics.sql"
}

resource "google_bigquery_routine" "user_rolling_window_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_rolling_window_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily. Metrics calculated using a rolling window operation."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_scoped_lifetime_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_scoped_lifetime_metrics.sql"
}

resource "google_bigquery_routine" "user_scoped_lifetime_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_scoped_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_scoped_lifetime_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_scoped_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_scoped_metrics.sql"
}

resource "google_bigquery_routine" "user_scoped_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_scoped_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_scoped_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_scoped_segmentation_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_scoped_segmentation_metrics.sql"
}

resource "google_bigquery_routine" "user_scoped_segmentation_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_scoped_segmentation_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_scoped_segmentation_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_segmentation_dimensions_file" {
  filename = "${local.sql_dir}/procedure/user_segmentation_dimensions.sql"
}

resource "google_bigquery_routine" "user_segmentation_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_segmentation_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_segmentation_dimensions_file.content
  description     = "User-per-day granularity level dimensions. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}


data "local_file" "user_session_event_aggregated_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_session_event_aggregated_metrics.sql"
}

resource "google_bigquery_routine" "user_session_event_aggregated_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_session_event_aggregated_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.user_session_event_aggregated_metrics_file.content
  description     = "User-per-day granularity level metrics. Run this procedure daily."
  arguments {
    name      = "input_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "end_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
  arguments {
    name      = "rows_added"
    mode      = "OUT"
    data_type = jsonencode({ "typeKind" : "INT64" })
  }
}

data "local_file" "aggregate_predictions_procudure_file" {
  filename = "${local.sql_dir}/procedure/aggregate_predictions_procedure.sql"
}

resource "google_bigquery_routine" "aggregate_last_day_predictions" {
  project         = var.project_id
  dataset_id      = module.aggregated_predictions.bigquery_dataset.dataset_id
  routine_id      = "aggregate_last_day_predictions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.aggregate_predictions_procudure_file.content
}

/*
 *Including the backfill routines
 */

data "local_file" "invoke_backfill_customer_lifetime_value_label_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_customer_lifetime_value_label.sql"
}

resource "google_bigquery_routine" "invoke_backfill_customer_lifetime_value_label" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_customer_lifetime_value_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_customer_lifetime_value_label_file.content
}

data "local_file" "invoke_backfill_purchase_propensity_label_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_purchase_propensity_label.sql"
}

resource "google_bigquery_routine" "invoke_backfill_purchase_propensity_label" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_purchase_propensity_label_file.content
}

data "local_file" "invoke_backfill_user_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_dimensions_file.content
}

data "local_file" "invoke_backfill_user_lifetime_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_lifetime_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_lifetime_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_lifetime_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_lifetime_dimensions_file.content
}


data "local_file" "invoke_backfill_user_lookback_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_lookback_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_lookback_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_lookback_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_lookback_metrics_file.content
}


data "local_file" "invoke_backfill_user_rolling_window_lifetime_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_rolling_window_lifetime_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_rolling_window_lifetime_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_rolling_window_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_rolling_window_lifetime_metrics_file.content
}


data "local_file" "invoke_backfill_user_rolling_window_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_rolling_window_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_rolling_window_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_rolling_window_metrics_file.content
}


data "local_file" "invoke_backfill_user_scoped_lifetime_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_scoped_lifetime_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_scoped_lifetime_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_scoped_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_scoped_lifetime_metrics_file.content
}

data "local_file" "invoke_backfill_user_scoped_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_scoped_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_scoped_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_scoped_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_scoped_metrics_file.content
}

data "local_file" "invoke_backfill_user_scoped_segmentation_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_scoped_segmentation_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_scoped_segmentation_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_scoped_segmentation_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_scoped_segmentation_metrics_file.content
}

data "local_file" "invoke_backfill_user_segmentation_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_segmentation_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_segmentation_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_segmentation_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_segmentation_dimensions_file.content
}

data "local_file" "invoke_backfill_user_session_event_aggregated_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_session_event_aggregated_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_session_event_aggregated_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_session_event_aggregated_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_session_event_aggregated_metrics_file.content
}

/*
 *Including the Inference, Training and Explanation routines
 */


data "local_file" "invoke_customer_lifetime_value_inference_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_customer_lifetime_value_inference_preparation.sql"
}

resource "google_bigquery_routine" "invoke_customer_lifetime_value_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "invoke_customer_lifetime_value_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_customer_lifetime_value_inference_preparation_file.content
}


data "local_file" "invoke_purchase_propensity_inference_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_purchase_propensity_inference_preparation.sql"
}

resource "google_bigquery_routine" "invoke_purchase_propensity_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "invoke_purchase_propensity_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_purchase_propensity_inference_preparation_file.content
}


data "local_file" "invoke_audience_segmentation_inference_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_audience_segmentation_inference_preparation.sql"
}

resource "google_bigquery_routine" "invoke_audience_segmentation_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "invoke_audience_segmentation_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_audience_segmentation_inference_preparation_file.content
}

data "local_file" "invoke_auto_audience_segmentation_inference_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_auto_audience_segmentation_inference_preparation.sql"
}

resource "google_bigquery_routine" "invoke_auto_audience_segmentation_inference_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.auto_audience_segmentation.dataset_id
  routine_id      = "invoke_auto_audience_segmentation_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_auto_audience_segmentation_inference_preparation_file.content
}

data "local_file" "invoke_auto_audience_segmentation_training_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_auto_audience_segmentation_training_preparation.sql"
}

resource "google_bigquery_routine" "invoke_auto_audience_segmentation_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.auto_audience_segmentation.dataset_id
  routine_id      = "invoke_auto_audience_segmentation_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_auto_audience_segmentation_training_preparation_file.content
}


data "local_file" "invoke_customer_lifetime_value_training_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_customer_lifetime_value_training_preparation.sql"
}

resource "google_bigquery_routine" "invoke_customer_lifetime_value_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "invoke_customer_lifetime_value_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_customer_lifetime_value_training_preparation_file.content
}


data "local_file" "invoke_purchase_propensity_training_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_purchase_propensity_training_preparation.sql"
}

resource "google_bigquery_routine" "invoke_purchase_propensity_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "invoke_purchase_propensity_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_purchase_propensity_training_preparation_file.content
}


data "local_file" "invoke_audience_segmentation_training_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_audience_segmentation_training_preparation.sql"
}

resource "google_bigquery_routine" "invoke_audience_segmentation_training_preparation" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "invoke_audience_segmentation_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_audience_segmentation_training_preparation_file.content
}

# Terraform data source for invoking the bigquery stored procedure
data "local_file" "invoke_aggregated_value_based_bidding_training_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_aggregated_value_based_bidding_training_preparation.sql"
}

# Terraform resource for invoking the bigquery stored procedure
resource "google_bigquery_routine" "invoke_aggregated_value_based_bidding_training_preparation" {
  project = var.project_id
  dataset_id = google_bigquery_dataset.aggregated_vbb.dataset_id
  routine_id = "invoke_aggregated_value_based_bidding_training_preparation"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = data.local_file.invoke_aggregated_value_based_bidding_training_preparation_file.content
}

# Terraform data source for invoking the bigquery stored procedure
data "local_file" "invoke_aggregated_value_based_bidding_explanation_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_aggregated_value_based_bidding_explanation_preparation.sql"
}

# Terraform resource for invoking the bigquery stored procedure
resource "google_bigquery_routine" "invoke_aggregated_value_based_bidding_explanation_preparation" {
  project = var.project_id
  dataset_id = google_bigquery_dataset.aggregated_vbb.dataset_id
  routine_id = "invoke_aggregated_value_based_bidding_explanation_preparation"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = data.local_file.invoke_aggregated_value_based_bidding_explanation_preparation_file.content
}

/*
 *Including the Feature Engineering invocation queries
 */

data "local_file" "invoke_customer_lifetime_value_label_file" {
  filename = "${local.sql_dir}/query/invoke_customer_lifetime_value_label.sql"
}

resource "google_bigquery_routine" "invoke_customer_lifetime_value_label" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_customer_lifetime_value_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_customer_lifetime_value_label_file.content
}

data "local_file" "invoke_purchase_propensity_label_file" {
  filename = "${local.sql_dir}/query/invoke_purchase_propensity_label.sql"
}

resource "google_bigquery_routine" "invoke_purchase_propensity_label" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_purchase_propensity_label_file.content
}

data "local_file" "invoke_user_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_user_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_user_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_dimensions_file.content
}

data "local_file" "invoke_user_lifetime_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_user_lifetime_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_user_lifetime_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_lifetime_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_lifetime_dimensions_file.content
}


data "local_file" "invoke_user_lookback_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_lookback_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_lookback_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_lookback_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_lookback_metrics_file.content
}


data "local_file" "invoke_user_rolling_window_lifetime_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_rolling_window_lifetime_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_rolling_window_lifetime_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_rolling_window_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_rolling_window_lifetime_metrics_file.content
}


data "local_file" "invoke_user_rolling_window_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_rolling_window_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_rolling_window_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_rolling_window_metrics_file.content
}


data "local_file" "invoke_user_scoped_lifetime_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_scoped_lifetime_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_scoped_lifetime_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_scoped_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_scoped_lifetime_metrics_file.content
}

data "local_file" "invoke_user_scoped_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_scoped_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_scoped_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_scoped_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_scoped_metrics_file.content
}

data "local_file" "invoke_user_scoped_segmentation_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_scoped_segmentation_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_scoped_segmentation_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_scoped_segmentation_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_scoped_segmentation_metrics_file.content
}

data "local_file" "invoke_user_segmentation_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_user_segmentation_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_user_segmentation_dimensions" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_segmentation_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_segmentation_dimensions_file.content
}

data "local_file" "invoke_user_session_event_aggregated_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_session_event_aggregated_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_session_event_aggregated_metrics" {
  project         = var.project_id
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_session_event_aggregated_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_session_event_aggregated_metrics_file.content
}

/*
 * Invoking training routines
 */


resource "google_bigquery_job" "job_invoke_customer_lifetime_value_training_preparation" {
  project = var.project_id
  job_id  = uuid()
  query {
    query              = "CALL `${local.config_bigquery.dataset.customer_lifetime_value.project_id}.${local.config_bigquery.dataset.customer_lifetime_value.name}.invoke_customer_lifetime_value_training_preparation`();"
    create_disposition = ""
    write_disposition  = ""
  }
  location = local.config_bigquery.dataset.customer_lifetime_value.location

  depends_on = [google_bigquery_routine.invoke_customer_lifetime_value_training_preparation]
}

resource "google_bigquery_job" "job_invoke_purchase_propensity_training_preparation" {
  project = var.project_id
  job_id  = uuid()
  query {
    query              = "CALL `${local.config_bigquery.dataset.purchase_propensity.project_id}.${local.config_bigquery.dataset.purchase_propensity.name}.invoke_purchase_propensity_training_preparation`();"
    create_disposition = ""
    write_disposition  = ""
  }
  location = local.config_bigquery.dataset.purchase_propensity.location

  depends_on = [google_bigquery_routine.invoke_purchase_propensity_training_preparation]
}

resource "google_bigquery_job" "job_invoke_audience_segmentation_training_preparation" {
  project = var.project_id
  job_id  = uuid()
  query {
    query              = "CALL `${local.config_bigquery.dataset.audience_segmentation.project_id}.${local.config_bigquery.dataset.audience_segmentation.name}.invoke_audience_segmentation_training_preparation`();"
    create_disposition = ""
    write_disposition  = ""
  }
  location = local.config_bigquery.dataset.audience_segmentation.location

  depends_on = [google_bigquery_routine.invoke_audience_segmentation_training_preparation]
}