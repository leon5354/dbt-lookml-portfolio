{#
  Custom generic test: reusable from any YAML file.
  Every dbt test is a query that must return ZERO rows to pass.
#}
{% test positive_value(model, column_name) %}
select {{ column_name }}
from {{ model }}
where {{ column_name }} <= 0
{% endtest %}
