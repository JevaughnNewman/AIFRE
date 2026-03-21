{{ config(materialized='view') }}

WITH source_data AS (
    SELECT * FROM {{ source('bronze_raw', 'AIFRE_LOGS_RAW') }}
),

flattened AS (
    SELECT
        -- Using $1 handles cases where Snowflake doesn't name the JSON column
        PARSE_JSON($1) AS log_json,
        log_json:session_id::STRING AS session_id,
        log_json:app_id::STRING AS app_id,
        log_json:device_id::STRING AS device_id,
        log_json:ip_address::STRING AS ip_address,
        log_json:browser::STRING AS browser,
        log_json:proxy_detected::BOOLEAN AS is_proxy,
        log_json:seconds_on_page::FLOAT AS seconds_on_page,
        log_json:event_time::STRING AS raw_event_time,
        log_json:request_path::STRING AS request_path,
        log_json:response_code::INT AS response_code
    FROM source_data
),

final_cleaning AS (
    SELECT
        *,
        -- Handle the mixed ISO/Unix timestamps
        TRY_TO_TIMESTAMP_NTZ(raw_event_time) AS event_timestamp
    FROM flattened
)

SELECT * FROM final_cleaning