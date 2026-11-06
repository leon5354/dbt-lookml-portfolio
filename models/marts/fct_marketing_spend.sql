-- Grain: one row per channel per month. spend_id is the key LookML needs.
select
    channel || '-' || cast(spend_month as varchar) as spend_id,
    channel,
    spend_month,
    spend_gbp,
    leads
from {{ ref('stg_marketing_spend') }}
