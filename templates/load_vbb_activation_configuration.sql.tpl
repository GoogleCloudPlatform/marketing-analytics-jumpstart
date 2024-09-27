-- Copyright 2023 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Step 1: Load JSON data from GCS into the temporary table
LOAD DATA OVERWRITE `${project_id}.${dataset}.temp_json_data`
FROM FILES (
  format = 'JSON',
  uris = ['${config_file_uri}']
);

-- Step 2: Transform and load into the final table
CREATE OR REPLACE TABLE `${project_id}.${dataset}.vbb_activation_configuration` AS
  SELECT
    t.activation_type AS activation_type, 
    dm.decile,
    (t.value_norm * dm.multiplier) AS value
  FROM
    `${project_id}.${dataset}.temp_json_data` AS t,
    UNNEST(t.decile_multiplier) AS dm;

-- Step 3: Clean up temporary tables
DROP TABLE `${project_id}.${dataset}.temp_json_data`;
