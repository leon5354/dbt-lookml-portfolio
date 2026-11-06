{#
  By default dbt names schemas <target>_<custom>, such as main_marts.
  This override uses the custom name as it is, so we get plain "marts".
  A macro is reusable Jinja. dbt calls this one for every model.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ custom_schema_name | trim if custom_schema_name else target.schema }}
{%- endmacro %}
