{{ config(schema='GOLD_MARTS', materialized='table') }}

with claimant_data as (
    -- Pull the dollars and browser info from our Silver scoring model
    select 
        app_id,
        total_claimed_amount,
        browser,
        ip_address
    from {{ ref('int_user_risk_scoring') }}
),

network_events as (
    -- Get the date of the claim
    select 
        app_id,
        cast(EVENT_TIMESTAMP as date) as activity_date
    from {{ ref('stg_network_logs') }}
    group by 1, 2 -- Ensures we don't double-count dollars if an app has multiple log entries
),

daily_metrics as (
    select 
        n.activity_date,
        count(distinct c.app_id) as total_claims_filed,
        count(distinct c.ip_address) as unique_ip_count,
        sum(c.total_claimed_amount) as daily_exposure_dollars,
        -- Tracking the specific 'Python-Requests' bot threat
        count(case when c.browser = 'Python-Requests' then 1 end) as bot_tool_claims
    from network_events n
    join claimant_data c on n.app_id = c.app_id
    group by 1
)

select 
    activity_date,
    total_claims_filed,
    unique_ip_count,
    bot_tool_claims,
    round(daily_exposure_dollars, 2) as daily_exposure,
    -- Velocity: Ratio of claims to unique IP addresses
    round((total_claims_filed * 1.0) / nullif(unique_ip_count, 0), 2) as velocity_score,
    -- Enhanced Threat Level logic for the Board of Directors
    case 
        when bot_tool_claims > 50 or (total_claims_filed * 1.0 / nullif(unique_ip_count, 0)) > 2.0 
            then 'CRITICAL_BOT_ATTACK'
        when (total_claims_filed * 1.0 / nullif(unique_ip_count, 0)) > 1.2 
            then 'ELEVATED_ACTIVITY'
        else 'STABLE'
    end as threat_level,
    current_timestamp() as processed_at
from daily_metrics
where activity_date is not null
order by activity_date desc