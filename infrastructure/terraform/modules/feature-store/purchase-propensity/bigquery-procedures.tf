# Copyright 2025 Google LLC
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


# This resource reads the contents of a local SQL file named purchase_propensity_inference_preparation.sql and 
# stores it in a variable named purchase_propensity_inference_preparation_file.content. 
# The SQL file is expected to contain the definition of a BigQuery procedure named purchase_propensity_inference_preparation.
data "local_file" "purchase_propensity_inference_preparation_file" {
  filename = "${local.sql_dir}/procedure/purchase_propensity_inference_preparation.sql"
}

# The purchase_propensity_inference_preparation procedure is designed to prepare features for the Purchase Propensity model.
# ##
# The procedure is typically invoked before prediction the Purchase Propensity model to ensure that the features data 
# is in the correct format and contains the necessary features for prediction.
resource "google_bigquery_routine" "purchase_propensity_inference_preparation" {
  project         = local.purchase_propensity_project_id
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

# This resource reads the contents of a local SQL file named purchase_propensity_label.sql and 
# stores it in a variable named purchase_propensity_label_file.content. 
# The SQL file is expected to contain the definition of a BigQuery procedure named purchase_propensity_label.
data "local_file" "purchase_propensity_label_file" {
  filename = "${local.sql_dir}/procedure/purchase_propensity_label.sql"
}

# The purchase_propensity_label procedure is designed to prepare label for the Purchase Propensity model.
# ##
# The procedure is typically invoked before training the Purchase Propensity model to ensure that the labeled data 
# is in the correct format and ready for training.
resource "google_bigquery_routine" "purchase_propensity_label" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
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

# This resource reads the contents of a local SQL file named purchase_propensity_training_preparation.sql and 
# stores it in a variable named purchase_propensity_training_preparation_file.content. 
# The SQL file is expected to contain the definition of a BigQuery procedure named purchase_propensity_training_preparation.
data "local_file" "purchase_propensity_training_preparation_file" {
  filename = "${local.sql_dir}/procedure/purchase_propensity_training_preparation.sql"
}

# The purchase_propensity_training_preparation procedure is designed to prepare features for the Purchase Propensity model.
# ##
# The procedure is typically invoked before training the Purchase Propensity model to ensure that the features data 
# is in the correct format and contains the necessary features for training.
resource "google_bigquery_routine" "purchase_propensity_training_preparation" {
  project         = local.purchase_propensity_project_id
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

# This resource reads the contents of a local SQL file named user_dimensions.sql and 
# stores it in a variable named user_dimensions_file.content. 
# The SQL file is expected to contain the definition of a BigQuery procedure named user_dimensions.
data "local_file" "user_dimensions_file" {
  filename = "${local.sql_dir}/procedure/user_dimensions.sql"
}

# The user_dimensions procedure is designed to prepare the features for the Purchase Propensity model.
# ##
# The procedure is typically invoked before training the Purchase Propensity model to ensure that the features data 
# is in the correct format and ready for training.
resource "google_bigquery_routine" "user_dimensions" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
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

# This resource reads the contents of a local SQL file named user_rolling_window_metrics.sql and 
# stores it in a variable named user_rolling_window_metrics_file.content. 
# The SQL file is expected to contain the definition of a BigQuery procedure named user_rolling_window_metrics.
data "local_file" "user_rolling_window_metrics_file" {
  filename = "${local.sql_dir}/procedure/user_rolling_window_metrics.sql"
}

# The user_rolling_window_metrics procedure is designed to prepare the features for the Purchase Propensity model.
# ##
# The procedure is typically invoked before training the Purchase Propensity model to ensure that the features data 
# is in the correct format and ready for training.
resource "google_bigquery_routine" "user_rolling_window_metrics" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
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


data "local_file" "invoke_backfill_purchase_propensity_label_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_purchase_propensity_label.sql"
}

resource "google_bigquery_routine" "invoke_backfill_purchase_propensity_label" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
  routine_id      = "invoke_backfill_purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_purchase_propensity_label_file.content
  description     = "Procedure that backfills the purchase_propensity_label feature table. Run this procedure occasionally before training the models."
}


data "local_file" "invoke_backfill_user_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_dimensions" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
  routine_id      = "invoke_backfill_user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_dimensions_file.content
  description     = "Procedure that backfills the user_dimensions feature table. Run this procedure occasionally before training the models."
}


data "local_file" "invoke_backfill_user_rolling_window_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_backfill_user_rolling_window_metrics.sql"
}

resource "google_bigquery_routine" "invoke_backfill_user_rolling_window_metrics" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
  routine_id      = "invoke_backfill_user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_backfill_user_rolling_window_metrics_file.content
  description     = "Procedure that backfills the user_rolling_window_metrics feature table. Run this procedure occasionally before training the models."
}


data "local_file" "invoke_purchase_propensity_inference_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_purchase_propensity_inference_preparation.sql"
}

resource "google_bigquery_routine" "invoke_purchase_propensity_inference_preparation" {
  project         = local.purchase_propensity_project_id
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "invoke_purchase_propensity_inference_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_purchase_propensity_inference_preparation_file.content
}


data "local_file" "invoke_purchase_propensity_training_preparation_file" {
  filename = "${local.sql_dir}/query/invoke_purchase_propensity_training_preparation.sql"
}

resource "google_bigquery_routine" "invoke_purchase_propensity_training_preparation" {
  project         = local.purchase_propensity_project_id
  dataset_id      = google_bigquery_dataset.purchase_propensity.dataset_id
  routine_id      = "invoke_purchase_propensity_training_preparation"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_purchase_propensity_training_preparation_file.content
}


data "local_file" "invoke_purchase_propensity_label_file" {
  filename = "${local.sql_dir}/query/invoke_purchase_propensity_label.sql"
}

resource "google_bigquery_routine" "invoke_purchase_propensity_label" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
  routine_id      = "invoke_purchase_propensity_label"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_purchase_propensity_label_file.content
  description     = "Procedure that invokes the purchase_propensity_label table. Daily granularity level. Run this procedure daily before running prediction pipelines."
}


data "local_file" "invoke_user_dimensions_file" {
  filename = "${local.sql_dir}/query/invoke_user_dimensions.sql"
}

resource "google_bigquery_routine" "invoke_user_dimensions" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
  routine_id      = "invoke_user_dimensions"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_dimensions_file.content
  description     = "Procedure that invokes the user_dimensions table. Daily granularity level. Run this procedure daily before running prediction pipelines."
}


data "local_file" "invoke_user_rolling_window_metrics_file" {
  filename = "${local.sql_dir}/query/invoke_user_rolling_window_metrics.sql"
}

resource "google_bigquery_routine" "invoke_user_rolling_window_metrics" {
  project         = local.feature_store_project_id
  dataset_id      = var.feature_store_dataset_id
  routine_id      = "invoke_user_rolling_window_metrics"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.local_file.invoke_user_rolling_window_metrics_file.content
  description     = "Procedure that invokes the user_rolling_window table. Daily granularity level. Run this procedure daily before running prediction pipelines."
}