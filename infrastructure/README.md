# Marketing Data Engine Installation Guide

## Overview

Marketing Data Engine consists of several components - marketing data store (MDS), feature store, ML pipelines, 
the activation pipeline and dashboards. This document describes the sequencing of installing these components. 

## Prerequisites
### Marketing Analytics Data Sources
* Set up Google Analytics 4 Export to Bigquery - TODO: links
* Set up Google Ads Export to Bigquery - TODO: links

Make sure the exports use the same BigQuery location, either regional or multi-regional one.

### Destination Projects
The Terraform scripts don’t create Google Cloud projects in customer environments, these projects need to be created
before the scripts can be run. It is possible to install the whole solution in a single project if the projected
BigQuery data volume is small (megabytes or low digit gigabytes of additional data per day). But for larger customer
installations and more granular access control multiple projects can be used.

* MDS data storage project for all the data curated by the solution.
* MDS data processing project for hosting the Dataform scripts and running BigQuery curation jobs.
* ML pipeline features engineering, model training, model inference and activation application.
* Dashboard query processing project. In case of high volume Dashboard usage this project can enable BigQuery BI Engine to
accelerate the query originated from the dashboard.

Users or service accounts used to run the Terraform scripts need to have Owner roles on these projects.
For installing MDS, they should also have the BigQuery Admin role on the source projects in order to grant data read
access to the service accounts created by the Terraform scripts.
For installing ML pipelines and the activation application, they should have the BigQuery Data Reader role on the
datasets, tables and views populated by the MDS.
For installing the Dashboards, they should have the BigQuery Data Reader role on the datasets, tables and views
populated by the MDS.

## Create Dataform Git Repository

MDS uses Dataform as the tool to run the data transformation. Dataform uses a private GitHub or GitLab
repository to store SQL transformation scripts. Customers will need to create a repository as part of the MDS
installation process.

1. Create a **private** empty repository in your GitHub or GitLab account.
2. On your computer, check out the blank GitHub or GitLab repository. Instructions below assume that the repository
   will be hosted on GitHub.
3. On your computer, in a separate folder check out the GitHub repository which contains the MDS Dataform scripts.
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
6. Generate a GitHub personal access token (classic). You will need to use it instead of a Git password when accessing GitHub. For details,
   see [GitHub documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
   .
   You will need to provide this token to the Terraform scripts using a Terraform variable.

## Installing the MDS, ML pipelines, the feature Store, and the activation pipeline

These components are installed using Terraform scripts.

Follow instructions in [terraform/README.md](terraform/README.md)

## Installing Dashboards

Dashboards are implemented using Looker Studio.

Follow instructions in [../python/lookerstudio/README.md](../python/lookerstudio/README.md)

