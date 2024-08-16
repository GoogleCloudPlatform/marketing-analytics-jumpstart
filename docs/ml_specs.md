# Machine Learning (ML) Technical Design

## Introduction
This document details the features and models used in the training, prediction and explanation pipelines for the ML driven use cases supported by this solution.

### GA4 events tagging requirement
The out-of-box ML driven use cases requires the following events tagged in the Google Analytics 4 (GA4) property, exported to BigQuery using the GA4 BigQuery Export. The export has to be set to run daily.

| Event |	Event Type | Requirement | Doc Ref. |
| -------- | ------- | ------- | --------- |
| purchase | Ecommerce Measurement event | Required |	https://developers.google.com/analytics/devguides/collection/ga4/set-up-ecommerce |
| view_item | Ecommerce Measurement event | Required |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| view_item_list | Ecommerce Measurement event | Optional |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| add_to_cart | Ecommerce Measurement event | Required |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| begin_checkout | Ecommerce Measurement event | Required |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| refund | Ecommerce Measurement event | Optional |	https://developers.google.com/analytics/devguides/collection/ga4/ecommerce |
| first_visit | Automatically collected event | Required |	https://support.google.com/analytics/answer/9234069?hl=en |
| page_view | Automatically collected event | Required |	https://support.google.com/analytics/answer/9234069?hl=en |
| click | Automatically collected event | Optional |	https://support.google.com/analytics/answer/9234069?hl=en |

