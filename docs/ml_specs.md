# Machine Learning Specifications
This document details the features employed for training and prediction in the out-of-the-box use cases supported by this solution.

## Pre-requisites
### GA4 events requirements
The out-of-box ML driven use cases requires the following events to existing in the GA4 export data. The events feed into features for the ML trainings and inference.

| Event |	Event Type | Doc Ref. |
| -------- | ------- | --------- |
| purchase | Ecommerce Measurement events |	https://developers.google.com/analytics/devguides/collection/ga4/set-up-ecommerce |
| view_item | Ecommerce Measurement events |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| view_item_list | Ecommerce Measurement events |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| add_to_cart | Ecommerce Measurement events |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| begin_checkout | Ecommerce Measurement events |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| refund | Ecommerce Measurement events |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| first_visit | Automatically collected events |	https://support.google.com/analytics/answer/9234069?hl=en |
| page_view | Automatically collected events |	https://support.google.com/analytics/answer/9234069?hl=en |
| click | Automatically collected events |	https://support.google.com/analytics/answer/9234069?hl=en |

## Machine Learning Feature Reference

### Purchase Propensity Features
Target field:
| Target field | Source Field from GA4 Event |
| -------- | -------- |
| will_purchase | A binary value (1 if any purchase event occurred, 0 otherwise) for each user in the predicting time window|

Features:

