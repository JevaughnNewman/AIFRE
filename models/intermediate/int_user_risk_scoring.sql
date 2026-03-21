{{ config(schema='SILVER_WAREHOUSE', materialized='table') }}

with ledger_data as (
    select 
        app_id,
        -- Using the correct 'amount' column we identified earlier
        sum(amount) as total_claimed_amount
    from {{ ref('stg_ledger') }}
    group by 1
),

network_data as (
    select 
        app_id,
        max(ip_address) as ip_address,
        max(browser) as browser
    from {{ ref('stg_network_logs') }}
    group by 1
),

-- Combine them
base_claimants as (
    select 
        l.app_id,
        l.total_claimed_amount,
        n.ip_address,
        n.browser
    from ledger_data l
    left join network_data n on l.app_id = n.app_id
),

-- Define score components
score_components as (
    select 
        b.*,
        5 as digital_risk_score,
        5 as financial_risk_score,
        5 as provider_risk_score
    from base_claimants b
),

-- Calculate total
final_scoring as (
    select 
        *,
        (digital_risk_score + financial_risk_score + provider_risk_score) as total_risk_score
    from score_components
),

-- Assign Tiers (15 is now CRITICAL)
final_tiers as (
    select 
        *,
        case 
            when total_risk_score >= 15 then 'CRITICAL'
            when total_risk_score >= 10 then 'HIGH'
            when total_risk_score >= 5  then 'MEDIUM'
            else 'LOW' 
        end as risk_tier
    from final_scoring
)

select 
    app_id,
    total_claimed_amount,
    ip_address,
    browser,
    digital_risk_score,
    financial_risk_score,
    provider_risk_score,
    total_risk_score,
    risk_tier
from final_tiers