{{ config(schema='SILVER_STAGING') }}

with source_data as (
    select * from {{ source('bronze_raw', 'AIFRE_IDENTITY_REGISTRY_RAW') }}
),

renamed as (
    select
        trim(upper(APP_ID)) as app_id,
        -- Splitting Full Name into First/Last
        trim(split_part(FULL_NAME, ' ', 1)) as first_name,
        trim(split_part(FULL_NAME, ' ', 2)) as last_name,
        
        trim(SIN) as sin_hash, -- Canadian context!
        trim(upper(ADDRESS)) as street_address,
        trim(upper(CITY)) as city,
        trim(upper(POSTAL_CODE)) as postal_code,
        AGE as age,
        trim(upper(OCCUPATION)) as occupation,
        
        -- Standardizing Phone
        regexp_replace(PHONE_NUMBER, '[^0-9]', '') as phone_clean,
        trim(upper(PHONE_TYPE)) as phone_type,
        
        trim(upper(KYC_STATUS)) as kyc_status,
        CREDIT_SCORE as credit_score
    from source_data
),

identity_flags as (
    select
        *,
        -- Risk Indicator: Multiple people using the same SIN
        count(*) over (partition by sin_hash) > 1 as is_duplicate_sin_risk,
        -- Risk Indicator: Multiple identities at the same address
        count(*) over (partition by street_address, postal_code) > 2 as is_high_occupancy_risk,
        -- Risk Indicator: Low Credit Score for high-value claims
        (credit_score < 500) as is_low_credit_risk
    from renamed
)

select * from identity_flags