{{ config(
    schema='GOLD_MARTS',
    materialized='table',
    description='Final granular claimant risk scores for Tableau reporting'
) }}

with final_scoring as (
    select * from {{ ref('int_user_risk_scoring') }}
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
    risk_tier,
    -- Adding a simple flag to make Tableau filtering easier
    case when browser = 'Python-Requests' then 1 else 0 end as is_bot_tool
from final_scoring