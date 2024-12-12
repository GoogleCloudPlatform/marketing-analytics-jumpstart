-- Copyright 2024 Google LLC
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

SELECT
  p_stat.inference_date,
  p_stat.p_p_decile,
  p_stat.number_of_users,
  conf.value*p_stat.number_of_users AS predicted_purchase_value
FROM (
  SELECT
    inference_date,
    p_p_decile,
    COUNT(p_p_decile) AS number_of_users
  FROM (
    SELECT
      PARSE_DATE('%Y_%m_%d', SUBSTR(_TABLE_SUFFIX, 1,10)) AS inference_date,
      NTILE(10) OVER (PARTITION BY _TABLE_SUFFIX ORDER BY b.prediction_prob DESC) AS p_p_decile,
    FROM
      `${project_id}.${purchase_propensity_dataset}.predictions_*` b
    WHERE
      ENDS_WITH(_TABLE_SUFFIX, '_view') )
  GROUP BY
    inference_date,
    p_p_decile ) AS p_stat
JOIN
  `${project_id}.${activation_dataset}.vbb_activation_configuration` conf
ON
  p_stat.p_p_decile = decile
WHERE
  conf.activation_type = 'purchase-propensity'