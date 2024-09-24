# Marketing Analytics Jumpstart Installation Guide

## Overview

Marketing Analytics Jumpstart consists of several components - marketing data store (MDS), feature store, ML pipelines,
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

### Permissions to create infrastructure and access source data

There are multiple ways to configure Google Cloud authentication for the Terraform installations. Terraform's Google
Provider [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference)
lists all possible options on how the authentication can be done. This installation guide assumes that will be using the
Application Default Credentials. You can change this by, for example, creating a dedicated service account and
setting `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT` environment variable before you run Terraform scripts. We will refer to the
identity which is used in the Terraform scripts (your email or the dedicated service account email) the "Terraform
principal" for brevity.

The Terraform principal will need to be granted certain permissions in different projects:

* the Owner role in all projects where the solution is to be installed. Required to install products related to the
  solution.
* the BigQuery [Data Owner role](https://cloud.google.com/bigquery/docs/control-access-to-resources-iam#required_roles)
  on the datasets containing the GA4 and Ads data exports. Required to grant data read access to
  a service account which will be created by the Terraform scripts. Follow the
  BigQuery [documentation](https://cloud.google.com/bigquery/docs/control-access-to-resources-iam#grant_access_to_a_dataset)
  on how to grant this permission on a dataset level.

### Dataform Git Repository

MDS uses [Dataform](https://cloud.google.com/dataform) as the tool to run the data transformation. Dataform uses a
private GitHub or GitLab repository to store SQL transformation scripts. Customers will need to create a repository and
copy the SQL scripts from a companion GitHub repo before running the Terraform scripts.

1. Create a **private** empty repository in your GitHub or GitLab account.
2. On your computer, check out the blank GitHub or GitLab repository. Instructions below assume that the repository
   will be hosted on GitHub.
3. On your computer or in a Cloud Shell, check out the GitHub repository which contains the MDS Dataform scripts.
    ```
    git clone https://github.com/googlecloudplatform/marketing-analytics-jumpstart-dataform.git
    ```
4. Push the contents of the source repository to your private repo
    ```
   cd marketing-analytics-jumpstart-dataform
   git remote add copy https://github.com/<your-account>/<repo>.git
   git branch -M main
   git push -u copy main
    ```
5. Clean the checkout directory
   ```shell
   cd ..
   rm -rf marketing-analytics-jumpstart-dataform
   ```
6. Generate a GitHub personal access token. It will be used by Dataform to access the repository. For details and
   additional guidance regarding token type, security and require permissions
   see [Dataform documentation](https://cloud.google.com/dataform/docs/connect-repository#create-secret). You don't need
   to create a Cloud Secret - it will be done by the Terraform scripts. You will need to provide the Git URL and the
   access token to the Terraform scripts using a Terraform variable.

### Google Analytics 4 Configurations and Permissions

The activation application uses sensitive information from the Google Analytics property, such as Measurement ID and API Secret. These information is stored temporarily on environment variables to be exported manually by the user. 

* A [Measurement ID](https://support.google.com/analytics/answer/12270356?hl=en) and [API secret](https://support.google.com/analytics/answer/9814495?sjid=9902804247343448709-NA) collected from the Google Analytics UI. In this [article](https://support.google.com/analytics/answer/9814495?sjid=9902804247343448709-NA) you will find instructions on how to generate the API secret.
* Editor or Administrator role to the Google Analytics 4 account or property. In this [article](https://support.google.com/analytics/answer/9305587?hl=en#zippy=%2Cgoogle-analytics) you will find instructions on how to setup.


## Installing the MDS, ML pipelines, the feature Store, and the activation pipeline

Once all the prerequisites are met you can install these components using Terraform scripts.

Follow instructions in [terraform/README.md](terraform/README.md)

## Installing Dashboards

Looker Studio Dashboards can be installed by following instructions
in [../python/lookerstudio/README.md](../python/lookerstudio/README.md)

