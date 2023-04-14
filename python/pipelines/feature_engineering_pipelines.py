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


@dsl.pipeline()
def pipeline(
    project_id: str,
    location: Optional[str],


    query_customer_lifetime_value_label: str,
    query_purchase_propensity_label: str,
    query_user_dimensions: str,
    query_user_lifetime_dimensions: str,
    query_user_lookback_metrics: str,
    query_user_rolling_window_lifetime_metrics: str,
    query_user_rolling_window_metrics: str,
    query_user_scoped_lifetime_metrics: str,
    query_user_scoped_metrics: str,
    query_user_scoped_segmentation_metrics: str,
    query_user_segmentation_dimensions: str,
    query_user_session_event_aggregated_metrics: str,

    query_purchase_propensity_inference_preparation: str,
    query_customer_lifetime_value_inference_preparation: str,
    query_audience_segmentation_inference_preparation: str,

    query_purchase_propensity_training_preparation: str,
    query_customer_lifetime_value_training_preparation: str,
    query_audience_segmentation_training_preparation: str,

    query_parameters: Optional[list] = None,
    timeout: Optional[float] = 600.0
):

    phase_1 = list()
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_customer_lifetime_value_label,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('customer_lifetime_value_label')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_purchase_propensity_label,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('purchase_propensity_label')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_dimensions,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_dimensions')
    )

    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_lifetime_dimensions,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_lifetime_dimensions')
    )
    phase_1.append(sp(
        project=project_id,
        location=location,
        query=query_user_lookback_metrics,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('user_lookback_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_rolling_window_lifetime_metrics,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_rolling_window_lifetime_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_rolling_window_metrics,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_rolling_window_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_scoped_lifetime_metrics,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_scoped_lifetime_metrics')
    )
    phase_1.append(

        sp(
            project=project_id,
            location=location,
            query=query_user_scoped_metrics,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_scoped_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_scoped_segmentation_metrics,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_scoped_segmentation_metrics')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_segmentation_dimensions,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_segmentation_dimensions')
    )
    phase_1.append(
        sp(
            project=project_id,
            location=location,
            query=query_user_session_event_aggregated_metrics,
            query_parameters=query_parameters,
            timeout=timeout).set_display_name('user_session_event_aggregated_metrics')
    )

    # Training data preparation for 3 use cases
    purchase_propensity_train_prep = sp(
        project=project_id,
        location=location,
        query=query_purchase_propensity_training_preparation,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('purchase_propensity_training_preparation').after(*phase_1)
    
    purchase_propensity_train_prep = sp(
        project=project_id,
        location=location,
        query=query_customer_lifetime_value_training_preparation,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('customer_lifetime_value_training_preparation').after(*phase_1)

    purchase_propensity_train_prep = sp(
        project=project_id,
        location=location,
        query=query_audience_segmentation_training_preparation,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('audience_segmentation_training_preparation').after(*phase_1)
  

    # Inference data preparation for 3 use cases
    purchase_propensity_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_purchase_propensity_inference_preparation,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('purchase_propensity_inference_preparation').after(*phase_1)
    
    customer_lifetime_value_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_customer_lifetime_value_inference_preparation,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('customer_lifetime_value_inference_preparation').after(*phase_1)

    audience_segmentation_inf_prep = sp(
        project=project_id,
        location=location,
        query=query_audience_segmentation_inference_preparation,
        query_parameters=query_parameters,
        timeout=timeout).set_display_name('audience_segmentation_inference_preparation').after(*phase_1)
  

   