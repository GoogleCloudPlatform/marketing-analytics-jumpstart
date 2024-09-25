# Marketing Analytics Jumpstart
Marketing Analytics Jumpstart is a terraform automated, quick-to-deploy, customizable end-to-end marketing solution on Google Cloud Platform (GCP). This solution aims at helping customer better understand and better use their digital advertising budget.

Customers are looking to drive revenue and increase media efficiency be identifying, predicting and targeting valuable users through the use of machine learning. However, marketers first have to solve the challenge of having a number of disparate data sources that prevent them from having a holistic view of customers. Marketers also often don't have the expertise and/or resources in their marketing departments to train, run, and activate ML models on paid channels. Without this solution that enables innovation through predictive analytics, marketers are missing opportunities to advance their marketing program and accelerate key goals and objectives (e.g. acquire new customers, improve customer retention, etc).


## Benefits
After installing the solution users will get:
* Scheduled ETL jobs for an extensible logical data model based on the Google Analytics 4 (GA4) and Google Ads (GAds) daily exports
* Validated feature engineering SQL transformations from event-level data to user-level data for reporting and machine learning models training and prediction
* End-to-end ML pipelines for Purchase Propensity, Customer Lifetime Value, Audience Segmentation and Value Based Bidding
* Dashboard for interpreting the data, model predictions and monitoring the pipelines and jobs in a seamless manner
* Activation application that sends models prediction to GA4 via Measurement Protocol API


## Who can benefit from this solution?
This solution is intended for Marketing Technologist teams using GA4 and GAds products. It facilitates efforts to store, transform, analyze marketing data, and programmatically creates audiences segments in Google Ads to support conversion optimization and remarketing campaigns.

| Role | User Journeys | Skillset | Can Deploy? |
|-------|-------------|----------|-------------|
| Marketing Scientist | Using an isolated and secure sandbox infrastructure to perform and monitor explorations with sensitive data. Using automated machine learning to accelerate time-to-value on building use cases solutions. Faster learning curve to quickly and easily access and analyze data from the marketing data store. Ability to collaborate with other teams by reusing similar components. | Vertex AI, Python, SQL, Data Science | No |
| Marketing Analyst | Simplifying the operation of the marketing data store (data assertions), machine learning pipelines (model training, prediction, explanation) and the activation application. Monitoring Ads Campaigns Performance, Web Traffic and Predictive Insights Reports. Interpreting the insights provided to plan and activate Ads campaigns. Defining audience segments using predictive metrics. | BigQuery, Looker Studio, Google Analytics 4, Google Ads | Yes |
 | Digital Marketing Manager | Gaining insights into customer behavior to improve marketing campaigns. Identifying and targeting new customers. Measuring the effectiveness of marketing campaigns. | Looker Studio, Google Analytics 4, Google Ads | No |
| IT/Data Engineer | Building and maintaining marketing data store transformation jobs. Developing and deploying custom marketing use cases reusing a consistent infrastructure. Integrating 1st party data and Google 3rd party data by extending the marketing data store. | Python, SQL, Google Cloud Platform, Data Engineering | Yes |


## Use Cases
This solution enables customer to plan and take action on their marketing campaigns by interpreting the insights provided by four common predictive use cases (purchase propensity, customer lifetime value, audience segmentation and aggregated value based bidding) and an operation dashboard that monitors Campaigns, Traffic, User Behavior and Models Performance, using the best of Google Cloud Data and AI products and practices.

These insights are used to serve as a basis to optimize paid media efforts and investments by:
* Building audience segments by using all Google first party data to identify user interests and demographic characteristics relevant to the campaign
* Improving campaign performance by identifying and targeting users deciles most likely to take an action (i.e. purchase, sign-up, churn, abandon a cart, etc)
* Driving a more personalized experience for your highly valued customers and improve return on ads spend (ROAS) via customer lifetime value
* Attributing bidding values to specific users according to their journeys through the conversion funnel which Ads platform uses to guide better campaign performance in specific markets

