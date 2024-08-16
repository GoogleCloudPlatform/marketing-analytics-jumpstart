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

from typing import Optional
import kfp as kfp
import kfp.dsl as dsl
from pipelines.components.bigquery.component import bq_stored_procedure_exec as sp
from pipelines.components.bigquery.component import (
    bq_dynamic_query_exec_output, 
    bq_dynamic_stored_procedure_exec_output_full_dataset_preparation)


@dsl.pipeline()
def auto_audience_segmentation_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    dataset: str,
    date_start: str,
    date_end: str,
    feature_table: str,
    mds_project_id: str,
    mds_dataset: str,
    stored_procedure_name: str,
    full_dataset_table: str,
    reg_expression: str,
    query_auto_audience_segmentation_inference_preparation: str,
    query_auto_audience_segmentation_training_preparation: str,
    perc_keep: int = 35,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for feature engineering for the auto audience segmentation model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        dataset: The BigQuery dataset where the raw data is stored.
        date_start: The start date for the data to be processed.
        date_end: The end date for the data to be processed.
        feature_table: The BigQuery table where the feature data will be stored.
        mds_project_id: The Google Cloud project ID where the Marketing Data Store (MDS) is located.
        mds_dataset: The MDS dataset where the product data is stored.
        stored_procedure_name: The name of the BigQuery stored procedure that will be used to prepare the full dataset.
        full_dataset_table: The BigQuery table where the full dataset will be stored.
        #training_table: The BigQuery table where the training data will be stored.
        #inference_table: The BigQuery table where the inference data will be stored.
        reg_expression: The regular expression that will be used to identify the pages to be included in the analysis.
        query_auto_audience_segmentation_inference_preparation: The SQL query that will be used to prepare the inference data.
        query_auto_audience_segmentation_training_preparation: The SQL query that will be used to prepare the training data.
        perc_keep: The percentage of pages to be included in the analysis.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """
    # Feature data preparation
    feature_table_preparation = bq_dynamic_query_exec_output(
        location=location,
        project_id=project_id,
        dataset=dataset,
        create_table=feature_table,
        mds_project_id=mds_project_id,
        mds_dataset=mds_dataset,
        date_start=date_start,
        date_end=date_end,
        perc_keep=perc_keep,
        reg_expression=reg_expression
    )

    full_dataset_table_preparation = bq_dynamic_stored_procedure_exec_output_full_dataset_preparation(
        location=location,
        project_id=project_id,
        dataset=dataset,
        mds_project_id=mds_project_id,
        mds_dataset=mds_dataset,
        dynamic_table_input=feature_table_preparation.outputs['destination_table'],
        stored_procedure_name=stored_procedure_name,
        full_dataset_table=full_dataset_table,
        reg_expression=reg_expression
    ).after(*[feature_table_preparation])

    # Training data preparation
    auto_audience_segmentation_training_prep = sp(
        project=project_id,
        location=location,
        query=query_auto_audience_segmentation_training_preparation,
        timeout=timeout).after(*[full_dataset_table_preparation]).set_display_name('auto_audience_segmentation_training_preparation')

    
    # Inference data preparation
    auto_audience_segmentation_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_auto_audience_segmentation_inference_preparation,
        timeout=timeout).after(*[auto_audience_segmentation_training_prep]).set_display_name('auto_audience_segmentation_inference_preparation')


@dsl.pipeline()
def aggregated_value_based_bidding_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    query_aggregated_value_based_bidding_training_preparation: str,
    query_aggregated_value_based_bidding_explanation_preparation: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for feature engineering for the aggregated value based bidding model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_aggregated_value_based_bidding_training_preparation: The SQL query that will be used to prepare the training data.
        query_aggregated_value_based_bidding_explanation_preparation: The SQL query that will be used to prepare the explanation data.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """

    # Training data preparation
    training_table_preparation = sp(
        project=project_id,
        location=location,
        query=query_aggregated_value_based_bidding_training_preparation,
        timeout=timeout).set_display_name('aggregated_value_based_bidding_training_preparation')
    
    # Explanation data preparation
    explanation_table_preparation = sp(
        project=project_id,
        location=location,
        query=query_aggregated_value_based_bidding_explanation_preparation,
        timeout=timeout).set_display_name('aggregated_value_based_bidding_explanation_preparation')


