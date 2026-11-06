-- Singular test: a one-off check. It FAILS if it returns any rows.
-- Revenue in the mart must match the raw source to the penny.
with raw_revenue as (
    select sum(fee_gbp - coalesce(refund_gbp, 0)) as total
    from {{ source('carmart', 'raw_deals') }}
),

mart_revenue as (
    select sum(net_revenue_gbp) as total
    from {{ ref('fct_deals') }}
)

select
    raw_revenue.total  as raw_total,
    mart_revenue.total as mart_total
from raw_revenue
cross join mart_revenue
where abs(raw_revenue.total - mart_revenue.total) > 0.01
