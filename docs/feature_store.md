




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