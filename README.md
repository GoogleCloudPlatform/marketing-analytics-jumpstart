# Marketing Data Engine

Marketing Data Engine consists of an easy, flexible and automated implementation of an end-to-end solution that enables Marketing Technologist teams to store, transform, analyze maketing data, and programatically sends predictive events to Google Analytics 4 to support conversion optimization and remarketing campaigns. 

This solution also demonstrates how to implement three common predictive use cases (purchase propensity, customer lifetime value and audience segmentation) and a dashboard to monitor Campaigns Performance leveraging the best of Google Cloud data and ai products and practices.

## Disclaimer

This is not an officially supported Google product. This solution is not finalized or validated with multiple customers. Use it at your own risk. Updates and implementation timeline to be informed soon.

## Introduction

Marketing Analytics commonly involves leveraging ML models and building ML pipelines providing audience management platforms with predictive conversion events or audiences to help the Marketing team to build audiences and come up with more effective marketing campaigns that drive better performance and ROAS.

This solution includes the following components: a petabyte-scale marketing data store (MDS), a reusable feature store, robust and parametrizable ml pipelines (feature engineering, training and inference pipelines), an activation pipeline that programatically sends predictive conversion events estimates to Google Analytics 4 and Google Ads, and a dashboard to monitor campaigns performance.

The MDS builds an easy-to-use logical data model using Google Ads and Google Analytics 4 data exports. The feature store and ml pipelines use Google Analytics 4 behavioural data. The following Google Cloud Products are used: BigQuery, DataForm, Vertex AI Pipelines, Vertex AI Tabular Workflows, DataFlow, Cloud Function, Cloud Pub/Sub.

## Installation Guide

The installation of this solution requires a multi-step process.

Please read [Installation Guide](./infrastructure/terraform/README.md) for more information on how to deploy this solution.

## Contributing

We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how to publish your contributions.
