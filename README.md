# Marketing Data Engine

Marketing Data Engine consists of an easy, flexible and automated implementation of an end-to-end solution that enables
Marketing Technologist teams to store, transform, analyze marketing data, and programmatically send predictive events to
Google Analytics 4 to support conversion optimization and remarketing campaigns.

This solution also demonstrates how to implement three common predictive use cases (purchase propensity, customer
lifetime value and audience segmentation) and a dashboard to monitor Campaigns Performance leveraging the best of Google
Cloud data and AI products and practices.

## Disclaimer

This is not an officially supported Google product. The detailed documentation, monitoring setup, performance tuning,
and configuration specifications are work in progress. Some products used in this solution are currently in
Preview and might not be suitable for production pipelines.

## Introduction

Marketing Analytics commonly involves leveraging ML models and building ML pipelines providing audience management
platforms with predictive conversion events or audiences to help the Marketing team to build audiences and come up with
more effective marketing campaigns that drive better performance and ROAS.

This solution includes the following components: a petabyte-scale marketing data store (MDS), a reusable feature store,
robust and parameterizable ML pipelines (feature engineering, training and inference pipelines), an activation pipeline
that programmatically sends predictive conversion events estimates to Google Analytics 4 and Google Ads, and a dashboard
to monitor campaign performance.

The MDS builds an easy-to-use logical data model using data from Google Ads and Google Analytics 4 data exports. The
feature store and ML pipelines use Google Analytics 4 behavioural data. The following Google Cloud Products are used:
BigQuery, Dataform, Workflows, Vertex AI Pipelines, Vertex AI Tabular Workflows, DataFlow, Cloud Function, Cloud
Pub/Sub.

## Installation Guide

The installation of this solution requires a multistep process.

Please follow the [Installation Guide](./infrastructure/README.md) to deploy this solution.

## Contributing

We welcome all feedback and contributions!  Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more information on how
to publish your contributions.
