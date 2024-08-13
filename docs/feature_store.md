# Feature Store Guide

## Introduction

The Feature Store component involves leveraging data pipelines that transforms event-level data  into user-level feature metrics and dimensions and combining them into training and inference data to be ingested by all the ML models. The features are stored and managed in BigQuery, and they are ready to be served to different ML models and allow reproducible model training and predictions across different intervals of time.

The Feature Store transformations are implemented in BigQuery [GoogleSQL](https://cloud.google.com/bigquery/docs/introduction-sql) and are orchestrated using Vertex AI [Pipelines](https://cloud.google.com/vertex-ai/docs/pipelines/introduction). The daily features preparation is scheduled and triggered using Vertex AI [Pipelines Scheduler](https://cloud.google.com/vertex-ai/docs/pipelines/schedule-pipeline-run).

This guide details how to deploy and monitor the feature store, manually backfill features for past days, troubleshoot and customize the feature store to meet your specific requirements.

## Solution Architecture

![data store architecture](images/feature_engineering_architecture.png)
This architecture diagram describes the feature engineering flow of data in the Feature Store component, from Marketing Data Store to the training and inference tables to be used by the ML pipelines. The Feature Store is fully orchestrated using Vertex AI Pipelines and the data platform adopted is BigQuery. The core components are:
* **Data Store**: The Marketing Data Store views and tables in the presentation layer. 
* **Transformation Procedures**:
    * For Purchase, Churn, CLTV labeling stored procedures: Event-level data is aggregated at the user-level. For each use case, specific metrics are calculated using fixed windows sizes (i.e. number of past days) and used as labels. These labels are attributed for every user in the data store.
    * For User dimensions stored procedures: Event-level data is aggregated at the user-level. For each use case, generic dimensions such as geo, device, traffic source dimension are consolidated taking in consideration the first and the last events observed for every user in the data store.
    * For User rolling windows stored procedures: Event-level data is aggregated at the user-level. For each use case, rolling windows metrics are calculated using fixed windows sizes (i.e. number of past days) and used as features. These are calculated for every user in the data store.
    * For User pages navigation stored procedures: Event-level data is aggregated at the user-level. For the Auto Audience Segmentation use case, rolling windows metrics are calculated using a fixed window size (i.e. number of past days) and used to determine which were the pages most visited in the website in that specific interval of dates. This is calculated for the most visited pages in the website, according to an configuration parameter, for every user in the data store.
    * For Conversion events stored procedures: Event-level data is aggregated daily. Every event marked as a [key event](https://support.google.com/analytics/answer/9267568) in Google Analytics 4 can be considered in this analysis. These metrics are calculated for every user in the data store. Identify [high-value conversions](https://support.google.com/google-ads/answer/14791574) and lay down a solid foundation for building and measuring data effectively. This will help you tap into the full potential of your first-party (1P) data by aligning with your business objectives.
* **Backfill Transformation Procedures**: The Feature Store provides backfill procedures that will populate features for every user at every valid past interval to enable you to train your models once you have had enabled the Google Analytics 4 BigQuery Export for enough days depending on your use case. Note that Google Analytics 4 BigQuery Export doesn't offer a backfill option. These procedures will only compute features taking into consideration the date interval available in your Marketing Data Store. 
* **Use Case Specific Training and Inference Procedures**: Training and inference procedures that can be run at any time immediately before running training or inference pipelines.

## Who is this solution for?

We heard common stories from customers who were struggling with three frequent objectives:

1. **Marketing teams looking into transforming data to solve marketing analytics use cases without the expertise in the raw data exported by the BigQuery [Data Transfer Services](https://cloud.google.com/bigquery/docs/dts-introduction)**
- These teams need a tool that can help them to easily and efficiently transform raw data into a format that can be used for analysis.
- The feature store provides a set of pre-built transformations that can be used to transform raw data into a format that is suitable for marketing analytics use cases.

2. **Data Scientists or Marketing Scientists looking into calculating features having difficulty in finding the right GoogleSQL queries to be used to obtain key metrics and user attributes**
- These teams need a repository of GoogleSQL queries that can be used to calculate common features.
- The feature store provides a library of GoogleSQL queries that can be used to calculate common features for marketing analytics use cases. These queries can be easily customized to meet the specific needs of each team.

3. **ML Engineers building automated production ready feature engineering data pipelines having to deal with backfilling and implementing consistent transformations for consolidating data for training and serving purposes**
- These teams need a platform that can help them to automate the feature engineering process.
- The feature store provides a platform that can be used to automate the feature engineering process. This platform can help to reduce the time and effort required to build and maintain feature engineering pipelines. Additionally, the feature store provides a mechanism for backfilling features and ensuring that the same transformations are applied to both training and serving data.

## Benefits of this solution

After deploying the Feature Store, Marketing Technology teams get the following benefits:

1. Productionize new features without extensive engineering support
2. Automate feature computation, backfills, and logging
3. Share and reuse feature pipelines across teams
4. Achieve consistency between training and serving data
5. Monitor the health of feature pipelines in production

## Advantages of the solution

## Feature Store usage by each use case

## Feature Store Design Principles

## What is deployed to Google Cloud?

## Manually Triggering Feature Store

## Manually Backfilling Feature Store

## Customize Features Transformations

## Implement new features into the Feature Store

# Troubleshooting

## When not using all ecommerce events in Google Analytics 4. Which changes I must do?

For example, let's say you don't use 'begin_checkout' events. In that case, you need to adjust your SQL code to handle the missing event. 
At first, search all SQL files in which 'begin_checkout' is mentioned and check the code documentation to understand how it is used in the metrics calculations.
Then, plan on how you would redefine the formula to determine cart abandonment. 

Here's a breakdown of the changes and the reasoning behind them:

**1. Cart Abandonment Logic:**

* **Current Logic:** The code currently identifies cart abandonment based on the presence of 'begin_checkout' events without corresponding 'purchase' events within the same day.
* **New Logic (Without 'begin_checkout'):** You'll need a new definition of cart abandonment. Here are a few options:
* **Option 1: 'add_to_cart' without 'purchase':** Identify users who added items to their cart ('add_to_cart' event) but didn't complete a purchase on the same day.
* **Option 2: Time-based abandonment:** Define a time threshold (e.g., 24 hours) after an 'add_to_cart' event. If a user doesn't make a purchase within that timeframe, consider it an abandoned cart.
* **Option 3: Utilize other events:** If you have other events that might signal intent to purchase (e.g., 'view_cart', 'proceed_to_payment'), you can incorporate those into your logic.

**2. Modify the SQL Code:**

* **Remove/Modify Temporary Tables:**
* **`returned_cart_to_purchase`:** This table is entirely dependent on the 'begin_checkout' event. You should remove it.
* **`cart_to_purchase`:** Modify this table's logic to reflect your chosen definition of cart abandonment (see options above).

* **Example Modification (Using Option 1):**
```sql
-- ... (previous code) ...

-- Has the user abandoned any cart by day?
CREATE OR REPLACE TEMP TABLE cart_to_purchase AS (
SELECT
GA.user_pseudo_id,
input_date as feature_date,
-- Check for 'add_to_cart' without 'purchase' on the same day
CASE
WHEN SUM(CASE WHEN event_name = 'add_to_cart' THEN 1 ELSE 0 END) > 0 -- At least one 'add_to_cart'
AND SUM(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) = 0 -- No 'purchase' events
THEN True
ELSE False
END AS has_abandoned_cart
FROM `{{mds_project_id}}.{{mds_dataset}}.event` AS GA
INNER JOIN `{{mds_project_id}}.{{mds_dataset}}.device` as D
ON GA.device_type_id = D.device_type_id
CROSS JOIN dates_interval as DI
WHERE event_date BETWEEN DI.end_date AND DI.input_date
AND GA.ga_session_id IS NOT NULL
AND D.device_os IS NOT NULL
GROUP BY user_pseudo_id, feature_date
);

-- ... (rest of the code) ...
```

**3. Adjust Feature Importance (Optional):**

* Without 'begin_checkout', the `has_abandoned_cart` feature might have different predictive power for your models. Consider evaluating its importance after making these changes and retraining your models.

**Important Considerations:**

* **Business Context:** The most appropriate definition of cart abandonment depends on your specific business context and the events you collect.
* **Data Exploration:** Before making changes, thoroughly explore your data to understand user behavior and identify potential alternative events to define cart abandonment effectively.
* **Model Retraining:** After modifying your SQL and feature engineering, you'll need to retrain your models to ensure they learn from the updated data.



## When the business is high-value and infrequent items purchases. Which changes I must do?

The use cases implemented calculates the purchase-related features on a daily basis. However, your customers typically buy once every five to ten years. This means you need to adjust the code to capture long-term purchase behavior instead of focusing solely on daily activities. Here's how you can modify the code.

**1. Expand Feature Calculation Window:**

- **Current Approach:** The code uses `dates_interval` with `interval_end_date` set to 180 days, limiting the feature calculation window to six months.
- **Proposed Change:** Instead of daily features, calculate features over a longer period, such as yearly or multi-year windows. This will help capture purchase patterns over a timeframe more relevant to your customer behavior.

```sql
-- Example: Calculate features yearly
CREATE OR REPLACE TEMP TABLE dates_interval as (
SELECT DISTINCT 
CAST(FORMAT_DATE('%Y', event_date) AS INT64) AS feature_year,
DATE(CAST(FORMAT_DATE('%Y', event_date) AS INT64), 1, 1) as start_date,
DATE(CAST(FORMAT_DATE('%Y', event_date) AS INT64) + 1, 1, 1) as end_date
FROM `{{mds_project_id}}.{{mds_dataset}}.event`
);
```

- **Adjust Joins:** Modify subsequent queries to join on `feature_year` instead of `feature_date` to aggregate data over the new time window.

**2. Recalculate Features for Long-Term Behavior:**

- **Purchase Frequency:** Instead of `how_many_purchased_before` on a daily basis, calculate the total number of purchases a user has made within the entire feature window (e.g., total purchases in the past 5 or 10 years).

```sql
-- Example: Calculate total purchases in the feature window
CREATE OR REPLACE TEMP TABLE repeated_purchase as (
SELECT
user_pseudo_id,
feature_year,
COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN event_timestamp ELSE NULL END) AS total_purchases
FROM `{{mds_project_id}}.{{mds_dataset}}.event` AS GA
INNER JOIN dates_interval AS DI
ON GA.event_date BETWEEN DI.start_date AND DI.end_date
GROUP BY user_pseudo_id, feature_year
);
```

- **Recency Features:** Calculate features that capture how long it has been since a user's last purchase. Examples include:
- Days since last purchase (at the start of the feature window)
- Years since last purchase

- **Average Purchase Value:** Calculate the average value of a user's purchases within the feature window.

**3. Consider Time-Based Features:**

- **Seasonality:** If there are seasonal trends in your data (e.g., more purchases during holidays), create features to capture these patterns. For example, you could have a feature indicating the quarter or month of the year.
- **Trends:** Calculate features that capture trends in user behavior over time, such as the change in purchase frequency or average purchase value compared to previous periods.

**4. Data Aggregation and Feature Store:**

- **Aggregate Data:** Once you have calculated features over longer time windows, aggregate your data to create a user-level feature store. Each row in the feature store would represent a user, and the columns would be the calculated features.
- **Feature Freshness:** Determine the appropriate update frequency for your feature store. Given the infrequent purchase behavior, updating the feature store less frequently (e.g., monthly or quarterly) might be suitable.

**Example Code Snippet (Recency Feature):**

```sql
CREATE OR REPLACE TEMP TABLE recency_features AS (
SELECT
user_pseudo_id,
feature_year,
DATE_DIFF(DI.start_date, MAX(event_date), DAY) AS days_since_last_purchase
FROM `{{mds_project_id}}.{{mds_dataset}}.event` AS GA
INNER JOIN dates_interval AS DI
ON GA.event_date BETWEEN DI.start_date AND DI.end_date
WHERE event_name = 'purchase'
GROUP BY user_pseudo_id, feature_year
);
```

Remember to adapt these suggestions to your specific business context and the available data in your Google Analytics 4 tables. By adjusting the feature calculation window, focusing on long-term purchase behavior, and incorporating time-based features, you can create a more relevant and valuable feature store for modeling customer behavior with infrequent purchases.