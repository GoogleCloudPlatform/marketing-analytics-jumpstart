# Marketing Analytics Jumpstart

Marketing Analytics Jumpstart is a terraform based, quick-to-deploy end-to-end marketing solutions on Google Cloud. This solutions aims at helping customer better understand and better use their digital advertising budget.
After installing the solutions users will get:
* Scheduled ETL jobs for an extensible data model based on the Google Analytics 4 and Google Ads daily exports
* End-to-end ML pipelines for Purchase Propensity, Customer Lifetime Value and Audience Segmentation
* Dashboard for interpreting the data and model predictions
* Activation pipeline that sends models prediction to Google Analytics 4 as custom dimensions

This solution handles scheduling, data engineering, data modeling, data normalization, feature engineering, model training, model evaluation, and programatically sending predictions back into Google Analytics 4.

## Disclaimer

This is not an officially supported Google product.
This solution in a work in progress and currently in the preview stage.

## High Level Architecture

![](https://i.imgur.com/5D3WPEb.png)

## Pre-Requisites
- [ ] [Create GCP project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project) and [Enable Billing](https://cloud.google.com/billing/docs/how-to/modify-project)
- [ ] Set up [Google Analyics 4 Export](https://support.google.com/analytics/answer/9823238?hl=en#zippy=%2Cin-this-article) and [Google Ads Export](https://cloud.google.com/bigquery/docs/google-ads-transfer) to Bigquery
- [ ] [Backfill](https://cloud.google.com/bigquery/docs/google-ads-transfer) BigQuery Data Transfer service for Google Ads
- [ ] Have existing Google Analytics 4 property with [Measurement ID](https://support.google.com/analytics/answer/12270356?hl=en)

## Permissions
- [ ] Google Analytics Property Editor or Owner
- [ ] Google Ads Reader
- [ ] Project Owner for GCP Project
- [ ] Github or Gitlab account priviledges for repo creation and access token. [Details](https://cloud.google.com/dataform/docs/connect-repository)

## Installation

Please follow the [Installation Guide](./infrastructure/README.md) to deploy this solution.

## Contributing

We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how
to publish your contributions.
