-- Grain: one row per deal.
-- Bids are rolled up BEFORE they meet deals, so fct_deals cannot fan out.
-- Ephemeral: dbt pastes this in as a CTE and builds no table.
select
    deal_id,
    count(*)        as bid_count,
    max(amount_gbp) as top_bid_gbp
from {{ ref('stg_bids') }}
group by deal_id
