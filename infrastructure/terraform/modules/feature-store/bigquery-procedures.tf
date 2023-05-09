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

resource "google_bigquery_routine" "audience_segmentation_inference_preparation" {
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "audience_segmentation_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/audience_segmentation_inference_preparation.sql") : null
  description     = "Procedure that prepares features for Audience Segmentation model inference. User-per-day granularity level features. Run this procedure every time before Audience Segmentation model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


resource "google_bigquery_routine" "audience_segmentation_training_preparation" {
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "audience_segmentation_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/audience_segmentation_training_preparation.sql") : null
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


resource "google_bigquery_routine" "customer_lifetime_value_inference_preparation" {
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "customer_lifetime_value_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/customer_lifetime_value_inference_preparation.sql") : null
  description     = "Procedure that prepares features for CLTV model inference. User-per-day granularity level features. Run this procedure every time before running CLTV model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


resource "google_bigquery_routine" "customer_lifetime_value_label" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "customer_lifetime_value_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/customer_lifetime_value_label.sql") : null
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

resource "google_bigquery_routine" "customer_lifetime_value_training_preparation" {
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "customer_lifetime_value_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/customer_lifetime_value_training_preparation.sql") : null
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


resource "google_bigquery_routine" "purchase_propensity_inference_preparation" {
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "purchase_propensity_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/purchase_propensity_inference_preparation.sql") : null
  description     = "Procedure that prepares features for Purchase Propensity model inference. User-per-day granularity level features. Run this procedure every time before Purchase Propensity model predict."
  arguments {
    name      = "inference_date"
    mode      = "INOUT"
    data_type = jsonencode({ "typeKind" : "DATE" })
  }
}


resource "google_bigquery_routine" "purchase_propensity_label" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/purchase_propensity_label.sql") : null
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


resource "google_bigquery_routine" "purchase_propensity_training_preparation" {
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "purchase_propensity_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/purchase_propensity_training_preparation.sql") : null
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


resource "google_bigquery_routine" "user_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_dimensions.sql") : null
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


resource "google_bigquery_routine" "user_lifetime_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_lifetime_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_lifetime_dimensions.sql") : null
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


resource "google_bigquery_routine" "user_lookback_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_lookback_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_lookback_metrics.sql") : null
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


resource "google_bigquery_routine" "user_rolling_window_lifetime_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_rolling_window_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_rolling_window_lifetime_metrics.sql") : null
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


resource "google_bigquery_routine" "user_rolling_window_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_rolling_window_metrics.sql") : null
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


resource "google_bigquery_routine" "user_scoped_lifetime_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_scoped_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_scoped_lifetime_metrics.sql") : null
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


resource "google_bigquery_routine" "user_scoped_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_scoped_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_scoped_metrics.sql") : null
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


resource "google_bigquery_routine" "user_scoped_segmentation_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_scoped_segmentation_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_scoped_segmentation_metrics.sql") : null
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


resource "google_bigquery_routine" "user_segmentation_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_segmentation_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_segmentation_dimensions.sql") : null
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


resource "google_bigquery_routine" "user_session_event_aggregated_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "user_session_event_aggregated_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/procedure/user_session_event_aggregated_metrics.sql") : null
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


/*
 *Including the backfill routines
 */

resource "google_bigquery_routine" "invoke_backfill_customer_lifetime_value_label" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_customer_lifetime_value_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_customer_lifetime_value_label.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_purchase_propensity_label" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_purchase_propensity_label.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_user_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_dimensions.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_user_lifetime_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_lifetime_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_lifetime_dimensions.sql") : null
}


resource "google_bigquery_routine" "invoke_backfill_user_lookback_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_lookback_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_lookback_metrics.sql") : null
}


resource "google_bigquery_routine" "invoke_backfill_user_rolling_window_lifetime_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_rolling_window_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_rolling_window_lifetime_metrics.sql") : null
}


resource "google_bigquery_routine" "invoke_backfill_user_rolling_window_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_rolling_window_metrics.sql") : null
}


resource "google_bigquery_routine" "invoke_backfill_user_scoped_lifetime_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_scoped_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_scoped_lifetime_metrics.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_user_scoped_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_scoped_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_scoped_metrics.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_user_scoped_segmentation_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_scoped_segmentation_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_scoped_segmentation_metrics.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_user_segmentation_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_segmentation_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_segmentation_dimensions.sql") : null
}

resource "google_bigquery_routine" "invoke_backfill_user_session_event_aggregated_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_backfill_user_session_event_aggregated_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_backfill_user_session_event_aggregated_metrics.sql") : null
}

/*
 *Including the Inference and Training routines
 */