| Feature | Source Field from GA4 Event |
| -------- | -------- |
| active_users_past_1_day | Aggregate metric derived from a sliding window over the previous X days, representing a binary value (1 if any events occurred, 0 otherwise) for each user. |
| active_users_past_15_30_day | 〃 |
| active_users_past_2_day | 〃 |
| active_users_past_3_day | 〃 |
| active_users_past_4_day | 〃 |
| active_users_past_5_day | 〃 |
| active_users_past_6_day | 〃 |
| active_users_past_7_day | 〃 |
| active_users_past_8_14_day | 〃 |
| add_to_carts_past_1_day | Aggregate metric derived from a sliding window over the previous X days, representing a binary value (1 if any `add_to_cart` events occurred, 0 otherwise) for each user. |
| add_to_carts_past_15_30_day | 〃 |
| add_to_carts_past_2_day | 〃 |
| add_to_carts_past_3_day | 〃 |
| add_to_carts_past_4_day | 〃 |
| add_to_carts_past_5_day | 〃 |
| add_to_carts_past_6_day | 〃 |
| add_to_carts_past_7_day | 〃 |
| add_to_carts_past_8_14_day | 〃 |
| checkouts_past_1_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `begin_checkout` events occurred for each user. |
| checkouts_past_15_30_day | 〃 |
| checkouts_past_2_day | 〃 |
| checkouts_past_3_day | 〃 |
| checkouts_past_4_day | 〃 |
| checkouts_past_5_day | 〃 |
| checkouts_past_6_day | 〃 |
| checkouts_past_7_day | 〃 |
| checkouts_past_8_14_day | 〃 |
| device_category | [GA4 event - device record](https://support.google.com/analytics/answer/7029846?hl=en#zippy=%2Cdevice) |
| device_language | 〃 |
| device_mobile_brand_name | 〃 |
| device_mobile_model_name | 〃 |
| device_os | 〃 |
| device_os_version | 〃 |
| device_web_browser | 〃 |
| device_web_browser_version | 〃 |
| first_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| first_traffic_source_name | 〃 |
| first_traffic_source_source | 〃 |
| geo_city | [GA4 event - geo record](https://support.google.com/analytics/answer/7029846#zippy=%2Cgeo) |
| geo_country | 〃 |
| geo_metro | 〃 |
| geo_region | 〃 |
| geo_sub_continent | 〃 |
| has_signed_in_with_user_id | When the `user_id` field is set on events aggregated over each user |
| last_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| last_traffic_source_name | 〃 |
| last_traffic_source_source | 〃 |
| purchases_past_1_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `purchase` events occurred for each user. |
| purchases_past_15_30_day | 〃 |
| purchases_past_2_day | 〃 |
| purchases_past_3_day | 〃 |
| purchases_past_4_day | 〃 |
| purchases_past_5_day | 〃 |
| purchases_past_6_day | 〃 |
| purchases_past_7_day | 〃 |
| purchases_past_8_14_day | 〃 |
| user_ltv_revenue | Summarization of `ecommerce.purchase_revenue_in_usd` over a period of X days for each user |
| view_items_past_1_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `view_item` events occurred for each user. |
| view_items_past_15_30_day | 〃 |
| view_items_past_2_day | 〃 |
| view_items_past_3_day | 〃 |
| view_items_past_4_day | 〃 |
| view_items_past_5_day | 〃 |
| view_items_past_6_day | 〃 |
| view_items_past_7_day | 〃 |
| view_items_past_8_14_day | 〃 |
| visits_past_1_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of visits an user have had. |
| visits_past_15_30_day | 〃 |
| visits_past_2_day | 〃 |
| visits_past_3_day | 〃 |
| visits_past_4_day | 〃 |
| visits_past_5_day | 〃 |
| visits_past_6_day | 〃 |
| visits_past_7_day | 〃 |
| visits_past_8_14_day | 〃 |

### Customer Lifetime Value Features
Target field:
| Target field | Source Field from GA4 Event |
| -------- | -------- |
| pltv_revenue_x_days | Aggregated value of all the purchase value for each user in the predicting time window|

Features:

| Feature | Source Field from GA4 Event |
| -------- | -------- |
| active_users_past_1_30_day | Aggregate metric derived from a sliding window over the previous X days, representing a binary value (1 if any events occurred, 0 otherwise) for each user. |
| active_users_past_120_150_day | 〃 |
| active_users_past_150_180_day | 〃 |
| active_users_past_30_60_day | 〃 |
| active_users_past_60_90_day | 〃 |
| active_users_past_90_120_day | 〃 |
| add_to_carts_past_1_30_day | Aggregate metric derived from a sliding window over the previous X days, representing a binary value (1 if any `add_to_cart` events occurred, 0 otherwise) for each user. |
| add_to_carts_past_120_150_day | 〃 |
| add_to_carts_past_150_180_day | 〃 |
| add_to_carts_past_30_60_day | 〃 |
| add_to_carts_past_60_90_day | 〃 |
| add_to_carts_past_90_120_day | 〃 |
| checkouts_past_1_30_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `begin_checkout` events occurred for each user. |
| checkouts_past_120_150_day | 〃 |
| checkouts_past_150_180_day | 〃 |
| checkouts_past_30_60_day | 〃 |
| checkouts_past_60_90_day | 〃 |
| checkouts_past_90_120_day | 〃 |
| device_category | [GA4 event - device record](https://support.google.com/analytics/answer/7029846?hl=en#zippy=%2Cdevice) |
| device_language | 〃 |
| device_mobile_brand_name | 〃 |
| device_mobile_model_name | 〃 |
| device_os | 〃 |
| device_os_version | 〃 |
| device_web_browser | 〃 |
| device_web_browser_version | 〃 |
| first_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| first_traffic_source_name | 〃 |
| first_traffic_source_source | 〃 |
| geo_city | [GA4 event - geo record](https://support.google.com/analytics/answer/7029846#zippy=%2Cgeo) |
| geo_country | 〃 |
| geo_metro | 〃 |
| geo_region | 〃 |
| geo_sub_continent | 〃 |
| has_signed_in_with_user_id | When the `user_id` field is set on events aggregated over each user |
| last_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| last_traffic_source_name | 〃 |
| last_traffic_source_source | 〃 |
| purchases_past_1_30_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `purchase` events occurred for each user. |
| purchases_past_120_150_day | 〃 |
| purchases_past_150_180_day | 〃 |
| purchases_past_30_60_day | 〃 |
| purchases_past_60_90_day | 〃 |
| purchases_past_90_120_day | 〃 |
| view_items_past_1_30_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `view_item` events occurred for each user. |
| view_items_past_120_150_day | 〃 |
| view_items_past_150_180_day | 〃 |
| view_items_past_30_60_day | 〃 |
| view_items_past_60_90_day | 〃 |
| view_items_past_90_120_day | 〃 |
| visits_past_1_30_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of visits an user have had. |
| visits_past_120_150_day | 〃 |
| visits_past_150_180_day | 〃 |
| visits_past_30_60_day | 〃 |
| visits_past_60_90_day | 〃 |
| visits_past_90_120_day | 〃 |

### Audience Segmentation Features
| Feature | Source Field from GA4 Event |
| -------- | -------- |
| active_users_past_1_7_day | Aggregate metric derived from a sliding window over the previous X days, representing a binary value (1 if any events occurred, 0 otherwise) for each user. |
| active_users_past_8_14_day | 〃 |
| add_to_carts_past_1_7_day | Aggregate metric derived from a sliding window over the previous X days, representing a binary value (1 if any `add_to_cart` events occurred, 0 otherwise) for each user. |
| add_to_carts_past_8_14_day | 〃 |
| checkouts_past_1_7_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `begin_checkout` events occurred for each user. |
| checkouts_past_8_14_day | 〃 |
| device_category | [GA4 event - device record](https://support.google.com/analytics/answer/7029846?hl=en#zippy=%2Cdevice) |
| device_language | 〃 |
| device_mobile_brand_name | 〃 |
| device_mobile_model_name | 〃 |
| device_os | 〃 |
| device_os_version | 〃 |
| device_web_browser | 〃 |
| device_web_browser_version | 〃 |
| first_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| first_traffic_source_name | 〃 |
| first_traffic_source_source | 〃 |
| geo_city | [GA4 event - geo record](https://support.google.com/analytics/answer/7029846#zippy=%2Cgeo) |
| geo_country | 〃 |
| geo_metro | 〃 |
| geo_region | 〃 |
| geo_sub_continent | 〃 |
| has_signed_in_with_user_id | When the `user_id` field is set on events aggregated over each user |
| last_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| last_traffic_source_name | 〃 |
| last_traffic_source_source | 〃 |
| ltv_revenue_past_1_7_day | Summarization of `ecommerce.purchase_revenue_in_usd` over a period of X days for each user |
| ltv_revenue_past_7_15_day | 〃 |
| purchases_past_1_7_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `purchase` events occurred for each user. |
| purchases_past_8_14_day | 〃 |
| view_items_past_1_7_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `view_item` events occurred for each user. |
| view_items_past_8_14_day | 〃 |
| visits_past_1_7_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of visits an user have had. |
| visits_past_8_14_day | 〃 |