## GA4 User identifiers
The Marketing Analytics Jumpstart solution uses Google Analytics 4 user pseudo IDs as the primary identifier for users. It also includes the user IDs as well. Google Analytics 4 uses User-ID to associate identifiers with individual users, enabling you to connect their behavior across sessions, devices, and platforms. [User-ID - Analytics Help](https://support.google.com/analytics/answer/9355972?hl=en) You can use User-ID to create remarketing audiences and join Analytics data with first-party data, such as CRM data. [Best practices for User-ID - Analytics Help](https://support.google.com/analytics/answer/12675187?hl=en) The User-ID feature is designed for use with Google Analytics technologies and must comply with the Analytics SDK/User-ID Feature Policy. Remember that User IDs sent to Google Analytics must be shorter than 256 characters. [Measure activity across platforms with User-ID - Analytics Help](https://support.google.com/analytics/answer/9213390?hl=en)

Each user must have a unique User ID, and the `user_id` parameter must be the same each time a user visits your website. [About data segments that use User ID to advertise - Ads Help](https://support.google.com/google-ads/answer/9199250?hl=en) Analytics can also use device ID as an identity space. [GA4 Reporting identity - Analytics Help](https://support.google.com/analytics/answer/10976610?hl=en)

## Modelling Principles

The machine pipelines were designed taking the following modelling principles:

- **Aggregated Value Based Bidding Training (VBB Training)**: This is Tabular Workflow End-to-End AutoML pipeline which modelling principle is to overfit the training data. Because of data, feel free to duplicate the train subset as many times as you need until you have the minimum number of 1000 examples, as required by AutoML. We use one full copy of train subset and use a evaluation and test subsets, to make the model stops training when the model overfits (preventing early stopping from happening).
- **Aggregated Value Based Bidding Explanation (VBB Explanation)**: This is custom pipeline in which we get the latest trained model shapley values generated during the Evaluation step in the AutoML Training. These feature importance values are then written to a BigQuery table for reporting. These values are relevant for a few weeks, that is why there is no need to train the model lesser than once a week.
- **Segmentation Training (Demographic based segmentation training)**: This is a custom pipeline in which we train a BigQuery ML KMEANS model having Vertex AI as a model registry. The modelling principle is to organize the demographic user behaviour by looking back 15 days (by default - double check the `interval_min_date` parameter value inside the `bigquery.query.invoke_audience_segmentation_training_preparation` block in the `config.yaml` file) aggregated metrics.
- **Segmentation Prediction (Demographic based segmentation prediction)**: This custom pipeline gets the latest trained audience segmentation model, call predict method and writes the predictions values to BigQuery. The clusters predicted are useful only for a short number of days (7 days is a good assumption), that is why it is important to retrain the audience segmentation model frequently. 
- **Auto Segmentation Training (Interest based segmentation training)**: This a custom training pipeline which trains a scikit-learn KMEANS model and applies the elbow method to find out the correct number of clusters to be created. The modelling principle is to suggest clusters of users who have been navigating in specific section in your website that have reached cumulative percentage traffic of 35% (double check the parameter value defined in the section `vertex_ai.pipelines.feature-creation-auto-audience-segmentation.execution.pipeline_parameters.perc_keep` in the `config.yaml` file) by using the regular expression defined in `vertex_ai.pipelines.feature-creation-auto-audience-segmentation.execution.pipeline_parameters.reg_expression` parameter as a criteria to count the `page_path` event parameter value. 
- **Auto Segmentation Prediction (Interest based segmentation prediction)**: This is custom pipeline which gets the latest trained auto audience segmentation model, runs the predict method and writes all predictions values to a BigQuery table. The predictions are useful only for a few days, you may want to retrain the model to observe important changes in traffic behaviour of users weekly or bi-weekly.
- **Propensity Training (Purchase Propensity Training)**: This is a Tabular Workflow AutoML End-to-End training pipeline in which the main objective is classify users into two classes (1 or 0) taking the label `will_purchase` calculated for the next 15 days (double-check the parameter value in `bigquery.query.invoke_purchase_propensity_label.interval_input_date`). The modelling principle is to train a classifier that looks back at aggregated metrics of users looking back 30 days (double-check pipeline parameter `vertex_ai.pipelines.propensity.training.pipeline_parameters.target_column`, and the `sql/procedure/purchase_propensity_label.sqlx` stored procedure file to understand how the `will_purchase` feature label is calculated) to predict 15 days ahead (as default, but configurable). The idea is to avoid overfitting or having a perfect fit, what we actually want is to have accurate propensity probabilities or score or likelihoods to rank the user according to it. Users with a higher rank are more likely to purchase, whereas users with a lower rank is less likely to purchase. 

*Note*: The `propensity_clv.training pipeline` is a training pipeline similar but different to this one. What is different is the look ahead window interval and the how it is used. The `propensity_clv.training` pipeline is used to classify not to rank, since we want to know which users are going to buy to predict their Lifetime Value gain. This model predictions are used in the Customer Lifetime Time Value Prediction pipeline.

- **Propensity Prediction (Purchase Propensity Prediction)**: This is a custom pipeline in which we predict the propensity of a user to purchase (as default, but configurable). The pipeline gets the latest best performing model, generates the predictions and saves them into a BigQuery table. The propensities rank should not change dramatically from one day to the next day, however depending on the traffic volume you will need to train it weekly or bi-weekly to understand frequent purchasers and non-frequent purchasers behaviours.
- **Customer LTV Training (Customer Lifetime Value Training)**: This is a Tabular Workflow AutoML End-to-End training pipeline which trains a regression model to predict the lifetime value gains of users looking back at aggregated metrics in the past 180 days (double-check the parameter value in `bigquery.query.invoke_customer_lifetime_value_training_preparation.interval_min_date` in the `config.yaml` file) in the future 30 days (double-check the parameter value in `bigquery.query.invoke_customer_lifetime_value_training_preparation.interval_max_date` in the `config.yaml` file). The modelling principle is to predict what will be the LTV gain for every user, in case the user doesn't purchase, the LTV gain is set to 0.0 gain (double-check the query logic used in the sql/procedure/customer_lifetime_value_label.sqlx file).
- **Customer LTV Prediction (Customer Lifetime Value Prediction)**: This is a custom prediction pipeline that uses the models clv regression and propensity clv models to predict the ltv gains for each user. The idea is to split the effort in two steps: First, we predict which users are going to purchase in the next 30 days (default, but configurable). Next, we predict the ltv gain for those users only, for those non-purchasers in the next days we set the ltv gain as 0.0. This prediction is relevant for several weeks, you will retrain the model once you have more conversions events that increase the users LTV past one or two weeks.


## Machine Learning Feature Reference

### Purchase Propensity Features
Target field:
| Target field | Source Field from GA4 Event |
| -------- | -------- |
| will_purchase | A binary value (1 if any `purchase` event occurred, 0 otherwise) for each user in the predicting time window|

Features:

| Feature | Source Field from GA4 Event |
| -------- | -------- |
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
| has_signed_in_with_user_id | Boolean representing the `user_id` field is set on events aggregated over each user |
| last_traffic_source_medium | [GA4 event - traffic_source record](https://support.google.com/analytics/answer/7029846#zippy=%2Ctraffic-source) |
| last_traffic_source_name | 〃 |
| last_traffic_source_source | 〃 |
| user_ltv_revenue | SUM of `ecommerce.purchase_revenue_in_usd` over a period of X days for each user |
| active_users_past_1_day | Aggregate metric derived from a sliding window over the previous 1st day, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_15_30_day | Aggregate metric derived from a sliding window over the interval of the past 15 to 30 days, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_2_day | Aggregate metric derived from a sliding window over the previous 2nd day, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_3_day | Aggregate metric derived from a sliding window over the previous 3rd day, representing a SUM of active sessions number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_4_day | Aggregate metric derived from a sliding window over the previous 4th day, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_5_day | Aggregate metric derived from a sliding window over the previous 5th day, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_6_day | Aggregate metric derived from a sliding window over the previous 6th day, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_7_day | Aggregate metric derived from a sliding window over the previous 7th day, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| active_users_past_8_14_day | Aggregate metric derived from a sliding window over the interval of the past 8 to 14 days, representing a SUM of active sessions (number of sessions were long enough to be considered an active session, 0 otherwise) for each user. |
| add_to_carts_past_1_day | Aggregate metric derived from a sliding window over the previous 1st day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_15_30_day | Aggregate metric derived from a sliding window over the interval of the past 15 to 30 days, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_2_day | Aggregate metric derived from a sliding window over the previous 2nd day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_3_day | Aggregate metric derived from a sliding window over the previous 3rd day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_4_day | Aggregate metric derived from a sliding window over the previous 4th day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_5_day | Aggregate metric derived from a sliding window over the previous 5th day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_6_day | Aggregate metric derived from a sliding window over the previous 6th day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_7_day | Aggregate metric derived from a sliding window over the previous 7th day, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| add_to_carts_past_8_14_day | Aggregate metric derived from a sliding window over the interval of the past 8 to 14 days, representing a SUM of `add_to_cart` events (number of add_to_cart events, 0 otherwise) for each user. |
| checkouts_past_1_day | Aggregate metric derived from a sliding window over the previous 1st day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_15_30_day | Aggregate metric derived from a sliding window over the interval of the past 15 to 30 days, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_2_day | Aggregate metric derived from a sliding window over the previous 2nd day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_3_day | Aggregate metric derived from a sliding window over the previous 3rd day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_4_day | Aggregate metric derived from a sliding window over the previous 4th day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_5_day | Aggregate metric derived from a sliding window over the previous 5th day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_6_day | Aggregate metric derived from a sliding window over the previous 6th day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_7_day | Aggregate metric derived from a sliding window over the previous 7th day, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| checkouts_past_8_14_day | Aggregate metric derived from a sliding window over the interval of the past 8 to 14 days, representing a SUM of `begin_checkout` events (number of begin_checkout events, 0 otherwise) for each user. |
| purchases_past_1_day | Aggregate metric derived from a sliding window over the previous X days, summerized to the number of `purchase` events occurred for each user. |
| purchases_past_15_30_day | 〃 |
| purchases_past_2_day | 〃 |
| purchases_past_3_day | 〃 |
| purchases_past_4_day | 〃 |
| purchases_past_5_day | 〃 |
| purchases_past_6_day | 〃 |
| purchases_past_7_day | 〃 |
| purchases_past_8_14_day | 〃 |
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

### Auto Audience Segmentation Features
| Feature | Source Field from GA4 Event |
| -------- | -------- |



## Value Based Bidding

Value-based bidding enables you to maximize the total value of conversions generated by your campaigns. Google AI optimizes bids in real time to reach people who are likely to bring more value to your business. Just specify the value you want to maximize, like sales revenue, profit margins, or lead scores, when setting up conversion tracking for your account. Learn [more](https://support.google.com/google-ads/answer/14791574?sjid=2840724071076810112-NC).

Value based bidding brings value into Smart Bidding because differentiating your customers and bidding on what matters will drive increased performance. Advertisers differentiate their customers value, but often don’t share this information with Google for optimization. With value bidding the system will learn which potential customers are most valuable to the advertisers. Bidding towards the most valuable customers will deliver incremental revenue uplift and profitability to advertisers.

Value Bidding works across all business models, and also provides you a better insight into your customers. 
* Online sales: Maximize sales of higher value products that drive the most profit, setting unique values for each product.
* Omnichannel sales: You can set an average value of a store visit conversion to let Smart Bidding maximize sales across all channels, online and in-store.
* Lead Generation: Improve the quality of leads by differentiating how much an online quote is worth through your lead-to-sale journey. 

Enabling values for your conversions, also gives you better insights into your marketing
activities on Google

### Data driven Attribution

Before making a purchase or completing another valuable action on your website, people may click or interact with several of your ads. Typically, all credit for the conversion is given to the last ad customers interacted with. But was it really that ad that made them decide to choose your business?

Data-driven attribution gives credit for conversions based on how people engage with your various ads and decide to become your customers. It uses data from your account to determine which keywords, ads, and campaigns have the greatest impact on your business goals. Data-driven attribution looks at website, store visit, and Google Analytics conversions from Search (including Shopping), YouTube, Display, and Demand Gen ads.