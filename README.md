# Marketing Analytics Jumpstart
Marketing Analytics Jumpstart is a terraform automated, quick-to-deploy, customizable end-to-end marketing solutions on Google Cloud Platform (GCP). This solutions aims at helping customer better understand and better use their digital advertising budget.

Customers are looking to drive revenue and increase media efficiency be identifying, predicting and targeting valuable users through the use of machine learning. However, marketers first have to solve the challenge of having a number of disparate data sources that prevent them from having a holistic view of customers. Marketers also often don't have the expertise and/or resources in their marketing departments to train, run, and activate ML models on paid channels. Without this solution that enables innovation through predictive analytics, marketers are missing opportunities to advance their marketing program and accelerate key goals and objectives (e.g. acquire new customers, improve customer retention, etc).

## Benefits
After installing the solutions users will get:
* Scheduled ETL jobs for an extensible logical data model based on the Google Analytics 4 (GA4) and Google Ads (GAds) daily exports
* Validated feature engineering SQL transformations from event-level data to user-level data for machine learning models training and prediction
* End-to-end ML pipelines for Purchase Propensity, Customer Lifetime Value, Audience Segmentation and Value Based Bidding
* Dashboard for interpreting the data, model predictions and operate the pipelines and jobs in a seamless manner
* Activation application that sends models prediction to GA4 as custom dimensions

## Target Audience
This solution is intended for Marketing Technologist teams using GA4 and GAds products. It facilitates efforts to store, transform, analyze marketing data, and programmatically creates audiences segments in Google Ads to support conversion optimization and remarketing campaigns.

## Use Cases
This solution enables customer to plan and take action on their marketing campaigns by interpreting the insights provided by four common predictive use cases (purchase propensity, customer lifetime value, audience segmentation and aggregated value based bidding) and an operation dashboard that monitors Campaigns, Traffic, User Behavior and Models Performance, using the best of Google Cloud Data and AI products and practices.

These insights are used to serve as a basis to optimize paid media efforts and investments by:
* Building audience segments by using all Google first party data to identify user interests and demographic characteristics relevant to the campaign
* Improving campaign performance by identifying and targeting users deciles most likely to take an action (i.e. purchase, sign-up, churn, abandon a cart, etc)
* Driving a more personalized experience for your highly valued customers and improve return on ads spend (ROAS) via customer lifetime value
* Attributing bidding values to specific users according to their journeys through the conversion funnel which Ads platform uses to guide better campaign performance in specific markets

## Repository Structure
The solution's source code is written in Terraform, Python, SQL, YAML and JSON; and it is organized into five main folders:
* `config/`: This folder contains the configuration file for the solution. This file define the parameters and settings used by the various components of the solution.
* `infrastructure/terraform/`: This folder contains the Terraform modules, variables and the installation guide to deploy the solution's infrastructure on GCP.
    * `infrastructure/terraform/modules/`: This folder contains the Terraform modules and their corresponding Terraform resources. These modules corresponds to the architectural components broken down in the next section.
* `python/`: This folder contains most of the Python code. This code implements the activation application, which sends model predictions to Google Analytics 4; and the custom Vertex AI pipelines, its components and the base component docker image used for feature engineering, training, prediction, and explanation pipelines. It also implements the cloud function that triggers the activation application, and the Google Analytics Admin SDK code that creates the custom dimensions on the GA4 property.
* `sql/`: This folder contains the SQL code and table schemas specified in JSON files. This code implements the stored procedures used to transform and enrich the marketing data, as well as the queries used to invoke the stored procedures and retrieve the data for analysis.
* `templates/`: This folder contains the templates for generating the Google Analytics 4 Measurement Protocol API payloads used to send model predictions to Google Analytics 4.

In addition to that, there is a `tasks.py` file which implements python invoke tests who hydrate values to the JINJA template files with the `.sqlx` extension  located in the `sql/` folder that defines the DDL and DML statements for the bigquery datasets, tables, procedures and queries.

## High Level Architecture
![](https://i.imgur.com/5D3WPEb.png)

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

5. Activation Application:
* Dataflow: This tool processes the model predictions and sends them to Google Analytics 4 via the Measurement Protocol API.
* User-level Predictions: These predictions are used to enhance your Google Analytics 4 data with insights about user behavior and purchase likelihood.

6. Dashboards:
* Looker Studio: This tool provides interactive dashboards for visualizing the performance of your Google Ads campaigns, user behavior in Google Analytics 4, and the results of the machine learning models.

7. Monitoring:
* Dataform Jobs: These jobs are monitored for errors to ensure the data transformation process runs smoothly.
* Vertex AI Pipelines Runs: These runs are monitored to track the performance and success of the machine learning pipelines.

This high-level architecture demonstrates how Marketing Analytics Jumpstart integrates various Google Cloud services to provide a comprehensive solution for analyzing and activating your marketing data.

## Installation Pre-Requisites
- [ ] [Create GCP project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project) and [Enable Billing](https://cloud.google.com/billing/docs/how-to/modify-project)
- [ ] Set up [Google Analyics 4 Export](https://support.google.com/analytics/answer/9823238?hl=en#zippy=%2Cin-this-article) and [Google Ads Export](https://cloud.google.com/bigquery/docs/google-ads-transfer) to Bigquery
- [ ] [Backfill](https://cloud.google.com/bigquery/docs/google-ads-transfer) BigQuery Data Transfer service for Google Ads
- [ ] Have existing Google Analytics 4 property with [Measurement ID](https://support.google.com/analytics/answer/12270356?hl=en)

## Installation Permissions and Privileges
- [ ] Google Analytics Property Editor or Owner
- [ ] Google Ads Reader
- [ ] Project Owner for GCP Project
- [ ] Github or Gitlab account priviledges for repo creation and access token. [Details](https://cloud.google.com/dataform/docs/connect-repository)

## Installation
Please follow the step by step installation guide with [![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart.git&cloudshell_git_branch=main&cloudshell_workspace=&cloudshell_tutorial=infrastructure/cloudshell/tutorial.md)

**Note:** If you are working from a forked repository, be sure to update the `cloudshell_git_repo` parameter to the URL of your forked repository for the button link above.

The detailed installation instructions can be found at the [Installation Guide](./infrastructure/README.md).

## Contributing
We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how
to publish your contributions.

## License
This project is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Resources


## Disclaimer
This is not an officially supported Google product.
This solution in a work in progress and currently in the preview stage.

