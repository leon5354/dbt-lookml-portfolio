-- Staging: one model per source table. Rename, cast, clean. No joins.
with source as (
    select * from {{ source('carmart', 'raw_dealers') }}
),

cleaned as (
    select
        cast(dealer_id as varchar)    as dealer_id,
        trim(dealer_name)             as dealer_name,
        upper(trim(region))           as region,
        lower(trim(plan))             as plan,
        cast(updated_at as timestamp) as updated_at
    from source
)

select * from cleaned