@dsl.pipeline()
def audience_segmentation_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    query_user_lookback_metrics: str,
    query_user_segmentation_dimensions: str,
    query_audience_segmentation_inference_preparation: str,
    query_audience_segmentation_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for feature engineering for the audience segmentation model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_user_lookback_metrics: The SQL query that will be used to calculate the user lookback metrics.
        query_user_segmentation_dimensions: The SQL query that will be used to calculate the user segmentation dimensions.
        query_audience_segmentation_inference_preparation: The SQL query that will be used to prepare the inference data.
        query_audience_segmentation_training_preparation: The SQL query that will be used to prepare the training data.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """

    # Features Preparation
    phase_1 = list()
    phase_1.append(sp(
        project=project_id,
        location=location,
        query=query_user_lookback_metrics,
        timeout=timeout).set_display_name('user_lookback_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_segmentation_dimensions,
            timeout=timeout).set_display_name('user_segmentation_dimensions')
    )
    # Training data preparation
    audience_segmentation_train_prep = sp(
        project=project_id,
        location=location,
        query=query_audience_segmentation_training_preparation,
        timeout=timeout).set_display_name('audience_segmentation_training_preparation').after(*phase_1)
    # Inference data preparation
    audience_segmentation_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_audience_segmentation_inference_preparation,
        timeout=timeout).set_display_name('audience_segmentation_inference_preparation').after(*phase_1)
  
      
@dsl.pipeline()
def purchase_propensity_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    query_purchase_propensity_label: str,
    query_user_dimensions: str,
    query_user_rolling_window_metrics: str,
    query_purchase_propensity_inference_preparation: str,
    query_purchase_propensity_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for feature engineering for the purchase propensity model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_purchase_propensity_label: The SQL query that will be used to calculate the purchase propensity label.
        query_user_dimensions: The SQL query that will be used to calculate the user dimensions.
        query_user_rolling_window_metrics: The SQL query that will be used to calculate the user rolling window metrics.
        query_purchase_propensity_inference_preparation: The SQL query that will be used to prepare the inference data.
        query_purchase_propensity_training_preparation: The SQL query that will be used to prepare the training data.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """

    # Features Preparation
    phase_1 = list()
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_purchase_propensity_label,
            timeout=timeout).set_display_name('purchase_propensity_label')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_dimensions,
            timeout=timeout).set_display_name('user_dimensions')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_rolling_window_metrics,
            timeout=timeout).set_display_name('user_rolling_window_metrics')
    )
    # Training data preparation
    purchase_propensity_train_prep = sp(
        project=project_id,
        location=location,
        query=query_purchase_propensity_training_preparation,
        timeout=timeout).set_display_name('purchase_propensity_training_preparation').after(*phase_1)
    # Inference data preparation
    purchase_propensity_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_purchase_propensity_inference_preparation,
        timeout=timeout).set_display_name('purchase_propensity_inference_preparation').after(*phase_1)
  

