{{ config(
    materialized='table',
    schema='GOLD_MARTS'
) }}

with all_activity as (
    -- 1. Capture transaction dates from Ledger
    select 
        app_id, 
        date_trunc('day', transaction_at) as event_date,
        amount as daily_amount
    from {{ ref('stg_ledger') }}
    
    union all -- Use union all for performance, then group by app_id/date
    
    -- 2. Capture login dates from Network Logs
    select 
        app_id, 
        date_trunc('day', event_timestamp) as event_date,
        0 as daily_amount
    from {{ ref('stg_network_logs') }}
),

risk_scores as (
    -- 3. Pulling from your Silver Layer source of truth
    select 
        app_id, 
        total_risk_score, 
        risk_tier,
        total_claimed_amount -- Ensure this exists in your int_user_risk_scoring
    from {{ ref('int_user_risk_scoring') }}
),

final_pulse as (
    select
        a.event_date,
        s.risk_tier,
        count(distinct a.app_id) as daily_active_claimants,
        round(avg(s.total_risk_score), 2) as avg_daily_risk_score,
        -- Corrected: Standardized tier check
        sum(case when s.risk_tier = 'CRITICAL' then 1 else 0 end) as critical_incident_count,
        -- New: Financial Impact
        sum(case when s.risk_tier = 'CRITICAL' then s.total_claimed_amount else 0 end) as critical_dollars_at_risk
    from all_activity a
    join risk_scores s on a.app_id = s.app_id 
    group by 1, 2
)

select * from final_pulse
where event_date is not null
order by event_date desc, risk_tier desc