resource "google_bigquery_routine" "invoke_customer_lifetime_value_inference_preparation" {
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "invoke_customer_lifetime_value_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_customer_lifetime_value_inference_preparation.sql") : null
}


resource "google_bigquery_routine" "invoke_purchase_propensity_inference_preparation" {
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "invoke_purchase_propensity_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_purchase_propensity_inference_preparation.sql") : null
}


resource "google_bigquery_routine" "invoke_audience_segmentation_inference_preparation" {
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "invoke_audience_segmentation_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_audience_segmentation_inference_preparation.sql") : null
}





resource "google_bigquery_routine" "invoke_customer_lifetime_value_training_preparation" {
  dataset_id      = google_bigquery_dataset.customer_lifetime_value.dataset_id
  routine_id      = "invoke_customer_lifetime_value_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_customer_lifetime_value_training_preparation.sql") : null
}


resource "google_bigquery_routine" "invoke_purchase_propensity_training_preparation" {
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "invoke_purchase_propensity_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_purchase_propensity_training_preparation.sql") : null
}


resource "google_bigquery_routine" "invoke_audience_segmentation_training_preparation" {
  dataset_id      = google_bigquery_dataset.audience_segmentation.dataset_id
  routine_id      = "invoke_audience_segmentation_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_audience_segmentation_training_preparation.sql") : null
}

/*
 *Including the Feature Engineering invocation queries
 */

resource "google_bigquery_routine" "invoke_customer_lifetime_value_label" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_customer_lifetime_value_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_customer_lifetime_value_label.sql") : null
}

resource "google_bigquery_routine" "invoke_purchase_propensity_label" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_purchase_propensity_label.sql") : null
}

resource "google_bigquery_routine" "invoke_user_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_dimensions.sql") : null
}

resource "google_bigquery_routine" "invoke_user_lifetime_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_lifetime_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_lifetime_dimensions.sql") : null
}


resource "google_bigquery_routine" "invoke_user_lookback_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_lookback_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_lookback_metrics.sql") : null
}


resource "google_bigquery_routine" "invoke_user_rolling_window_lifetime_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_rolling_window_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_rolling_window_lifetime_metrics.sql") : null
}


resource "google_bigquery_routine" "invoke_user_rolling_window_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_rolling_window_metrics.sql") : null
}


resource "google_bigquery_routine" "invoke_user_scoped_lifetime_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_scoped_lifetime_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_scoped_lifetime_metrics.sql") : null
}

resource "google_bigquery_routine" "invoke_user_scoped_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_scoped_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_scoped_metrics.sql") : null
}

resource "google_bigquery_routine" "invoke_user_scoped_segmentation_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_scoped_segmentation_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_scoped_segmentation_metrics.sql") : null
}

resource "google_bigquery_routine" "invoke_user_segmentation_dimensions" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_segmentation_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_segmentation_dimensions.sql") : null
}

resource "google_bigquery_routine" "invoke_user_session_event_aggregated_metrics" {
  dataset_id      = google_bigquery_dataset.feature_store.dataset_id
  routine_id      = "invoke_user_session_event_aggregated_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = var.enabled ? file("${local.sql_dir}/query/invoke_user_session_event_aggregated_metrics.sql") : null
}

/*
 * Invoking training routines
 */


resource "google_bigquery_job" "job_invoke_customer_lifetime_value_training_preparation" {
  job_id     = uuid()
  query {
    query = "CALL `${local.config_bigquery.dataset.customer_lifetime_value.project_id}.${local.config_bigquery.dataset.customer_lifetime_value.name}.invoke_customer_lifetime_value_training_preparation`();"
    create_disposition = ""
    write_disposition = ""
    }
  
  depends_on = [google_bigquery_routine.invoke_customer_lifetime_value_training_preparation]  
}

resource "google_bigquery_job" "job_invoke_purchase_propensity_training_preparation" {
  job_id     = uuid()
  query {
    query = "CALL `${local.config_bigquery.dataset.purchase_propensity.project_id}.${local.config_bigquery.dataset.purchase_propensity.name}.invoke_purchase_propensity_training_preparation`();"
    create_disposition = ""
    write_disposition = ""
    }  
  
  depends_on = [google_bigquery_routine.invoke_purchase_propensity_training_preparation]
}

resource "google_bigquery_job" "job_invoke_audience_segmentation_training_preparation" {
  job_id     = uuid()
  query {
    query = "CALL `${local.config_bigquery.dataset.audience_segmentation.project_id}.${local.config_bigquery.dataset.audience_segmentation.name}.invoke_audience_segmentation_training_preparation`();"
    create_disposition = ""
    write_disposition = ""
    }
  
  depends_on = [google_bigquery_routine.invoke_audience_segmentation_training_preparation]  
}