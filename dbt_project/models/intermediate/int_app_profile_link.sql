{{ config(schema='SILVER_WAREHOUSE', materialized='table') }}

with identity_base as (
    select 
        app_id, 
        first_name, 
        last_name, 
        sin_hash, 
        is_high_occupancy_risk 
    from {{ ref('stg_identity') }}
),

logs_base as (
    select 
        app_id, 
        count(*) as total_log_events,
        -- Corrected: Using 'is_proxy' from your stg_network_logs
        max(case when is_proxy then 1 else 0 end) as vpn_ever_used,
        -- Corrected: Using 'is_proxy' as the indicator for shared infrastructure
        max(case when is_proxy then 1 else 0 end) as shared_ip_detected
    from {{ ref('stg_network_logs') }}
    group by 1
),

ledger_base as (
    select 
        app_id, 
        sum(amount) as total_claimed_amount,
        -- Ensure this column exists in stg_ledger (should be from your Ledger script)
        max(case when amount > 2000 then 1 else 0 end) as has_round_invoice_risk
    from {{ ref('stg_ledger') }}
    group by 1
)

select
    coalesce(i.app_id, lo.app_id, le.app_id) as app_id,
    
    -- Identifying the Profile Integrity Status
    case 
        when i.app_id is null and le.app_id is not null then 'GHOST_CLAIM'
        when i.app_id is not null and le.app_id is null then 'INACTIVE_USER'
        when i.app_id is not null and le.app_id is not null then 'COMPLETE_PROFILE'
        else 'LOG_ONLY'
    end as profile_integrity_status,

    i.first_name,
    i.last_name,
    i.sin_hash,
    le.total_claimed_amount,
    lo.total_log_events,
    
    -- Consolidating Risk Flags
    (nvl(i.is_high_occupancy_risk, false) 
     or (nvl(lo.shared_ip_detected, 0) = 1) 
     or (nvl(le.has_round_invoice_risk, 0) = 1)) as is_any_risk_flagged
    
from identity_base i
full outer join logs_base lo on i.app_id = lo.app_id
full outer join ledger_base le on i.app_id = le.app_id