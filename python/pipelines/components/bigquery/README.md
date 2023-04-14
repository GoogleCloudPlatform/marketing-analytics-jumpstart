# bq_stored_procedure_exec

## Component to run stored procedures in BigQuery

This component allows you to execute stored procedures in BigQuery.


## The component has the following parameters

### BigQuery Parameters

#### project (str)
The project id for the BigQuery client. (project that will execute the procedures)

#### location (str)
The location in which the BigQuery Job for the stored procedures will run

#### query (str)
This contains the stored procedures that the component will run. It is query writen in SQL BQ sytax.

#### query_parameters (list[dict])
Optiona list of query parameters. If the query has parameters, (i.e @my_date) then this paramter should be defined as a dictionary within the query_paramters list. The dictionary is a list item should should adhere to the following structure:
[{'name': 'my_date', 'type':'DATE', 'value': '2019-12-30'}]


#### timeout (float)
timeout for BQ job before retry
