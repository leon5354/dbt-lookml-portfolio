with source as (
    select * from {{ source('carmart', 'raw_deals') }}
),

cleaned as (
    select
        cast(deal_id as varchar)           as deal_id,
        cast(dealer_id as varchar)         as dealer_id,
        trim(car)                          as car,
        upper(trim(seller_region))         as region,
        cast(final_price_gbp as double)    as final_price_gbp,
        cast(fee_gbp as double)            as fee_gbp,
        cast(refund_gbp as double)         as refund_gbp,
        cast(finance_provider as varchar)  as finance_provider,
        cast(sold_at as timestamp)         as sold_at
    from source
)

select * from cleaned
