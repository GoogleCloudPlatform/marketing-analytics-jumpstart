"MDS GA4 Dataset","mds","${mds_dataset_url_base}marketing_ga4_base_${mds_dataset_suffix}",1
"MDS Ads Dataset","mds","${mds_dataset_url_base}marketing_ads_base_${mds_dataset_suffix}",2
"MDS Dependency Graph","mds","${dataform_graph_url}",3
"Feature Store Dataset","analysis","${feature_store_dataset_url_base}feature_store",1
"Vertex AI Pipelines","analysis","${vertex_pipelines_url}",2
"Model Registry","analysis","${vertex_models_url}",3
"Auto Audience Segmentation Prediction","activation","${feature_store_dataset_url_base}auto_audience_segmentation",1
"Audience Segmentation Prediction","activation","${feature_store_dataset_url_base}audience_segmentation",2
"Purchase Propensity Prediction","activation","${feature_store_dataset_url_base}purchase_propensity",3
"CLTV Prediction","activation","${feature_store_dataset_url_base}customer_lifetime_value",4
"Aggregated VBB","activation","${mds_table_url_base}aggregated_vbb",5
"Activation Dataset","activation","${activation_dataset_url_base}activation",6
"MDS Workflow Executions","jobrun","${dataform_workflows_url}",1
"Feature Store & Pipeline Executions","jobrun","${vertex_pipelines_runs_url}",2
"Activation Pipeline Executions","jobrun","${activation_pipelines_runs_url}",3