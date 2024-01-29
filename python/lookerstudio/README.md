# Marketing Analytics Jumpstart Looker Studio Dashboard

## Extract Looker Studio dashboard URL
Extract the URL used to create the dashboard from the Terraform output value:

```sh
echo "$(terraform -chdir=${TERRAFORM_RUN_DIR} output -raw lookerstudio_create_dashboard_url)"
```

Click on the long URL from the command output that will open a new browser tab that executes the copy operation and you will see a screen similar to below. This copy may take a few moments to execute but if it does not, close the tab and try clicking the link again.

![Opening Screen](images/opening.png)

Click on **Edit and share** to continue the copy process.

## Review Access

Review the data source configuration settings and then click on **Acknowledge and Save** to continue.

![Review Access](images/review_access.png)

Acknowledge the data sources you are adding to the report by clicking on **Add to report**.

![Add to Report](images/add_to_report.png)

A copy of the report named **Marketing Analytics Sample** is now saved to your own Looker Studio account.

## Configure Access

The data sources will default to owner credentials (your own). It is highly recommended that you either configure service account access or set the access to viewer so that each viewer will need viewer access to the product views in the datamart.
