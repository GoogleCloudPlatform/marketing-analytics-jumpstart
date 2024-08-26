# Copyright 2022 Google LLC
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

terraform {
  required_version = ">=1.3.7"

  # Check the latest version at https://registry.terraform.io/providers/hashicorp/google
  # Observe the changelogs at https://github.com/hashicorp/terraform-provider-google/blob/main/CHANGELOG.md
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.43.0, >= 3.53.0, >= 3.63.0, >= 4.83.0, < 5.0.0, < 6.0.0"
    }
  }

  provider_meta "google" {
    module_name = "cloud-solutions/marketing-analytics-jumpstart-dataform-deploy-v1.0" #x-release-please-minor
  }
}
