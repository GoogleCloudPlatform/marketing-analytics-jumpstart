# Marketing Analytics Jumpstart
Marketing Analytics Jumpstart consists of an easy, extensible and automated implementation of an end-to-end solution that enables Marketing Technology teams to store, transform, enrich with 1PD and analyze marketing data, and programmatically send predictive events to Google Analytics 4 to support conversion optimization and remarketing campaigns.

## Developer pre-requisites
Use Visual Studio Code to develop the solution. Install Gemini Code Assistant, Docker, Github, Hashicopr Terraform, Jinja extensions.
You should have Python 3, Poetry, Terraform, Git and Docker installed in your developer terminal environment.

## Preparing development environment

### Installing Python dependencies
```bash
gcloud init
python3.7 -m venv ~/.venvs/myenv
source ~/.venvs/myenv/bin/activate
gcloud config configurations activate propensity-modelling
pip3 install -r requirements-dev.txt
pip3 install pipenv
```

### Installing Terraform
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Manually testing template rendering from yaml file
```bash
inv apply-env-variables-procedures --env-name=prod
```

### Testing using pyTest
Tests are configuration is part of *pyproject.toml*
Automatically running tests will aslo execute code coverage.
*variables* will be imported from config/dev.yaml to the test suite and used in testing

To execute tests on terminal
```bash
poetry run pytest -c pyproject.toml
```

## Customizing the solution
The solution is customizable using a set of configurations defined in the config file in YAML format located in the `config/` folder, the terraform files located in the `infrastructure/terraform/` folder, the Python files located in the `python/` folder, the SQL files located in the `sql/` folder, and the template files located in the `templates/` folder.

