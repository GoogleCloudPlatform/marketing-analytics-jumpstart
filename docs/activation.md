# Activation Process Guide
## Introduction
![tech architecture](images/activation_tech_architecture.png)
The activation process enriches your Google Analytics 4 (GA4) user profiles with custom properties based on machine learning predictions for the different use cases supported by MAJ. This enrichment enables granular audience segmentation for targeted remarketing campaigns.

The activation process is automated and built on Google Cloud Dataflow for efficient data processing and reliable data delivery into GA4.

This guide details how to monitor the activation process, leverage the enriched user data, and tailor the process to fit your specific requirements.
## Prerequisites
The present activation implementation is dependent on the connection between your Google Analytics property and your Google Ads account. For the users in the custom audiences you create in GA4 to be able to synchronize with Google Ads, you must have the following setting:
1. [Advanced settings to allow for ads personalization on your GA4 property](https://support.google.com/analytics/answer/9626162)
1. For audiences to be transmitted to Google Ads, Ads personalization must be [enabled on the link](https://support.google.com/analytics/answer/9626162#ads-link) between a Google Analytics property and a Google Ads link
1. [Consent Mode](https://support.google.com/analytics/answer/9976101) implemented

    If you implement a consent banner requesting permission to store ads or analytics data, users who visit your site or app can choose to opt out. If users opt out of ads data storage, they are ineligible for remarketing campaigns. However, if they have agreed to analytics storage, they may still appear in your Google Analytics 4 reports, but they will not be included in the count for any linked advertising services.
    - To verify that you have a user base of eligible users for remarketing, you can turn on [GA4 export to BigQuery of User-data](https://support.google.com/analytics/answer/12769371?hl=en).
    -   In the export table, look for eligible users that allow personalized ads by running the following query:
        ```sql
        SELECT pseudo_user_id, privacy_info.is_ads_personalization_allowed
        FROM `analytics_XXXXXXXXX.pseudonymous_users_*`
        WHERE privacy_info.is_ads_personalization_allowed = 'true';
        ```
To further comprehend the factors affecting the audience synchronization between GA4 and Google Ads, please refer to the following guide: [Audience size differences between Google Analytics and Google Ad](https://support.google.com/analytics/answer/13656908).

## Activation process overview

MAJ automatically creates the following custom events and user properties corresponding to each supported use case as part of the installation process:
| Use Case |	GA4 Custom Event | GA4 Custom User Properties |
| -------- | ------- | --------- |
| Purchase Propensity | `maj_purchase_propensity_30_15` |	`p_p_prediction`<br>`p_p_decile` |
| Customer Lifetime Value  | `maj_cltv_180_30` |	`cltv_decile` |
| Demographic Audience Segmentation | `maj_audience_segmentation_15` |	`a_s_prediction` |
| Interest based Audience Segmentation | `maj_auto_audience_segmentation_15` |	`a_a_s_prediction` |
| Churn Propensity | `maj_churn_propensity_30_15` |	`c_p_prediction`<br>`c_p_decile` |

For each use case, a corresponding SQL query template dictates how prediction values are selected and processed for activation:

| Use Case |	Query Template |
| -------- | --------- |
| Purchase Propensity | [purchase_propensity_query_template.sqlx](../templates/activation_query/purchase_propensity_query_template.sqlx)|
| Customer Lifetime Value  | [cltv_query_template.sqlx](../templates/activation_query/cltv_query_template.sqlx) |
| Demographic Audience Segmentation | [audience_segmentation_query_template.sqlx](../templates/activation_query/audience_segmentation_query_template.sqlx) |
| Interest based Audience Segmentation | [auto_audience_segmentation_query_template.sqlx](../templates/activation_query/auto_audience_segmentation_query_template.sqlx) |
| Churn Propensity | [churn_propensity_query_template.sqlx](../templates/activation_query/churn_propensity_query_template.sqlx)|
| Lead Score Propensity | [lead_score_propensity_query_template.sqlx](../templates/activation_query/purchase_propensity_query_template.sqlx)|
| Lead Score Propensity for Smart Bidding | [lead_score_propensity_vbb_query_template.sqlx](../templates/activation_query/lead_score_propensity_vbb_query_template.sqlx)|

**Note:** The dynamic fields in the query template need to be prefixed with `user_prop_` or `event_param_` prefix inorder for the activation process to parse the value into measurement protocol payload.


The payload have the following keys set based on the [payload reference documentation](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference#payload_post_body):

| Key |	Value |
| -------- | --------- |
| `client_id` | `user_pseudo_id` from the last GA4 event |
| `user_id` | `user_id` from the last GA4 event and is only set if the field is not empty |
| `timestamp_micros` | 1 micro second before `event_timestamp` of the last GA4 event |
| `consent` | Allow sending user data from the request's events and user properties to Google for advertising purposes and personalized advertising for the user. |
| `user_properties` | [GA4 Custom User Properties](#activation-process-overview) specific for each use case |
| `event` | [GA4 Custom Event](#activation-process-overview) specific for each use case and `session_id` from the last GA4 event as [Event-scoped custom parameters](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference#custom_parameters) |

The activation pipeline reads the activation configuration to dynamically determine the templates to use for the specific use case it is processing.

Activation Pipeline Steps:
1. **Hydration:** Populates the prediction selection query template with the concrete use case prediction table. 
1. **Query Execution:** Runs the prediction selection query to retrieve all predictions that need activation. 
1. **Payload Generation:** Fills the GA4 Measurement Protocol payload template to create payloads for each prediction result.
1. **Event Transmission:** Sends each prediction as a custom event to GA4 using the [Measurement Protocl API](https://developers.google.com/analytics/devguides/collection/protocol/ga4/user-properties). 
1. **Logging:** Records each entry into an activation log table in BigQuery for tracking and auditing purposes.

### Prediction selection logic
The activation process links custom events sent to GA4 with the last user session. This is achieved by setting matching `session_id` and `event_timestamp` values in the payload.

Since the Measurement Protocol only accepts events within a 72-hour window, the activation process performs a cross join between the prediction results and the last 72 hours' user data. This ensures that only users active within this timeframe are selected for activation. 

### Activation process triggering
The activation Dataflow job is initiated by events sent to the Cloud Pub/Sub topic `activation-trigger`. The message format is as follows:
```
{"activation_type": "...","source_table": "..."}
```

Where:

* `activation_type`: A value corresponding to a key from the activation configuration file (e.g., "purchase-propensity-30-15").

* `source_table`: A reference to the actual BigQuery table containing prediction results (e.g., "purchase_propensity.predictions_2024_05_04T02_04_06_124Z_244_view").

For example:
```
{"activation_type": "purchase-propensity-30-15","source_table": "purchase_propensity.predictions_2024_05_04T02_04_06_124Z_244_view"}
```

By the end of the ML prediction process, a triggering event containing the path to the prediction table is sent to Pub/Sub, which automatically initiates the activation process on the prediction results.
You can also manually trigger the activation pipeline by sending the message through the [Pub/Sub console](https://console.cloud.google.com/cloudpubsub/topic/detail/activation-trigger?mods=logs_tg_staging&tab=messages&modal=publishmessage)

## Activating predictions on new models

The following changes will enable your system to send activation data (presumably related to a new model prediction) to Google Analytics 4 using Measurement Protocol and User Data Import. This is done through a Dataflow job, which is a way to process large datasets in a scalable and distributed manner. For the sake of this exercise, let's pretend we want to activate on a churn propensity model prediction.

**Modify Files:**
- `infrastructure/terraform/modules/activation/main.tf` (Terraform): New terraform resources are defined and the `activation_type_configuration` is updated.
  - New Data Object: Adds a new Terraform data object to load a template file called `churn_propensity_query_template_file`. This file likely contains a SQL query used to fetch data relevant to churn propensity from your feature store.
  - New Bucket Object: Creates a new object in your Google Cloud Storage bucket to hold the rendered version of the `churn_propensity_query_template_file`.
  - Configuration Update: Modifies the activation_type_configuration template to include the path to the newly created churn propensity query template in GCS. This ensures the Dataflow job can access the query.
- `python/ga4_setup/setup.py` (Python): 
  - New Custom Dimension: Creates new custom dimensions for the Churn Propensity use case. The new dimensions must match with the values keys being sent via Measurement Protocol. In this case, the GA4 Custom User Properties (c_p_prediction, c_p_decile).

**New Files:**
- `templates/activation_query/churn_propensity_query_template.sqlx` (Templated SQL): This query template aims to combine churn propensity predictions from {{source_table}} with user information from a table containing recent events. It calculates churn deciles, consolidates user IDs, and potentially adjusts event timestamps for consistency. The use of variables and placeholders makes it adaptable for different prediction sources and datasets.
- `templates/activation_user_import/churn_propensity_csv_export.sqlx` (Templated SQL): This script takes churn propensity predictions from a BigQuery table, prepares a temporary table with specific columns and calculations, and then exports this data to a CSV file in a GCS bucket. The use of dynamic SQL allows for flexibility in specifying the source prediction table.

**Note:** There is no need to modify the Dataflow job to use the new queries and send activation data to Google Analytics 4.

## Build custom audiences in GA4
**Note:**  It can take up to 24 hours after sending data through the Measurement Protocol before the activation user data becomes available in GA4.

To build your custom audience, follow the [Create an audience guide](https://support.google.com/analytics/answer/9267572?#create-an-audience) to navigate to the "Build new audience" view and select **Create a custom audience** option. 
![alt text](images/build_audience.png)
1. Choose the relevant custom event you want to target (e.g., `maj_purchase_propensity_30_15`)
1. Further refine your audience by selecting the custom user property that matches the use case (e.g., `MAJ Purchase Propensity p_p_decile`) and choose the specific user property values to include. **Note:** Decile values are in descending order, with the first decile (value: `1`) containing users with the highest propensity or lifetime value.
1. Give your audience a clear and descriptive name.
1. Click the save button to create the custom audience.

Now you have a custom audience that is automatically updated as new activation events are sent by the activation process. This custom audience can then be used for targeted remarketing campaigns in Google Ads or other platforms. Follow the [Share audiences guide](https://support.google.com/analytics/answer/12800258) to learn how to export your audience for use in external platforms.

**Important:** If you are using User Data Import only use the customer user properties and remove the custom event filtering.

## Alternative 1 - Activation through Google Ads Audience Manager Manual Import and Google Tag Dynamic Remarketing events



## Alternative 2 - Activation using User Data Import
GA4 [user-data import](https://support.google.com/analytics/answer/10071143?hl=en) is a file based batch import manually initiated through the GA4 console. Do the following steps for the user-data import.

- Export the prediction data by calling a stored procedure. For each of the use cases the corresponde procedure call are listed in the following table:

| Use Case |	Procedure Call |
| -------- | ------- |
| Purchase Propensity | ``CALL `activation.export_purchase_propensity_predictions`('purchase_propensity.predictions_2024_05_30T02_03_10_419Z_751_view');`` |
| Customer Lifetime Value  | ``CALL `activation.export_cltv_predictions`('customer_lifetime_value.predictions_2024_05_30T03_02_07_517Z_917_view_final');`` |
| Demographic Audience Segmentation | ``CALL `activation.export_audience_segmentation_predictions`('audience_segmentation.pred_audience_segmentation_inference_15_1717066870_view');`` |
| Interest based Audience Segmentation | ``CALL `activation.export_auto_audience_segmentation_predictions`('auto_audience_segmentation.predictions_2024_05_30T04_02_47_517Z_877');`` |

**Note:** replace the table name in the sample code with the actual prediction table name in your environment.

- Navigate to the `csv-export` folder within your `activation-app` bucket in Google Cloud Storage. Download the CSV file from previous step. The files are named according to the following pattern:

| Use Case |	Export file name |
| -------- | ------- |
| Purchase Propensity | `csv-export/purchase_propensity-000000000000.csv` |
| Customer Lifetime Value  | `csv-export/cltv-000000000000.csv` |
| Demographic Audience Segmentation | `csv-export/audience_segmentation-000000000000.csv` |
| Interest based Audience Segmentation | `csv-export/auto_audience_segmentation-000000000000.csv` |

**Note:** If you have a large number of users in the prediction tables the csv file export can output multiple files with incremental file suffix attached to the use case based file name. In that case you need to download all the files.

- Import the data from GA4 console
1. In GA4 Admin console choose **Data Import**

  ![alt text](images/ga4_data_import1.png)

2. Choose **Create data source** and select **Data type** `User data by Client ID`

3. Give the data source a descriptive name.

4. Choose **Manual CSV upload** and **Upload CSV**

5. Select the export file you downloaded from GCS bucket in the previous step, choose **Next**

6. Map out the field based on the Use Case you currently loading predictions for. The following is a sample for the purchase propensity mapping.

![alt text](images/ga4_data_import2.png)

7. Choose **Import**

## Alternative 3 - Activation through Smart Bidding Strategy
To activate lead score propensity predictions via [Smart Bidding Strategy](https://support.google.com/google-ads/answer/7065882), we translate predicted decile segments into monetary values, sent as conversion events to GA4. This allows you to use Google Ads strategies for [maximizing conversion value](https://support.google.com/google-ads/answer/7684216) and [target ROAS](https://support.google.com/google-ads/answer/6268637) with custom event values as the target.

This also allows you to use [Search Ads 360 bid strategies](https://support.google.com/searchads/answer/6231813?hl=en).

**DISCLAIMER:**

**1. If you are using a bidding strategy for branded Search campigns (or any other lower funnel), this bidding strategy is not best suited.**

**2. If you are bidding towards online purchases which are tracked via [GA4 Key conversion events](https://support.google.com/analytics/answer/12844695?hl=en), this bidding strategy is not best suited.**

### Configure translation values
This section explains how to configure the translation of event propensity predictions into monetary values for Smart Bidding.

#### Understanding the Configuration File:
The [vbb_activation_configuration.jsonl](../templates/vbb_activation_configuration.jsonl) file controls how predicted deciles are converted into monetary values. It contains two key fields:

- `value_norm`: Represents the typical or average transaction value for your GA4 property. This provides a baseline for calculating monetary values.
- `decile_multiplier`: An array of multipliers, one for each decile. These multipliers determine how much each decile is valued relative to the value_norm.

#### Configuration Steps:

1. Set `value_norm`:
    - Open the [vbb_activation_configuration.jsonl](../templates/vbb_activation_configuration.jsonl) file.
    - Locate the entry where `"activation_type":"event-propensity"`.
    - Modify the `value_norm` field to reflect the average transaction value specific to your GA4 property. For example, if your average transaction value is $200, set `value_norm` to 200.

1. Set `decile_multiplier`:s:
    - For each decile (1 through 10), adjust the `multiplier` value to reflect how much you value users in that decile.
    - A higher multiplier signifies a higher value. For example, a multiplier of 3.5 for decile 1 means you value users in that decile 3.5 times more than the average customer.

**Important**: To exclude lower-value deciles from smart bidding, set their decile_multiplier to 0. This prevents predictions for those deciles from being sent to GA4.

**Calculate multiplier example:**
The following example provide a way to use quantative analysis to derived the multiplier value for each decile. The query uses the prediction result table, which contains purchase propensity predictions and associated user data.
```sql
WITH
  base AS (
  SELECT
    user_ltv_revenue,
    NTILE(10) OVER (ORDER BY prediction_prob DESC) AS p_p_decile,
  FROM
    `purchase_propensity.predictions_YYYY_MM_DDTHH_mm_ss_xxxx_xxx_view`),
  segments_ltv AS (
  SELECT
    SUM(user_ltv_revenue) AS seg_total_revenue,
    AVG(user_ltv_revenue) AS avg_seg_revenue,
    p_p_decile
  FROM
    base
  GROUP BY
    p_p_decile),
  total_avg AS (
  SELECT
    AVG(user_ltv_revenue) AS avg_revenue
  FROM
    base
  WHERE
    p_p_decile IS NOT NULL)
SELECT
  sg.*,
  sg.avg_seg_revenue/t.avg_revenue AS multiplier
FROM
  segments_ltv AS sg,
  total_avg AS t
ORDER BY
  sg.p_p_decile ASC
```
The SQL query calculates the `multiplier` by dividing `avg_seg_revenue` (average revenue per decile) by `avg_revenue` (overall average revenue)

In the example `user_ltv_revenue` field is used, but you can replace it with other relevant numeric metrics depending on their business goals. For example, if the goal is to maximize conversions, the query could use a conversion value metric instead. The key is to choose a metric that aligns with the desired optimization strategy.

**Example:**
```json
{"activation_type":"purchase-propensity","value_norm":150,"decile_multiplier":[{"decile":1,"multiplier":5.5},{"decile":2,"multiplier":3},{"decile":3,"multiplier":2},{"decile":4,"multiplier":1},{"decile":5,"multiplier":0},{"decile":6,"multiplier":0},{"decile":7,"multiplier":0},{"decile":8,"multiplier":0},{"decile":9,"multiplier":0},{"decile":10,"multiplier":0}]}
```
In this example:
- The average transaction value (`value_norm`) is set to $150.
- Users in the top decile are valued 5.5 times higher than the average customer.
- Deciles 5 through 10 are excluded from smart bidding (`multiplier` is 0).

**Important**:
- Maintain the exact formatting of the JSON file. Do not add extra lines or commas as this will cause errors when importing the configuration into BigQuery.
- The formula for calculating the final monetary value for each decile is:` value_norm * decile_multiplier`.

### Upload configuration 
This section outlines the process of uploading your Smart Bidding configuration to Google Cloud Storage (GCS) and then loading it into BigQuery for use in the activation pipeline.

1. Run terraform apply to upload configuration into GCS bucket:
    ```
    cd infrastructure/terraform
    terraform apply -target=module.activation[0].google_storage_bucket_object.vbb_activation_configuration_file
    ```
1. Run [load_vbb_activation_configuration](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!6m3!1s!2sactivation!3sload_vbb_activation_configuration) stored procedure to load configuration into BigQeury

1. Control the configuration in [vbb_activation_configuration](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1s!2sactivation!3svbb_activation_configuration) BigQuery table

### Send Smart Bidding activation events to GA4
You can manually trigger a activation pipeline execution for Smart Bidding action by following [activation triggering process](#activation-process-triggering) where you set the `activation_type` value to `purchase-propensity-vbb-30-15`

To configure the prediction pipeline to automatically trigger activation pipeline for Smart Bidding change the pipeline configuration parameter in [config.yaml.tftpl](../config/config.yaml.tftpl)
and set `vertex_ai.pipelines.purchase_propensity.prediction.pipeline_parameters.pubsub_activation_type` to `purchase-propensity-vbb-30-15`
and re-apply terraform to redeploy the pipeline:
  ```
  cd infrastructure/terraform
  terraform apply -target=module.pipelines[0].null_resource.compile_purchase_propensity_prediction_pipelines
  ```

### Google Analytics configuration
After the activation events have been send it will take ruffly 24 hours for them to appear in the `Admin -> Events` view. Once you see `maj_purchase_propensity_vbb_30_15` showing up in the event list mark it as key event.
![alt text](images/vbb_mark_key_event.png)

### Google Ads configuration

Follow the [Set up Smart Bidding](https://support.google.com/google-ads/answer/10893605) guide to configure the bidding strategy to optimize for conversion value with `maj_purchase_propensity_vbb_30_15` as the conversion event.

## Monitoring & Troubleshooting
The activation process logs all sent Measurement Protocol messages in log tables within the `activation` dataset in BigQuery. This includes both successful and failed transmissions, allowing you to track the progress of the activation, get number of events sent to GA4 and identify any potential issues.

### Cloud Resources Used in Activation
The following Cloud resources facilitate the activation flow. Use the links to access each resource's console page, verify its operational status, and troubleshoot any issues using the resource logs.
| Resource |	Description | Link |
| -------- | ------- | --------- |
| Pub/Sub Topic | Topic where activation events are sent to trigger the activation process. | [activation-trigger](https://console.cloud.google.com/cloudpubsub/topic/detail/activation-trigger) |
| Cloud Functions | Function that listens to the activation topic and orchestrates the activation Dataflow process. | [activation-function](https://console.cloud.google.com/functions/details/us-central1/activation-trigger) |
| Dataflow Job | The actual activation process runs here. | [activation-jobs](https://console.cloud.google.com/dataflow/jobs) |
|BigQuery| Stores activation logs. | [activation-dataset](https://console.cloud.google.com/bigquery?ws=!1m4!1m3!3m2!1sPROJECT!2sactivation) **Note:** replace the `PROJECT` placeholder in the link with your Google Cloud project ID |
| Cloud Storage | Stores all configuration files and templates. | [activation-files](https://console.cloud.google.com/storage/browser/activation-app-PROJECT) **Note:** replace the `PROJECT` placeholder in the link with your Google Cloud project ID |

### Monitoring Activation Runs
To monitor and troubleshoot specific activation runs, use the [Dataflow Cloud console](https://console.cloud.google.com/dataflow/jobs). Here, you can:

* **Check Run Status:** View the overall status of each activation run, including whether it is currently running, succeeded, or failed.
* **Inspect Step Details:** Drill down into individual steps within the activation processing pipeline to see their progress and identify any errors.
* **Access Logs:** View detailed logs for each activation run to pinpoint the exact cause of any issues and troubleshoot them effectively.

## Analyze Prediction Results
Learn how to leverage the MAJ dashboard to gain a[ comprehensive understanding of your prediction results](prediction_result_analysis.md).
