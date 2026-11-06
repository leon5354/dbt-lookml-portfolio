with source as (
    select * from {{ source('carmart', 'raw_bids') }}
),

cleaned as (
    select
        cast(bid_id as varchar)     as bid_id,
        cast(deal_id as varchar)    as deal_id,
        cast(dealer_id as varchar)  as dealer_id,
        cast(amount_gbp as double)  as amount_gbp,
        cast(bid_at as timestamp)   as bid_at
    from source
)

select * from cleaned
