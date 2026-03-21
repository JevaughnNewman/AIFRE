{{ config(schema='SILVER_WAREHOUSE', materialized='table') }}

with ledger as (
    select * from {{ ref('stg_ledger') }}
),

merchant_stats as (
    select
        merchant_category,
        mcc_code,
        -- How much does this merchant type usually bill?
        avg(amount) as avg_txn_value,
        -- Count how many "Suspiciously Round" invoices they've issued
        sum(case when is_suspicious_round_amount then 1 else 0 end) as round_txn_count,
        count(*) as total_txns
    from ledger
    group by 1, 2
)

select 
    l.*,
    ms.avg_txn_value,
    -- The "Collusion Ratio": What % of their bills are suspiciously round?
    (cast(ms.round_txn_count as float) / nullif(ms.total_txns, 0)) as merchant_round_ratio,
    -- A high ratio (e.g. > 30%) for high-volume merchants is a major SIU flag
    case 
        when (ms.round_txn_count / nullif(ms.total_txns, 0)) > 0.25 and ms.total_txns > 5 
        then true 
        else false 
    end as is_merchant_collusion_risk
from ledger l
join merchant_stats ms 
    on l.mcc_code = ms.mcc_code 
    and l.merchant_category = ms.merchant_category