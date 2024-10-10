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
  vbb_activation_configuration_file = "vbb_activation_configuration.jsonl"
}

# JSON configuration file for smart bidding based activation
resource "google_storage_bucket_object" "vbb_activation_configuration_file" {
  name   = "${local.configuration_folder}/${local.vbb_activation_configuration_file}"
  source = "${local.template_dir}/${local.vbb_activation_configuration_file}"
  bucket = module.pipeline_bucket.name
}

# This data resources creates a data resource that renders a template file and stores the rendered content in a variable.
data "template_file" "load_vbb_activation_configuration_proc" {
  template = file("${local.template_dir}/load_vbb_activation_configuration.sql.tpl")
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
  routine_id      = "load_vbb_activation_configuration"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = data.template_file.load_vbb_activation_configuration_proc.rendered
  description     = "Procedure for loading vbb activation configuration from GCS bucket"
}
