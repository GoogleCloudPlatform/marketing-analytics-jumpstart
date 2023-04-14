# Terraform Scripts for Marketing Data Store

The Terraform scripts in this folder create the infrastructure to start data ingestion
into BigQuery

## Pre-requirements

- A Google Cloud project
- Billing enabled for the project

## Resources created

At this time, the Terraform scripts in this folder create:

- Enables the APIs needed
- IAM bindings needed for the GCP services used
- Secret in GCP Secret manager for the private Github repo
- Dataform repository connected to the Github repo

## Preparation
- Copy [terraform-sample.tfvars](terraform-sample.tfvars) to `terraform.tfvars`
  file and edit variables.

```
    cp terraform-sample.tfvars terraform.tfvars
    vim terraform.tfvars
```

- Launch Terraform

```
    terraform init
    terraform plan
    terraform apply
```


