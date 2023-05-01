# How to Contribute

We would love to accept your patches and contributions to this project.

## Before you begin

### Sign our Contributor License Agreement

Contributions to this project must be accompanied by a
[Contributor License Agreement](https://cla.developers.google.com/about) (CLA).
You (or your employer) retain the copyright to your contribution; this simply
gives us permission to use and redistribute your contributions as part of the
project.

If you or your current employer have already signed the Google CLA (even if it
was for a different project), you probably don't need to do it again.

Visit <https://cla.developers.google.com/> to see your current agreements or to
sign a new one.

### Review our Community Guidelines

This project follows [Google's Open Source Community
Guidelines](https://opensource.google/conduct/).

## Contribution process

### Code Reviews

All submissions, including submissions by project members, require review. We 
use [GitHub pull requests](https://docs.github.com/articles/about-pull-requests)
for this purpose.

## Contributor Guide

### Fork this repo.

Follow the typical Github guide on how to [fork a repo](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

**Note**: 
1. To keep track of the new releases, configure git to [sync your fork with this upstream repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo#configuring-git-to-sync-your-fork-with-the-upstream-repository).
2. Don't submit a Pull Request to this upstream Github repo if you don't want to expose your environment configuration. You're at your own risk at exposing your company data.
3. Observe your fork is also public, you cannot make your own fork a private repo.

### Complete the installation guide

Complete the installation guide in a Google Cloud project in which you're developer and/or owner.

### Configure Continuous Integration recipes

Connect your Github repository by following this [guide](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github).

In your Google Cloud project, configure Cloud Build triggers to be executed when you push code into your branch. Update the Clould build recipes in the `cloudbuild` folder and deploy them.

### Update GCloud and Install Beta

```bash
gcloud components update
gcloud components install beta
```

### Install packages to define components, run locally and compile pipeline

```bash
pip install poetry
poetry install
```

### Modify the code and configurations as you prefer

Do all the code changes you wish. 
If you're implementing new use cases, add these resources to the existing terraform module components.
Otherwise, in case you're implementing a new component, implement your own terraform module for it.

### Manual Re-Deployment

Change the values in the terraform templates located in the `infrastructure/terraform` folder and deploy the code your google cloud project.

```bash
terraform init
terraform plan
terraform apply
```