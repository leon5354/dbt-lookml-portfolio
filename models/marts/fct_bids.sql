-- Grain: one row per bid. Incremental: the first run loads everything, later
-- runs only reprocess the last 3 days, which catches late-arriving bids.
{{ config(
    materialized='incremental',
    unique_key='bid_id',
    incremental_strategy=('merge' if target.type == 'bigquery' else 'delete+insert'),
    on_schema_change='fail',
    partition_by=({'field': 'bid_at', 'data_type': 'timestamp', 'granularity': 'day'} if target.type == 'bigquery' else none),
    cluster_by=(['deal_id'] if target.type == 'bigquery' else none)
) }}

select
    bid_id,
    deal_id,
    dealer_id,
    amount_gbp,
    bid_at
from {{ ref('stg_bids') }}

{% if is_incremental() %}
where bid_at >= {{ dbt.dateadd('day', -3, '(select max(bid_at) from ' ~ this ~ ')') }}
{% endif %}