| Use Case | Data Sources | Model | Looker Report Name | Activation Event | Google Ads Campaign Optimization |
|-------|-------|-------|--------|--------|--------|
| Audience Segmentation | Google Analytics 4 | BQML Kmeans | Demographic based Audience Segmentation | [maj_audience_segmentation_15](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/templates/activation_type_configuration_template.tpl#L2) | [Custom Data Segments](https://support.google.com/google-ads/answer/2497941?sjid=12303667953034547771-NC#zippy=%2Cyour-data-segments-formerly-known-as-remarketing) |
| Auto Audience Segmentation | Google Analytics 4 | BQML Kmeans | Interest based Audience Segmentation | [maj_auto_audience_segmentation_15](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/templates/activation_type_configuration_template.tpl#L8) | [Custom Data Segments](https://support.google.com/google-ads/answer/2497941?sjid=12303667953034547771-NC#zippy=%2Cyour-data-segments-formerly-known-as-remarketing) |
| Customer Lifetime Value | Google Analytics 4 | Vertex AI Tabular Wokflows AutoML | Customer Lifetime Value | [maj_cltv_180_30](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/templates/activation_type_configuration_template.tpl#L23) | [Custom Data Segments](https://support.google.com/google-ads/answer/2497941?sjid=12303667953034547771-NC#zippy=%2Cyour-data-segments-formerly-known-as-remarketing) |
| Purchase Propensity | Google Analytics 4 | Vertex AI Tabular Wokflows AutoML | Propensity to Purchase | [maj_purchase_propensity_30_15](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/templates/activation_type_configuration_template.tpl#L28) | [Custom Data Segments](https://support.google.com/google-ads/answer/2497941?sjid=12303667953034547771-NC#zippy=%2Cyour-data-segments-formerly-known-as-remarketing) |
| Churn Propensity | Google Analytics 4 | Vertex AI Tabular Wokflows AutoML | Propensity to Churn | [maj_churn_propensity_30_15](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart/blob/main/templates/activation_type_configuration_template.tpl#L43) | [Custom Data Segments](https://support.google.com/google-ads/answer/2497941?sjid=12303667953034547771-NC#zippy=%2Cyour-data-segments-formerly-known-as-remarketing) |
| Aggregated Value Based Bidding | Google Analytics 4 | Vertex AI Tabular Wokflows AutoML | High Value Action | - | [Static Conversion Values](https://support.google.com/google-ads/answer/13064107?sjid=13060303839552593837-NA#zippy=%2Cset-a-conversion-value%2Cchange-a-conversion-value) <br><br> [Bid Adjustment](https://support.google.com/google-ads/answer/7068417?hl=en#zippy=%2Ctips-for-setting-up-data-segments-for-search-ads%2Csetting-bids-tailoring-ads-and-copying-campaigns) |

## Repository Structure
The solution's source code is written in Terraform, Python, SQL, YAML and JSON; and it is organized into five main folders:
* `config/`: This folder contains the configuration file for the solution. This file define the parameters and settings used by the various components of the solution.
* `infrastructure/terraform/`: This folder contains the Terraform modules, variables and the installation guide to deploy the solution's infrastructure on GCP.
    * `infrastructure/terraform/modules/`: This folder contains the Terraform modules and their corresponding Terraform resources. These modules corresponds to the architectural components broken down in the next section.
* `python/`: This folder contains most of the Python code. This code implements the activation application, which sends model predictions to Google Analytics 4; and the custom Vertex AI pipelines, its components and the base component docker image used for feature engineering, training, prediction, and explanation pipelines. It also implements the cloud function that triggers the activation application, and the Google Analytics Admin SDK code that creates the custom dimensions on the GA4 property.
* `sql/`: This folder contains the SQL code and table schemas specified in JSON files. This code implements the stored procedures used to transform and enrich the marketing data, as well as the queries used to invoke the stored procedures and retrieve the data for analysis.
* `templates/`: This folder contains the templates for generating the Google Analytics 4 Measurement Protocol API payloads used to send model predictions to Google Analytics 4.

In addition to that, there is a `tasks.py` file which implements python invoke tests who hydrate values to the JINJA template files with the `.sqlx` extension  located in the `sql/` folder that defines the DDL and DML statements for the BigQuery datasets, tables, procedures and queries.


## High Level Architecture
![High Level Architecture](docs/images/reference_architecture.png)

The provided architecture diagram depicts the high-level architecture of the Marketing Analytics Jumpstart solution. Let's break down the components:

1. Data Sources:
* Google Analytics 4 Export: This provides daily data exports from your Google Analytics 4 property to BigQuery.
* Google Ads Export: This provides daily data exports from your Google Ads account to BigQuery.

2. Marketing Data Store:
* Dataform: This tool manages the data transformation and enrichment process. It uses SQL-like code to define data pipelines that transform the raw data from Google Analytics 4 and Google Ads into a unified and enriched format.

3. Feature Store:
* BigQuery: This serves as the central repository for storing the features extracted from the marketing data.
* Vertex AI Pipelines: These pipelines automate the feature engineering process, generating features based on user behavior, traffic sources, devices, and other relevant factors.

4. Machine Learning Pipelines:
* Vertex AI Pipelines: These pipelines handle the training, prediction, and explanation of various machine learning models.
* Tabular Workflow End-to-End AutoML: This approach automates the model training process for tasks like purchase propensity and customer lifetime value prediction.
* Custom Training and Prediction Pipelines: These pipelines are used for the auto audience segmentation training and prediction; and for the aggregated value based bidding model explanation.
* Gemini Insights: This leverages the Gemini 1.5 Vertex AI LLM API to provide insights on user behaviour and revenue. Gemini is connected directly to BigQuery and the insights are provided via a Looker Studio report.

5. Activation Application:
* Dataflow: This tool processes the model predictions and sends them to Google Analytics 4 via the Measurement Protocol API.
* User-level Predictions: These predictions are used to enhance your Google Analytics 4 data with insights about user behavior and purchase likelihood.

6. Dashboards:
* Looker Studio: This tool provides interactive dashboards for visualizing the performance of your Google Ads campaigns, user behavior in Google Analytics 4, LLM inisghts and the results of the machine learning models.

7. Monitoring:
* Dataform Jobs: These jobs are monitored for errors to ensure the data transformation process runs smoothly.
* Vertex AI Pipelines Runs: These runs are monitored to track the performance and success of the machine learning pipelines.

This high-level architecture demonstrates how Marketing Analytics Jumpstart integrates various Google Cloud services to provide a comprehensive solution for analyzing and activating your marketing data.


## Advantages
1. Easy to deploy: Deploy the resources and use cases that you need.
2. Cost Effective: Pay only for the cost of infrastructure in order to maintain the Data Store, Feature Store and ML Models.
3. Keep control of your data: This solution runs entirely in your environment and doesn’t transfer data out of your ownership or organization.
4. Fondation for 1st Party Data Strategy: The data store can serves as a basis for your team to customize or implement your own use cases and enable in house expertise to thrive.
5. Enable team collaboration: Use Terraform to maintain dependency graph between the resources and to manage resources lifecycle.


## Installation Pre-Requisites
- [ ] [Create GCP project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project) and [Enable Billing](https://cloud.google.com/billing/docs/how-to/modify-project)
- [ ] Set up [Google Analyics 4 Export](https://support.google.com/analytics/answer/9823238?hl=en#zippy=%2Cin-this-article) and [Google Ads Export](https://cloud.google.com/bigquery/docs/google-ads-transfer) to Bigquery
- [ ] [Backfill](https://cloud.google.com/bigquery/docs/google-ads-transfer) BigQuery Data Transfer service for Google Ads
- [ ] Have existing Google Analytics 4 Property with [Measurement ID](https://support.google.com/analytics/answer/12270356?hl=en)

**Note:** Google Ads Customer Matching currently only works with Google Analytics 4 **Properties** linked to Google Ads Accounts, it won't work for subproperties or Rollup properties.

## Installation Permissions and Privileges
- [ ] Google Analytics Property Editor or Owner
- [ ] Google Ads Reader
- [ ] Project Owner for GCP Project
- [ ] Github or Gitlab account priviledges for repo creation and access token. [Details](https://cloud.google.com/dataform/docs/connect-repository)


## Installation

To facilitate the installation, use this Step by Step Installation Video.

[![Step by Step Installation Video](docs/images/YoutubeScreenshot.png)](https://youtu.be/JMnsIxTNbE4 "Marketing Analytics Jumpstart Installation Video")

Please follow this [Installation Guide](./infrastructure/README.md) to accompany the video.

Alternatively, follow the step by step installation guide with Google Cloud Shell.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart.git&cloudshell_git_branch=main&cloudshell_workspace=&cloudshell_tutorial=infrastructure/cloudshell/tutorial.md)

**Note:** If you are working from a forked repository, be sure to update the `cloudshell_git_repo` parameter to the URL of your forked repository for the button link above.


## Contributing
We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how
to publish your contributions.


## License
This project is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).


## Resources
This a list of public websites you can use to learn more about the Google Analytics 4, Google Ads, Google Cloud Products we used to build this solution.

| Websites | Description |
|----------|-------------|
| [github.com/GoogleCloudPlatform/marketing-analytics-jumpstart-dataform](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart-dataform) | Marketing Analytics Jumpstart Dataform Github Repository |
| [console.cloud.google.com/marketplace/product/bigquery-data-connectors/google_ads](https://console.cloud.google.com/marketplace/product/bigquery-data-connectors/google_ads) | BigQuery Data Transfer Service for Google Ads |
| [support.google.com/google-ads/*](https://support.google.com/google-ads/) [support.google.com/analytics/*](https://support.google.com/analytics/) | Google Ads and Google Analytics Support |
| [support.google.com/looker-studio/*](https://support.google.com/looker-studio/) | Looker Studio Support |
| [developers.google.com/analytics/*](https://developers.google.com/analytics/) [developers.google.com/google-ads/*](https://developers.google.com/analytics/) | Google Ads and Google Analytics Developers Guides |
| [cloud.google.com/developers/*](https://cloud.google.com/developers/) [developers.google.com/looker-studio/*](https://developers.google.com/looker-studio/) | Google Cloud & Looker Studio Developers Guides |
| [cloud.google.com/bigquery/docs/*](https://cloud.google.com/bigquery/docs/) [cloud.google.com/vertex-ai/docs/*](https://cloud.google.com/vertex-ai/docs/) [cloud.google.com/looker/docs/*](https://cloud.google.com/looker/docs/) [cloud.google.com/dataform/docs/*](https://cloud.google.com/dataform/docs/) | Google Cloud Product Documentation |
| [cloud.google.com/python/docs/reference/aiplatform/latest/*](https://cloud.google.com/python/docs/reference/aiplatform/latest/) [cloud.google.com/python/docs/reference/automl/latest/*](https://cloud.google.com/python/docs/reference/automl/latest/) [cloud.google.com/python/docs/reference/bigquery/latest/*](https://cloud.google.com/python/docs/reference/bigquery/latest/) | Google Cloud API References Documentation |


## Disclaimer
This is not an officially supported Google product.
This solution in a work in progress and currently in the preview stage.