Here's a brief breakdown of the contents of each folder:
* `config/`:
* * `config.yaml.tftpl`: This file contains the main configuration parameters for the solution, including the project ID, dataset names, and pipeline schedules.
* `infrastructure/terraform/`:`
* * `terraform.tfvars`: This file contains the Terraform variables that can be used to override the default configuration values and to choose which components of the solution to deploy.
* `infrastructure/terraform/modules/`:
* * `activation/main.tf`: This Terraform file defines the Cloud Function that triggers the activation application.
* * `data-store/main.tf`: This Terraform file defines the parameters to deploy the Dataform code defined in the [repository](https://github.com/GoogleCloudPlatform/marketing-analytics-jumpstart-dataform)
* * `dataform-workflow/dataform-workflow.tf`: This Terraform file defines the parameters to deploy the Cloud Workflow that triggers the Dataform code. 
* * `feature-store/bigquery-*.tf`: This Terraform file defines the BigQuery datasets, tables, and stored procedures that are used to store and transform the features extracted from the marketing data store.
* * `monitor/main.tf`: This Terraform file defines the Cloud Logging Sink destination in BigQuery used by the Looker Studio Dashboard.
* * `pipelines/pipelines.tf`: This Terraform file defines the Vertex AI pipelines used for feature engineering, training, prediction, and explanation.
* `python/`:
* * `activation`: This python module implements the Dataflow/ Apache Beam pipeline that sends all predictions to Google Analytics 4 via Measurement Protocol API.
* * `base_component_image`: This python module implements the base component image used by the Vertex AI pipelines components, all libraries dependencies are installed in this docker image.
* * `function/trigger_activation`: This python module implements the Cloud Function that triggers the activation application.
* * `ga4_setup`: This python module implements the Google Analytics 4 Admin SDK that is used to setup the custom dimensions on the Google Analytics 4 property.
* * `lookerstudio`: This python module automated the copy and deployment of the Looker Studio Dashboard.
* * `pipelines`: This python module implements all the custom kubeflow pipelines components using the Google Cloud Pipeline Components library used by the Vertex AI pipelines. It also contains the pipeline definitions for the feature engineering, training, prediction, and explanation pipelines of all use cases.
* `sql/`:
* * `procedures/`: This folder contains the JINJA template files with the `.sqlx` extension used to generate the stored procedures deployed in BigQuery.
* * `queries/`: This folder contains the JINJA template files with the `.sqlx` extension used to generate the queries deployed in BigQuery.
* `templates/`:
* * `app_payload_template.jinja2`: This file defines the JINJA template used to generate the payload for the Measurement Protocol API used by the Activation Application.
* * `activation_query`: This folder contains the JINJA template files with the `.sqlx` extension used to generate the SQL queries for each use case used by the Activation Application to get all the predictions to be prepared and send to Google Analytics 4.

## Out-of-the-box configuration parameters provided by the solution

### Overall configuration parameters
The `config.yaml.tftpl` file is a YAML file that contains all the configuration parameters for the Marketing Analytics Jumpstart solution. A YAML file is a map or a list, and it follows a hierarchy depending on the indentation, and how you define your key values. Maps allow you to associate key-value pairs. This configuration file is organized in section blocks mappings.
| Key | Description |
| ---------- | ---------- |
| google_cloud_project | This section contains general configuration parameters for the GCP project |
| google_cloud_project | This section contains the Google Cloud project ID and project number |
| cloud_build | This section contains the configuration parameters for the Cloud Build pipeline |
| container | This section contains the configuration parameters for the container images |
| artifact_registry | This section contains the configuration parameters for the Artifact Registry repository |
| dataflow | This section contains the configuration parameters for the Dataflow pipeline |
| vertex_ai | This section contains the configuration parameters for the Vertex AI pipelines |
| bigquery | This section contains the configuration parameters for the BigQuery artifacts |

There are two sections mappings which are very important, `vertex_ai` and `bigquery`.
- `vertex_ai` section mapping: In the vertex_ai section, there pipelines blocks for each vertex AI pipeline implemented.
This `pipelines` section contains configuration parameters for the Vertex AI pipelines into subsections defined as: `feature-creation-auto-audience-segmentation`, `feature-creation-audience-segmentation`, `feature-creation-purchase-propensity`, `feature-creation-customer-ltv`, `propensity.training`, `propensity.prediction`, `segmentation.training`, `segmentation.prediction`, `auto_segmentation.training`, `auto_segmentation.prediction`, `propensity_clv.training`, `clv.training`, `clv.prediction`, `reporting_preparation`.
For those subsections described above, inside the execution section you have the `schedule` and `pipeline_parameters` blocks mappings. The `schedule` defines the schedule key-values of the pipeline. The `pipeline_parameters` defines the key-values that are going to be used to compile the pipeline.
Observe the key-values pairs inside the `pipeline_parameters` for each `vertex_ai.pipelines`, since most of the pipeline parameters are changed inside that section mapping.

The `bigquery` section contains configuration parameters for the BigQuery datasets, tables, queries and procedures into subsections defined as: `dataset`, `table`, `query`, `procedure`.
- `dataset`: Contains key-values pairs for all the configuration parameters of the datasets deployed in BigQuery, such as name, location and description.
- `table`: Contains key-values pairs for all the configuration parameters of the tables deployed in BigQuery, such as dataset it is part of, table_name and location.
- `query`: Contains key-values pairs for all the configuration parameters of the queries deployed in BigQuery, such as interval days and split numbers.
- `procedure`: Contains key-values pairs for all the configuration parameters of the procedures deployed in BigQuery, such as start and end dates.

### Modules configuration parameters
The `terraform.tfvars` file is a terraform variables definition file created during the installation process that lets you define custom Terraform variables that will overwrite the defaults. Here are few examples of changes you can make:
Change the `project_id` to store the Terraform Remote backend state; change the data staging `project_id`; change the data processing `project_id`; the `website_url` for the customer digital store; the feature store and activation `project_id`; the source GA4 and GAds export projects and datasets; and a few more variables.
The Terraform definition files for the modules `feature-store` and `pipelines` contains all the terraform resources and data that reads local files to deploy the SQL code to BigQuery. In the `bigquery-procedures.tf`, you can configure which stored procedures are being deployed, in which datasets, using which `local_file` code in which project. In the `bigquery-datasets.tf`, you can configure which datasets are being deployed, their names, locations and whether the contents of the dataset will be deleted when you ask to run a terraform destroy command. In the `bigquery-tables.tf`, you can configure which tables are being deployed, their names, their datasets and schema.

### Feature Store configuration parameters
The SQL files in the folder `sql/procedure/` and `sql/query/` contains `.sqlx` JINJA templates files containing SQL code that are hydrated from the configuration parameters defined in the `config.yaml` file, more specifically from the sections sql.query and sql.procedure.

## Activation Application configuration parameters
The files in the folder `templates/activation_query/` contains `.sqlx` JINJA template files containing BigQuery SQL code the retrieves the model predictions produced in the prediction tables for each use case. You can configure the columns and the filter conditions to send user-level prediction events only a subset of users.