@dsl.pipeline()
def churn_propensity_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    query_churn_propensity_label: str,
    query_user_dimensions: str,
    query_user_rolling_window_metrics: str,
    query_churn_propensity_inference_preparation: str,
    query_churn_propensity_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for feature engineering for the churn propensity model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_churn_propensity_label: The SQL query that will be used to calculate the churn propensity label.
        query_user_dimensions: The SQL query that will be used to calculate the user dimensions.
        query_user_rolling_window_metrics: The SQL query that will be used to calculate the user rolling window metrics.
        query_churn_propensity_inference_preparation: The SQL query that will be used to prepare the inference data.
        query_churn_propensity_training_preparation: The SQL query that will be used to prepare the training data.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """

    # Features Preparation
    phase_1 = list()
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_churn_propensity_label,
            timeout=timeout).set_display_name('churn_propensity_label')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_dimensions,
            timeout=timeout).set_display_name('user_dimensions')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_rolling_window_metrics,
            timeout=timeout).set_display_name('user_rolling_window_metrics')
    )
    # Training data preparation
    churn_propensity_train_prep = sp(
        project=project_id,
        location=location,
        query=query_churn_propensity_training_preparation,
        timeout=timeout).set_display_name('churn_propensity_training_preparation').after(*phase_1)
    # Inference data preparation
    churn_propensity_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_churn_propensity_inference_preparation,
        timeout=timeout).set_display_name('churn_propensity_inference_preparation').after(*phase_1)
    

@dsl.pipeline()
def customer_lifetime_value_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    query_customer_lifetime_value_label: str,
    query_user_lifetime_dimensions: str,
    query_user_rolling_window_lifetime_metrics: str,
    query_customer_lifetime_value_inference_preparation: str,
    query_customer_lifetime_value_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for feature engineering for the customer lifetime value model.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_customer_lifetime_value_label: The SQL query that will be used to calculate the customer lifetime value label.
        query_user_lifetime_dimensions: The SQL query that will be used to calculate the user lifetime dimensions.
        query_user_rolling_window_lifetime_metrics: The SQL query that will be used to calculate the user rolling window lifetime metrics.
        query_customer_lifetime_value_inference_preparation: The SQL query that will be used to prepare the inference data.
        query_customer_lifetime_value_training_preparation: The SQL query that will be used to prepare the training data.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """

    # Features Preparation
    phase_1 = list()
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_customer_lifetime_value_label,
            timeout=timeout).set_display_name('customer_lifetime_value_label')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_lifetime_dimensions,
            timeout=timeout).set_display_name('user_lifetime_dimensions')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_rolling_window_lifetime_metrics,
            timeout=timeout).set_display_name('user_rolling_window_lifetime_metrics')
    )
    # Training data preparation
    customer_lifetime_value_train_prep = sp(
        project=project_id,
        location=location,
        query=query_customer_lifetime_value_training_preparation,
        timeout=timeout).set_display_name('customer_lifetime_value_training_preparation').after(*phase_1)
    # Inference data preparation
    customer_lifetime_value_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_customer_lifetime_value_inference_preparation,
        timeout=timeout).set_display_name('customer_lifetime_value_inference_preparation').after(*phase_1)


@dsl.pipeline()
def reporting_preparation_pl(
    project_id: str,
    location: Optional[str],
    query_aggregate_last_day_predictions: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for preparing the reporting data.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_aggregate_last_day_predictions: The SQL query that will be used to aggregate the last day predictions.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """
    
    # Reporting Preparation
    aggregate_predictions = sp(
        project=project_id,
        location=location,
        query=query_aggregate_last_day_predictions,
        query_parameters=[]
    ).set_display_name('aggregate_predictions')


@dsl.pipeline()
def gemini_insights_pl(
    project_id: str,
    location: Optional[str],
    query_invoke_user_scoped_metrics: str,
    query_invoke_user_behaviour_revenue_insights: str,
    timeout: Optional[float] = 3600.0
):
    """
    This pipeline defines the steps for invoking the user behaviour revenue insights query.

    Args:
        project_id: The Google Cloud project ID.
        location: The Google Cloud region where the pipeline will be run.
        query_invoke_user_behaviour_revenue_insights: The SQL query that will be used to invoke the user behaviour revenue gemini insights.
        timeout: The timeout for the pipeline in seconds.

    Returns:
        None
    """
    
    # User Scoped Metrics
    user_scoped_metrics = sp(
        project=project_id,
        location=location,
        query=query_invoke_user_scoped_metrics,
        query_parameters=[]
    ).set_display_name('user_scoped_metrics')

    # User behaviour revenue insights
    user_behaviour_revenue_insights = sp(
        project=project_id,
        location=location,
        query=query_invoke_user_behaviour_revenue_insights,
        query_parameters=[]
    ).after(*[user_scoped_metrics]).set_display_name('user_behaviour_revenue_insights')
