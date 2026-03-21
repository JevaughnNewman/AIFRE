{{ config(schema='SILVER_STAGING') }}

with source_data as (
    select * from {{ source('bronze_raw', 'AIFRE_LEDGER_RAW') }}
),

renamed as (
    select
        trim(upper(TXN_ID)) as transaction_id,
        trim(upper(APP_ID)) as app_id,
        
        -- Mapping the specific Snowflake headers
        TIMESTAMP as transaction_at, 
        cast(AMOUNT as decimal(18,2)) as amount,
        upper(trim(MERCHANT_CAT)) as merchant_category,
        
        -- Cleaning the MCC Code (removing any stray quotes from the CSV)
        trim(replace(MCC_CODE, '''', '')) as mcc_code,
        
        trim(upper(ENTRY_MODE)) as entry_mode,
        lower(trim(STATUS)) as status
    from source_data
),

ledger_flags as (
    select
        *,
        -- Risk Indicator: Round Number Invoices (Common in inflated claims)
        (amount > 500 and amount % 100 = 0) as is_suspicious_round_amount,
        
        -- Risk Indicator: Manual Entry (Higher risk of "Ghost" transactions)
        case when entry_mode = 'MANUAL_KEY_IN' then true else false end as is_manual_entry_risk,
        
        -- Risk Indicator: High-Risk Merchant Categories (e.g., Towing, Legal, Cash Advance)
        case 
            when mcc_code in ('7549', '8111', '6011') then true 
            else false 
        end as is_high_risk_mcc,
        
        -- Risk Indicator: Velocity (Is one claimant spending $10k+ in a single day?)
        sum(amount) over (partition by app_id, date_trunc('day', transaction_at)) > 10000 as is_daily_velocity_risk
    from renamed
)

select * from ledger_flags