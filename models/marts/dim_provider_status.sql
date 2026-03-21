{{ config(schema='GOLD_MARTS', materialized='table') }}

-- 1. Start with WITH (only once!)
with merchant_base as (
    select 
        merchant_category as provider_name,
        mcc_code,
        count(distinct app_id) as total_claimants_served
    from {{ ref('stg_ledger') }}
    group by 1, 2
), -- <--- THIS COMMA IS CRITICAL

-- 2. Do NOT use "WITH" again here
provider_risk_metrics as (
    select 
        ldb.merchant_category as provider_name,
        ldb.mcc_code,
        count(distinct case when r.risk_tier in ('HIGH', 'CRITICAL') then r.app_id end) as high_risk_claimant_count,
        sum(case when r.risk_tier in ('HIGH', 'CRITICAL') then r.total_claimed_amount else 0 end) as total_exposure_dollars,
        avg(r.total_risk_score) as avg_provider_risk_score
    from {{ ref('stg_ledger') }} ldb
    left join {{ ref('int_user_risk_scoring') }} r on ldb.app_id = r.app_id
    group by 1, 2
)

-- 3. Final Select
select
    md5(mb.provider_name || mb.mcc_code) as provider_key,
    mb.provider_name,
    mb.mcc_code,
    mb.total_claimants_served,
    nvl(prm.high_risk_claimant_count, 0) as high_risk_claimant_count,
    nvl(prm.total_exposure_dollars, 0) as total_exposure_dollars,
    round(nvl(prm.avg_provider_risk_score, 0), 2) as provider_risk_index,
    
    case 
        when prm.total_exposure_dollars > 500000 or prm.high_risk_claimant_count > 15 then 'CRITICAL_WATCHLIST'
        when prm.total_exposure_dollars > 100000 or prm.high_risk_claimant_count > 5 then 'UNDER_INVESTIGATION'
        else 'ACTIVE'
    end as provider_status,

    current_timestamp() as last_audit_timestamp

from merchant_base mb
left join provider_risk_metrics prm 
    on mb.provider_name = prm.provider_name 
    and mb.mcc_code = prm.mcc_code