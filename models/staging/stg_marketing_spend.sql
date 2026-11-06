select
    lower(trim(channel))          as channel,
    cast(spend_month as date)     as spend_month,
    cast(spend_gbp as double)     as spend_gbp,
    cast(leads as bigint)         as leads
from {{ source('carmart', 'raw_marketing_spend') }}
