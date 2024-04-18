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
    #training_table: str,
    #inference_table: str,
    reg_expression: str,
    query_auto_audience_segmentation_inference_preparation: str,
    query_auto_audience_segmentation_training_preparation: str,
    perc_keep: int = 35,
    timeout: Optional[float] = 3600.0
):
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
    query_user_scoped_segmentation_metrics: str,
    query_user_segmentation_dimensions: str,
    query_audience_segmentation_inference_preparation: str,
    query_audience_segmentation_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
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
            query=query_user_scoped_segmentation_metrics,
            timeout=timeout).set_display_name('user_scoped_segmentation_metrics')
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
    query_user_scoped_metrics: str,
    query_user_session_event_aggregated_metrics: str,
    query_purchase_propensity_inference_preparation: str,
    query_purchase_propensity_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
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
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_scoped_metrics,
            timeout=timeout).set_display_name('user_scoped_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_session_event_aggregated_metrics,
            timeout=timeout).set_display_name('user_session_event_aggregated_metrics')
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
def customer_lifetime_value_feature_engineering_pipeline(
    project_id: str,
    location: Optional[str],
    query_customer_lifetime_value_label: str,
    query_user_lifetime_dimensions: str,
    query_user_rolling_window_lifetime_metrics: str,
    query_user_scoped_lifetime_metrics: str,
    query_customer_lifetime_value_inference_preparation: str,
    query_customer_lifetime_value_training_preparation: str,
    timeout: Optional[float] = 3600.0
):
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
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_scoped_lifetime_metrics,
            timeout=timeout).set_display_name('user_scoped_lifetime_metrics')
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


   