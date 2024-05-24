# Activation Process Guide
## Introduction
![tech architecture](images/activation_tech_architecture.png)
The activation process enriches your Google Analytics 4 (GA4) user profiles with custom properties based on machine learning predictions for the different use cases supported by MAJ. This enrichment enables granular audience segmentation for targeted remarketing campaigns.
The activation process is automated and built on Google Cloud Dataflow for efficient data processing and reliable data delivery into GA4.
This guide details how to monitor the activation process, leverage the enriched user data, and tailor the process to fit your specific requirements.
## Activation process overview

MAJ automatically creates the following custom events and user properties corresponding to each supported use case as part of the installation process:
| Use Case |	GA4 Custom Event | GA4 Custom User Properties |
| -------- | ------- | --------- |
| Purchase Propensity | `maj_purchase_propensity_30_15` |	`p_p_prediction`<br>`p_p_decile` |
| Customer Lifetime Value  | `maj_cltv_180_30` |	`cltv_decile` |
| Demographic Audience Segmentation | `maj_audience_segmentation_15` |	`a_s_prediction` |
| Interest based Audience Segmentation | `maj_auto_audience_segmentation_15` |	`a_a_s_prediction` |

For each use case, a corresponding SQL query template dictates how prediction values are selected and processed for activation:

| Use Case |	Query Template |
| -------- | --------- |
| Purchase Propensity | [purchase_propensity_query_template.sqlx](../templates/activation_query/purchase_propensity_query_template.sqlx)|
| Customer Lifetime Value  | [cltv_query_template.sqlx](../templates/activation_query/cltv_query_template.sqlx) |
| Demographic Audience Segmentation | [audience_segmentation_query_template.sqlx](../templates/activation_query/audience_segmentation_query_template.sqlx) |
| Interest based Audience Segmentation | [auto_audience_segmentation_query_template.sqlx](../templates/activation_query/auto_audience_segmentation_query_template.sqlx) |

The [activation configuration](../templates/activation_type_configuration_template.tpl) file links the GA4 custom events with their corresponding query templates and [GA4 Measurement Protocol payload template](../templates/app_payload_template.jinja2)

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

## Build custom audiences in GA4
**Note:**  It can take up to 24 hours after sending data through the Measurement Protocol before the activation user data becomes available in GA4.

To build your custom audience, follow the [Create an audience guide](https://support.google.com/analytics/answer/9267572?#create-an-audience) to navigate to the "Build new audience" view and select **Create a custom audience** option. 
![alt text](images/build_audience.png)
1. Choose the relevant custom event you want to target (e.g., `maj_purchase_propensity_30_15`)
1. Further refine your audience by selecting the custom user property that matches the use case (e.g., `MAJ Purchase Propensity p_p_decile`) and choose the specific user property values to include. **Note:** Decile values are in descending order, with the first decile (value: `1`) containing users with the highest propensity or lifetime value.
1. Give your audience a clear and descriptive name.
1. Click the save button to create the custom audience.

Now you have a custom audience that is automatically updated as new activation events are sent by the activation process. This custom audience can then be used for targeted remarketing campaigns in Google Ads or other platforms. Follow the [Share audiences guide](https://support.google.com/analytics/answer/12800258) to learn how to export your audience for use in external platforms.

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
