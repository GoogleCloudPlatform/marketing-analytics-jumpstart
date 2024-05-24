# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from typing import Optional
from kfp.dsl import component, Output, Model
import os
import yaml

config_file_path = os.path.join(os.path.dirname(
    __file__), '../../../../config/config.yaml')

base_image = None
if os.path.exists(config_file_path):
    with open(config_file_path, encoding='utf-8') as fh:
        configs = yaml.full_load(fh)

    vertex_components_params = configs['vertex_ai']['components']
    repo_params = configs['artifact_registry']['pipelines_docker_repo']

    # defines the base_image variable, which specifies the Docker image to be used for the component. This image is retrieved from the config.yaml file, which contains configuration parameters for the project.
    base_image = f"{repo_params['region']}-docker.pkg.dev/{repo_params['project_id']}/{repo_params['name']}/{vertex_components_params['base_image_name']}:{vertex_components_params['base_image_tag']}"


@component(base_image=base_image)
def train_scikit_cluster_model(
    project_id: str,
    dataset: str,
    location: str,
    training_table: str,
    cluster_model: Output[Model],
    bucket_name: str,
    model_name: str,
    p_wiggle: int = 10,
    min_num_clusters: int = 3,
    columns_to_skip: int = 3,
    timeout: Optional[float] = 1800
) -> None:
    """
    This component trains a scikit-learn cluster model using the KMeans algorithm. It provides a reusable and configurable way 
    to train a scikit-learn cluster model using KFP.

    The component trainng logic is described in the following steps:
        Constructs a BigQuery client object using the provided project ID.
        Reads the training data from the specified BigQuery table.
        Defines a function _create_model to create a scikit-learn pipeline with a KMeans clustering model.
        Defines an objective function _objective for hyperparameter optimization using Optuna. 
            This function trains the model with different hyperparameter values and evaluates its performance using the silhouette score.
        Creates an Optuna study and optimizes the objective function to find the best hyperparameters.
        Trains the final model with the chosen hyperparameters.
        Saves the trained model as a pickle file.
        Creates a GCS bucket if it doesn't exist.
        Uploads the pickled model to the GCS bucket.

    Args:
        project_id: The Google Cloud project ID.
        dataset: The BigQuery dataset name.
        location: The Google Cloud region where the BigQuery dataset is located.
        training_table: The BigQuery table name containing the training data.
        cluster_model: The output model artifact.
        bucket_name: The Google Cloud Storage bucket name to upload the trained model.
        model_name: The name of the model to be saved in the bucket.
        p_wiggle: The percentage wiggle allowed for the best score.
        min_num_clusters: The minimum number of clusters to consider.
        columns_to_skip: The number of columns to skip from the beginning of the dataset.
        timeout: The maximum time in seconds to wait for the training job to complete.

    Returns:
        None
    """

    import numpy as np
    import pandas as pd
    import sklearn
    print('The scikit-learn version is {}.'.format(sklearn.__version__))

    import optuna
    optuna.logging.set_verbosity(optuna.logging.WARNING)

    from sklearn.pipeline import Pipeline
    from sklearn.cluster import KMeans, MiniBatchKMeans
    from sklearn.compose import ColumnTransformer
    from sklearn.preprocessing import FunctionTransformer
    from sklearn.feature_extraction.text import TfidfTransformer
    from sklearn.metrics import silhouette_samples, silhouette_score
    
    import logging
    from google.cloud import bigquery

    # Construct a BigQuery client object.
    client = bigquery.Client(
        project=project_id,
        #location=location
    )

    training_dataset_df = client.query(
        query=f"""SELECT * FROM `{project_id}.{dataset}.{training_table}`"""
        ).to_dataframe()

    # Skipping the first three columns: [user_pseudo_id, user_id, feature_timestamp]
    columns_to_skip 
    features = list(training_dataset_df.columns[columns_to_skip:])
    min_num_clusters = 3
    max_num_clusters = len(features)

    def _create_model(params):
        model = Pipeline([
            ('transform', ColumnTransformer(
                transformers=[
                    ('tfidf',
                    TfidfTransformer(norm='l2'),
                    list(range(columns_to_skip, len(features) + columns_to_skip))  # Skipping the first three columns: [user_pseudo_id, user_id, feature_timestamp]
                    )
                ]
            )),
            ('model', KMeans(
                init='k-means++', n_init='auto',
                random_state=42,
                **params)
            )
        ])

        return model

    def _objective(trial):
        params = {
        "n_clusters": trial.suggest_int("n_clusters", min_num_clusters, max_num_clusters),
        "max_iter": trial.suggest_int("max_iter", 10, 1000, step=10),
        "tol": trial.suggest_float("tol", 1e-6, 1e-2, step=1e-6),
        }

        model = _create_model(params)
        model.fit(training_dataset_df)
        labels = model.predict(training_dataset_df)

        return silhouette_score(
            model.named_steps['transform'].transform(training_dataset_df),
            labels, metric='euclidean',
            sample_size=int(len(training_dataset_df) * 0.1) if int(len(training_dataset_df) * 0.1) < 10_000 else 10_000,
            random_state=42
        ), params['n_clusters']
    
    study = optuna.create_study(
        directions=["maximize", "minimize"],
        sampler=optuna.samplers.TPESampler(seed=42, n_startup_trials=25)
    )
    study.optimize(_objective,
                n_trials=125,
                show_progress_bar=True,
                n_jobs=-1
    )

    best_trials = sorted([(t.number, t.values[0], t.values[1], t.params) for t in study.best_trials], key=lambda x: x[1], reverse=True)
    best_score = best_trials[0][1]
    best_trials = sorted([(t.number, t.values[0], t.values[1], t.params) for t in study.best_trials], key=lambda x: (x[2], x[1]))
    trial_chosen = None
    for t in best_trials:
        if (1 - t[1]/best_score) <= p_wiggle/100:
            print (f'TRIAL {t[0]}:')
            print (f" Num. clusters: {int(t[2])}")
            print (f" Best score: {round(best_score, 4)} / Chosen trial Score: {round(t[1], 4)}")
            print (f" % worse than best: {100 * round((1 - t[1]/best_score), 4)}%")
            print (f" Params: {t[3]}")

            trial_chosen = t
            break

    model = _create_model(trial_chosen[3])
    model.fit(training_dataset_df)
    labels = model.predict(training_dataset_df)

    import pickle
    with open('model.pkl', 'wb') as f:
        pickle.dump(model, f)
    
    # Create a GCS bucket to upload the pickled model using google.cloud.storage library
    def _create_gcs_bucket(bucket_name):
        """Creates a Google Cloud Storage bucket."""
        from google.cloud import storage
        storage_client = storage.Client()
        bucket = storage_client.lookup_bucket(bucket_name)
        if bucket is None:
            bucket = storage_client.create_bucket(bucket_name)
            print(f"Bucket {bucket.name} created.")
        else:
            print(f"Bucket {bucket.name} already exists.")

        return bucket

    # Create a GCS bucket to upload the pickled model
    _create_gcs_bucket(bucket_name)

    # Upload model to GCS bucket to be later deployed on Vertex AI Model Registry in Python
    def _upload_to_gcs(bucket_name, model_filename, destination_blob_name=""):
        """Uploads a file to a Google Cloud Storage bucket."""
        from google.cloud import storage

        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(destination_blob_name)

        blob.upload_from_filename(model_filename)

        print(f"Model uploaded to gs://{bucket_name}/{destination_blob_name}")

    model_filename = 'model.pkl'
    destination_blob_name = f"{model_name}/model.pkl" # Path within the bucket

    # Upload the model to GCS
    _upload_to_gcs(bucket_name, model_filename, destination_blob_name)
    


