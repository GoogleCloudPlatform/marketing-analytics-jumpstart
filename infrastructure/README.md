# Marketing Data Engine Installation Guide

## Overview

Marketing Data Engine consists of several components - marketing data store (MDS), feature store, ML pipelines,
the activation pipeline and dashboards. This document describes the sequencing of installing these components.

## Prerequisites

### Marketing Analytics Data Sources

* Set up Google Analytics 4 Export to Bigquery. Please follow the
  set-up [documentation](https://support.google.com/analytics/answer/9358801?hl=en). The current version of MDS doesn't
  use streaming export tables.
* Set up Google Cloud Data Transfer Service to export Google Ads to Bigquery. Follow
  these [instructions](https://cloud.google.com/bigquery/docs/google-ads-transfer).

Make sure these exports use the same BigQuery location, either regional or multi-regional one. You can export the data
into the same project or different projects - the MDS will be able to get the data from multiple projects.

### Destination Projects

The Terraform scripts which are used to create the infrastructure don’t create Google Cloud projects themselves. These
projects need to be created before the scripts can be run and their ids will be provided to the script via Terraform
variables. It is possible to install the whole solution in a single project if the projected BigQuery data volume is
small (megabytes or low digit gigabytes of additional data per day). For larger installations or when more granular
access control is desired multiple projects can be used:

* MDS data storage project for all the data curated by the solution.
* MDS data processing project for hosting the Dataform scripts and running BigQuery curation jobs.
* ML pipeline features engineering, model training, model inference and activation application.
* Dashboard query processing project. In case of high volume Dashboard usage this project can enable BigQuery BI Engine
  to
  accelerate the query originated from the dashboard.

### Permissions for the Terraform Service Account

There is a dedicated service account used to run the Terraform script. That account will need to be granted certain
permissions in different projects:

* the Owner role in all projects where the solution is installed. Required to install products related to the solution.
* the BigQuery Admin role on the datasets containing the GA4 and Ads data exports. Required to grant data read access to
  the service accounts created by the Terraform scripts.

### Dataform Git Repository

MDS uses [Dataform](https://cloud.google.com/dataform) as the tool to run the data transformation. Dataform uses a
private GitHub or GitLab repository to store SQL transformation scripts. Customers will need to create a repository and
copy the SQL scripts from a companion GitHub repo before running the Terraform scripts.

1. Create a **private** empty repository in your GitHub or GitLab account.
2. On your computer, check out the blank GitHub or GitLab repository. Instructions below assume that the repository
   will be hosted on GitHub.
3. On your computer or in a Cloud Shell, check out the GitHub repository which contains the MDS Dataform scripts.
    ```
    git clone https://github.com/googlecloudplatform/marketing-data-engine-dataform.git
    ```
4. Push the contents of the source repository to your private repo
    ```
   cd marketing-data-engine-dataform
   git remote add copy https://github.com/<your-account>/<repo>.git
   git branch -M main
   git push -u copy main
    ```
5. Clean the checkout directory
   ```shell
   cd ..
   rm -rf marketing-data-engine-dataform
   ```
6. Generate a GitHub personal access token. It will be used by Dataform to access the repository. For details and
   additional guidance regarding token type, security and require permissions
   see [Dataform documentation](https://cloud.google.com/dataform/docs/connect-repository#create-secret). You don't need
   to create a Cloud Secret - it will be done by the Terraform scripts. You will need to provide the Git URL and the
   access token to the Terraform scripts using a Terraform variable.

### GitHub repository with a Google Cloud Source Repository that are used by Cloud Build triggers of the ML processing pipelines.

TODO: details

### Install Python Poetry

[Poetry](https://python-poetry.org/docs/) is a Python's tool for dependency management and packaging.

```bash
  curl -sSL https://install.python-poetry.org | python3 -
```

## Installing the MDS, ML pipelines, the feature Store, and the activation pipeline

Once all the prerequisites are met you can install these components using Terraform scripts.

Follow instructions in [terraform/README.md](terraform/README.md)

## Installing Dashboards

Looker Studio Dashboards can be installed by following instructions
in [../python/lookerstudio/README.md](../python/lookerstudio/README.md)

