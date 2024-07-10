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
# WITHOUT WARRANTIES OR CONDITI} OF ANY KIND, either express or implied.
# See the License for the specific language governing permissi} and
# limitati} under the License.

# This resource creates a BigQuery table named audience_segmentation_inference_preparation 
# in the dataset specified by google_bigquery_dataset.audience_segmentation.dataset_id.

locals {
  tables = tomap({
    audience_segmentation_inference_preparation = {
      dataset           = "audience_segmentation"
      name              = "audience_segmentation_inference_preparation"
      table_description = "Audience Segmentation Inference Preparation table to be used for Model Prediction"
      schema_file       = "audience_segmentation_inference_preparation.json"
    },
    customer_lifetime_value_inference_preparation = {
      dataset           = "customer_lifetime_value"
      name              = "customer_lifetime_value_inference_preparation"
      table_description = "Customer Lifetime Value Inference Preparation table to be used for Model Prediction"
      schema_file       = "customer_lifetime_value_inference_preparation.json"
    },
    customer_lifetime_value_label = {
      dataset           = "feature_store"
      name              = "customer_lifetime_value_label"
      table_description = "Customer Lifetime Value Label table to be used for Model Traning"
      schema_file       = "customer_lifetime_value_label.json"
    },
    purchase_propensity_inference_preparation = {
      dataset           = "purchase_propensity"
      name              = "purchase_propensity_inference_preparation"
      table_description = "Purchase Propensity Inference Preparation table to be used for Model Prediction"
      schema_file       = "purchase_propensity_inference_preparation.json"
    },
    churn_propensity_inference_preparation = {
      dataset           = "churn_propensity"
      name              = "churn_propensity_inference_preparation"
      table_description = "Purchase Propensity Inference Preparation table to be used for Model Prediction"
      schema_file       = "churn_propensity_inference_preparation.json"
    },
    purchase_propensity_label = {
      dataset           = "feature_store"
      name              = "purchase_propensity_label"
      table_description = "Purchase Propensity Label table to be used for Model Prediction"
      schema_file       = "purchase_propensity_label.json"
    },
    churn_propensity_label = {
      dataset           = "feature_store"
      name              = "churn_propensity_label"
      table_description = "Churn Propensity Label table to be used for Model Prediction"
      schema_file       = "churn_propensity_label.json"
    },
    user_dimensions = {
      dataset           = "feature_store"
      name              = "user_dimensions"
      table_description = "User Dimensions table as part of the Feature Store for the Purchase Propensity use case"
      schema_file       = "user_dimensions.json"
    },
    user_lifetime_dimensions = {
      dataset           = "feature_store"
      name              = "user_lifetime_dimensions"
      table_description = "User Lifetime Dimensions table as part of the Feature Store for the Customer Lifetime Value use case"
      schema_file       = "user_lifetime_dimensions.json"
    },
    user_lookback_metrics = {
      dataset           = "feature_store"
      name              = "user_lookback_metrics"
      table_description = "User Lookback Metrics table as part of the Feature Store"
      schema_file       = "user_lookback_metrics.json"
    },
    user_rolling_window_lifetime_metrics = {
      dataset           = "feature_store"
      name              = "user_rolling_window_lifetime_metrics"
      table_description = "User Rolling Window Lifetime Metrics table as part of the Feature Store for the Customer Lifetime Value use case"
      schema_file       = "user_rolling_window_lifetime_metrics.json"
    },
    user_rolling_window_metrics = {
      dataset           = "feature_store"
      name              = "user_rolling_window_metrics"
      table_description = "User Rolling Window Metrics table as part of the Feature Store for Purchase Propensity use case"
      schema_file       = "user_rolling_window_metrics.json"
    },
    user_scoped_lifetime_metrics = {
      dataset           = "feature_store"
      name              = "user_scoped_lifetime_metrics"
      table_description = "User Scoped Lifetime Metrics table as part of the Feature Store for the Customer Lifetime Value use case"
      schema_file       = "user_scoped_lifetime_metrics.json"
    },
    user_scoped_metrics = {
      dataset           = "feature_store"
      name              = "user_scoped_metrics"
      table_description = "User Scoped Metrics table as part of the Feature Store for the Purchase Propensity use case"
      schema_file       = "user_scoped_metrics.json"
    },
    user_scoped_segmentation_metrics = {
      dataset           = "feature_store"
      name              = "user_scoped_segmentation_metrics"
      table_description = "User Scoped Segmentation Metrics table as part of the Feature Store for Audience Segmentation use case"
      schema_file       = "user_scoped_segmentation_metrics.json"
    },
    user_segmentation_dimensions = {
      dataset           = "feature_store"
      name              = "user_segmentation_dimensions"
      table_description = "User Segmentation Dimensions table as part of the Feature Store for Audience Segmentation use case"
      schema_file       = "user_segmentation_dimensions.json"
    },
    user_session_event_aggregated_metrics = {
      dataset           = "feature_store"
      name              = "user_session_event_aggregated_metrics"
      table_description = "User Session Event Aggregated Metrics table as part of the Feature Store"
      schema_file       = "user_session_event_aggregated_metrics.json"
    },
    vbb_weights = {
      dataset           = "aggregated_vbb"
      name              = "vbb_weights"
      table_description = "Aggregated Value Based Bidding weights table"
      schema_file       = "vbb_weights.json"
    },
    aggregated_value_based_bidding_correlation = {
      dataset           = "aggregated_vbb"
      name              = "aggregated_value_based_bidding_correlation"
      table_description = "Aggregated Value Based Bidding correlation table"
      schema_file       = "aggregated_value_based_bidding_correlation.json"
    },
    aggregated_value_based_bidding_volume_daily = {
      dataset           = "aggregated_vbb"
      name              = "aggregated_value_based_bidding_volume_daily"
      table_description = "Aggregated Value Based Bidding daily volume table"
      schema_file       = "aggregated_value_based_bidding_volume_daily.json"
    },
    aggregated_value_based_bidding_volume_weekly = {
      dataset           = "aggregated_vbb"
      name              = "aggregated_value_based_bidding_volume_weekly"
      table_description = "Aggregated Value Based Bidding weekly volume table"
      schema_file       = "aggregated_value_based_bidding_volume_weekly.json"
    },
    aggregated_predictions_latest = {
      dataset           = "aggregated_predictions"
      name              = "latest"
      table_description = "Stores aggregated predictions generated by the predictions pipelines."
      schema_file       = "aggregated_predictions_latest.json"
    },
    aggregated_user_predictions = {
      dataset           = "aggregated_predictions"
      name              = "user_predictions"
      table_description = "Stores aggregated predictions per user generated by the predictions pipelines."
      schema_file       = "aggregated_predictions_per_user.json"
    },
    user_behaviour_revenue_insights_monthly = {
      dataset           = "gemini_insights"
      name              = "user_behaviour_revenue_insights_monthly"
      table_description = "User Behaviour Revenue monthly insights"
      schema_file       = "user_behaviour_revenue_insights_monthly.json"
    },
    user_behaviour_revenue_insights_weekly = {
      dataset           = "gemini_insights"
      name              = "user_behaviour_revenue_insights_weekly"
      table_description = "User Behaviour Revenue weekly insights"
      schema_file       = "user_behaviour_revenue_insights_weekly.json"
    },
    user_behaviour_revenue_insights_daily = {
      dataset           = "gemini_insights"
      name              = "user_behaviour_revenue_insights_daily"
      table_description = "User Behaviour Revenue daily insights"
      schema_file       = "user_behaviour_revenue_insights_daily.json"
    }
  })
}

resource "google_bigquery_table" "tables" {
  for_each            = local.tables
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.datasets["${each.value.dataset}"].dataset_id
  table_id            = each.value.name
  description         = each.value.table_description
  deletion_protection = false
  labels = {
    version = "prod"
  }
  schema = file("${local.sql_dir}/schema/table/${each.value.schema_file}")
}
