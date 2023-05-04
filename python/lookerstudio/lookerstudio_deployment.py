# Copyright 2023 Google LLC
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

# README
# Script loads the configuration from the config.ini and generates a clickable link using the Looker Studio Linking API.
# Linking API Reference: https://developers.google.com/looker-studio/integrate/linking-api

# This script assumes the default configuration of the views used by the Marketing Analytics Dashboard.
# You are required to update the config.ini file with your own project and datasets in the [COMMON] section.


import sys
from google.cloud import bigquery
from google.api_core.exceptions import Forbidden, NotFound, BadRequest
from google.auth.exceptions import GoogleAuthError
from configparser import ConfigParser, ExtendedInterpolation, Error as ConfigError

# Constants

CONFIG_FILE = "config.ini"
BASE_URL = "https://lookerstudio.google.com/reporting/create?"
REPORT_ID = "f61f65fe-4991-45fc-bcdc-80593966f28c"
REPORT_NAME = "Marketing%20Analytics%20Sample"

def parse_config(config_file:str) -> list:
    """ Parses config file and returns a list of dicts for the data sources. """
    try:
        # ExtendedInterpolation to parse ${} format in config file
        config = ConfigParser(interpolation=ExtendedInterpolation())
        
        # optionxform to preserve case
        config.optionxform = str
        config.read(config_file)
            
        sections = config.sections()
        sources = list()

        for section in sections:
            # Do not add COMMON section to collection of options
            if section == "COMMON":
                continue
            # Convert options for the section to dict
            options = dict(config.items(section))
            # Format section name for URL and add to options dict
            section = section.replace(' ','%20')
            options.update(dict(datasourceName=section))
            sources.append(options)
        return sources
    # Handle exception from ConfigParser and exit program with error
    except ConfigError as error:
        print(f'Error parsing file {CONFIG_FILE}.\n{error}')
        sys.exit(1)

def check_view_exists(resource_id:str) -> bool:
    """ Opens connection to BigQuery, \cCheck if view exists and account has access.
    
    Accepts a string Resource ID as a parameter. Expects Resource ID to be formatted. `ProjectId.DatasetId.TableId`
    
    Returns True if view exists and is accessible. """

    view_exists = True

    try:
        bq_client.get_table(resource_id)
    # Catch exception if path to view does not exist and sets view_exists to false for further processing.
    except NotFound:
        print(f"ERROR: `{resource_id}` not found. Ensure the path is correct and the view has been created.")
        view_exists = False
    # Catch exception if path to view exists but user does not have access and sets view_exists to false for further processing.
    except Forbidden:
        print(f"ERROR: Access denied on `{resource_id}`. Ensure your account has access.")
        view_exists = False
    except BadRequest:
        print(f"ERROR: Project in `{resource_id}` does not exist.")
        view_exists = False

    return view_exists


def add_data_source(data_source: dict) -> str:
    """ Formats data source dictionary as URL and returns formatted URL.
    
    Expects a dict parameter for data sources. """
    resultUrl = str()
    
    # Get data source alias from first dict item
    ds_alias = data_source["ds_alias"]

    # Construct url from data_source and append
    for key,value in data_source.items():
        # Exclude ds_alias from key/value URL generation
        if key != "ds_alias":
            resultUrl += f"&ds.{ds_alias}.{key}={value}"
    
    return resultUrl

def main():
    views_exist = True
    report_url = BASE_URL + 'c.reportId=' + REPORT_ID + '&c.explain=true' + '&r.reportName=' + REPORT_NAME
    # Get sources from config file
    sources = parse_config(CONFIG_FILE)
    
    for source in sources:
        # Get fully qualified view Resource ID and check it exists
        view_id = f"{source['projectId']}.{source['datasetId']}.{source['tableId']}"

        # If view doesn't exist, skip constructing URL and check next view
        if not check_view_exists(view_id):
            views_exist = False
            continue
        
        # Check views_exist, if one does not then don't bother generating urls for remaining sources
        # But continue through loop to continue checking if they are accessible
        if views_exist:
            # View exists so construct url and append to main report_url
            report_url += add_data_source(source)
            
    # If all views do not exist and are not accessible, print error and exit main()
    if not views_exist:
        print('\nAn error ocurred. See error(s) above and try again.')
        sys.exit(1)

    print('Click link to copy report to your account and finish configuring data sources:\n')

    print(report_url)

# Guard check to ensure main is entry point
if __name__ == '__main__':
    try:
        bq_client = None
        
        #Establish BQ connection and run main()
        bq_client = bigquery.Client()
        main()
    # Catch exception for missing project and exit
    except EnvironmentError:
        print('Project not defined. Set your project using command: \n\tgcloud config set project.')
        sys.exit(1)
    # Catch auth error, print message and exit if connection fails
    except GoogleAuthError as error:
        print(f"ERROR: {error}")
        sys.exit(1)
    finally:
        # Regardless of outcome, close BQ connection to clean up if it exists
        if bq_client is not None:
            bq_client.close()