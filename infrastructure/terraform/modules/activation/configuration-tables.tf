# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  config_id = "vbb_activation_configuration"
  vbb_activation_configuration_file = "${local.config_id}.jsonl"
}

# JSON configuration file for smart bidding based activation
resource "google_storage_bucket_object" "vbb_activation_configuration_file" {
  name   = "${local.configuration_folder}/${local.vbb_activation_configuration_file}"
  source = "${local.template_dir}/${local.vbb_activation_configuration_file}"
  bucket = module.pipeline_bucket.name
}

# This data resources creates a data resource that renders a template file and stores the rendered content in a variable.
data "template_file" "load_vbb_activation_configuration_proc" {
  template = file("${local.template_dir}/load_${local.config_id}.sql.tpl")
  vars = {
    project_id      = module.project_services.project_id
    dataset         = module.bigquery.bigquery_dataset.dataset_id
    config_file_uri = "gs://${module.pipeline_bucket.name}/${google_storage_bucket_object.vbb_activation_configuration_file.output_name}"
  }
}

# Store procedure that loads the json configuation file from GCS into a configuration table in BQ
resource "google_bigquery_routine" "load_vbb_activation_configuration_proc" {
  project         = module.project_services.project_id
  dataset_id      = module.bigquery.bigquery_dataset.dataset_id
  routine_id      = "load_${local.config_id}"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.load_vbb_activation_configuration_proc.rendered
  description     = "Procedure for loading vbb activation configuration from GCS bucket"
}

# This resource creates a BigQuery table named vbb_activation_configuration
resource "google_bigquery_table" "smart_bidding_configuration" {
  project     = module.project_services.project_id
  dataset_id  = module.bigquery.bigquery_dataset.dataset_id
  table_id    = local.config_id
  description = "stores configuration settings used to translate predicted deciles into monetary values for Smart Bidding strategies."

  # The deletion_protection attribute specifies whether the table should be protected from deletion. In this case, it's set to false, which means that the table can be deleted.
  deletion_protection = false
  labels = {
    version = "prod"
  }

  # The schema attribute specifies the schema of the table. In this case, the schema is defined in the JSON file.
  schema = file("${local.source_root_dir}/sql/schema/table/${local.config_id}.json")

  # The lifecycle block is used to configure the lifecycle of the table. In this case, the ignore_changes attribute is set to all, which means that Terraform will ignore
  # any changes to the table and will not attempt to update the table.
  lifecycle {
    ignore_changes  = all
  }
}
