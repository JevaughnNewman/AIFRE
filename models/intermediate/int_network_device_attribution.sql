{{ config(schema='SILVER_WAREHOUSE', materialized='table') }}

with log_base as (
    select 
        app_id, 
        ip_address,
        browser, -- Match: stg_network_logs
        event_timestamp, -- Match: stg_network_logs
        is_proxy, -- Match: stg_network_logs
        -- Using seconds_on_page to determine bot-like behavior
        case when seconds_on_page < 5 then true else false end as is_bot_detected
    from {{ ref('stg_network_logs') }}
),

device_velocity as (
    select
        ip_address,
        browser, -- Replaced 'user_agent'
        -- Identifying how many distinct people are behind this device
        count(distinct app_id) as unique_claimants_on_device,
        count(*) as total_hits,
        max(case when is_proxy then 1 else 0 end) as vpn_flag,
        max(case when is_bot_detected then 1 else 0 end) as bot_flag
    from log_base
    group by 1, 2
),

time_window_velocity as (
    select 
        ip_address,
        count(distinct app_id) as apps_in_last_24h
    from log_base
    -- Focusing on high-frequency "Burst" attacks
    where event_timestamp >= dateadd(day, -1, current_timestamp())
    group by 1
)

select 
    dv.*,
    tw.apps_in_last_24h,
    -- Velocity Risk: 4+ unique apps from 1 IP in a day is a "Mule" indicator
    case 
        when tw.apps_in_last_24h > 3 then true 
        else false 
    end as is_velocity_risk,
    -- Device Mill Risk: 6+ unique apps on the exact same browser/OS
    case 
        when dv.unique_claimants_on_device > 5 then true 
        else false 
    end as is_device_mill_risk
from device_velocity dv
left join time_window_velocity tw on dv.ip_address = tw.ip_address