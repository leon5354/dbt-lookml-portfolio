-- Fails if a join made fct_deals bigger or smaller than its source.
with counts as (
    select
        (select count(*) from {{ ref('stg_deals') }}) as source_rows,
        (select count(*) from {{ ref('fct_deals') }}) as mart_rows
)

select * from counts where source_rows != mart_rows
