{{ config(schema='SILVER_WAREHOUSE', materialized='table') }}

with identity_base as (
    -- Ensure this points to your successful staging model
    select * from {{ ref('stg_identity') }}
),

address_groups as (
    select
        street_address,
        postal_code,
        -- Swapping USER_ID for APP_ID
        count(distinct app_id) as claimant_count,
        array_agg(distinct app_id) as clustered_app_ids,
        -- Flagging if multiple surnames are at the same address
        count(distinct last_name) > 1 as is_multi_family_cluster
    from identity_base
    group by 1, 2
)

select 
    i.*,
    ag.claimant_count,
    ag.is_multi_family_cluster,
    -- If more than 2 unique apps come from one address, it's a "Fraud House" risk
    case when ag.claimant_count > 2 then true else false end as is_address_risk
from identity_base i
left join address_groups ag 
    on i.street_address = ag.street_address 
    and i.postal_code = ag.postal_code