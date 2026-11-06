-- Grain: one row per sold car. Row-level logic lives here.
-- No totals or ratios: those are LookML measures, so they work at any grouping.
with deals as (
    select * from {{ ref('stg_deals') }}
),

bid_stats as (
    select * from {{ ref('int_bid_stats') }}
),

final as (
    select
        deals.deal_id,
        deals.dealer_id,
        deals.car,
        deals.region,
        deals.sold_at,
        deals.final_price_gbp,
        deals.fee_gbp - coalesce(deals.refund_gbp, 0) as net_revenue_gbp,
        deals.finance_provider is not null            as is_finance,
        coalesce(bid_stats.bid_count, 0)              as bid_count,
        bid_stats.top_bid_gbp
    from deals
    left join bid_stats
        on deals.deal_id = bid_stats.deal_id
)

select * from final
