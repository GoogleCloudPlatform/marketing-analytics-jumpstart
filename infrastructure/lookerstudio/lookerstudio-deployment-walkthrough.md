## Marketing Data Engine Looker Studio Deployment Walkthrough

These steps will generate the URL to deploy the Looker Studio Marketing Data Engine dashboard.

## Environment Set-Up

The installation script's library requirements are minimal however if you wish, you can configure a virtual environment.

```sh
cd infrastructure/lookerstudio
python -m venv mde
source ./mde/bin/activate

pip install -r requirements.txt
```

This step includes the following:
- Install Python local env
- Launch local env
- Install dependencies

## Set-up Configuration

The file `config.ini` needs to be updated for the project and datasets where your Marketing Data Engine Dataform is deployed.

Specifically the following properties need to be set under the `[COMMON]` section:

```
[COMMON]
# TODO: Replace the values in this section with your own

project = project_id
ga4_dataset = marketing_ga4_v1_prod
ads_dataset = marketing_ads_v1_prod
```

You can use your favorite text editor such as vim, nano or even the built in editor in Cloud Console.

![Editor](https://github.com/TXZebra/marketing-data-engine/raw/main/infrastructure/lookerstudio/images/editor.png)

## Execute the script

You're ready to execute the script simply by running:

```sh
python lookerstudio_deployment.py
```

If execution is successful, you will see a long https://lookerstudio.google.com URL that creates a copy of the template report with your defined Marketing Data Engine datasets.

If there is an error, the script should output the appropriate error to help guide you in ensuring that you are executing with the right account and have appropriate permissions on the dataset.

Clicking on the link will open a new browser tab that executes the copy operation and you will see a screen similar to below. This copy may take a few moments to execute but if it does not, close the tab and try clicking the link again.

![Opening Screen](https://github.com/TXZebra/marketing-data-engine/raw/main/infrastructure/lookerstudio/images/opening.png)

Click on **Edit and share** to continue the copy process.

## Review Access

Review the data source configuration settings and then click on **Acknowledge and Save** to continue.

![Review Access](https://github.com/TXZebra/marketing-data-engine/raw/main/infrastructure/lookerstudio/images/review_access.png)

Acknowledge the data sources you are adding to the report by clicking on **Add to report**.

![Add to Report](https://github.com/TXZebra/marketing-data-engine/raw/main/infrastructure/lookerstudio/images/add_to_report.png)

A copy of the report named **Marketing Analytics Sample** is now saved to your own Looker Studio account.

## Configure Access

The data sources will default to owner credentials (your own). It is highly recommended that you either configure service account access or set the access to viewer so that each viewer will need viewer access to the product views in the datamart.