-- Grain: one row per dealer, current state. History is in dealers_snapshot.
select
    dealer_id,
    dealer_name,
    region,
    plan
from {{ ref('stg_dealers') }}
