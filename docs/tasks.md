# Changing a Parameter Values for Template Rendering

To alter a parameter value that affects template rendering, focus on modifying the configuration file:

1. Identify the Parameter:
* Determine the specific parameter you want to change.
* Note its name and the section of the configuration file where it resides.

2. Modify the Configuration File:

* Open the YAML configuration file in a text editor.
* Locate the key-value pair associated with the parameter you want to modify.
* Change the value to the desired new setting.
* Save the configuration file with the updated value.

3. Re-render Templates:

* Rerun the relevant function(s) that handle template rendering.
* The functions will read the updated configuration values and apply them to the templates, generating new output files with the modified parameter values.

4. Example:

Initial configuration (`config.yaml.tftpl`):

```yaml
bigquery:
  table:
    example_table:
      table_name: my_table
      dataset_name: my_dataset
```

To change the dataset_name:
Edit the configuration file:

```yaml
bigquery:
  table:
    example_table:
      table_name: my_table
      dataset_name: my_new_dataset  # Updated value
```

Rerun the rendering function:

```bash
inv apply_config_parameters_to_all_tables --env=prod
```

6. Key Points:

    * No code changes required: The function code already handles configuration updates.
    * Multiple environments: If using multiple configurations (e.g., dev, prod), modify the appropriate file.
    * Thorough testing: Re-render templates and test thoroughly to ensure changes have the desired effect.
    * Version control: Consider using version control to track configuration changes.


# Add a New Parameter into Your Template File

Here's a step-by-step guide to adding a new parameter to your template file:

1. Template File:

* Add the placeholder:
    * Insert the new parameter's placeholder within the template file, surrounded by Jinja2's delimiters (e.g., {{ new_parameter }}) where you want its value to appear in the rendered output.

2. Configuration File:

* Include the value:
    * Add a new key-value pair for the new parameter under the appropriate section of your YAML configuration file.
    * Ensure the key matches the placeholder name in the template.

3. Function Code:

* No code changes required:
    * The existing code already retrieves configuration values and renders them into templates, so it should handle the new parameter without modification.

4. Function Call (if applicable):

* Pass the parameter (optional):
    * If you're directly calling the function with a custom configuration dictionary, make sure to include the new parameter's key-value pair in the dictionary.

5. Example:

Template file (`example.sqlx`):

```sql
CREATE TABLE {{ table_name }} (
    id INT64,
    name STRING,
    {{ new_column_type }} {{ new_column_name }}
)
```

Configuration file (`config.yaml.tftpl`):

```yaml
bigquery:
  table:
    example_table:
      table_name: my_table
      new_column_type: STRING
      new_column_name: description
```

Function call (if applicable):

```bash
inv apply_config_parameters_to_all_tables --env=prod --custom-config=new_column_type:TIMESTAMP
```

6. Key Reminders:
    * Consistency: Double-check the placeholder names for consistency between the template and configuration files.
    * YAML Syntax: Ensure the configuration file has valid YAML syntax.
    * Thorough Testing: Test the changes thoroughly to verify that the new parameter renders correctly in the output files.