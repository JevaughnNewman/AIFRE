{% snapshot snsh_identity %}

{{
    config(
      target_schema='snapshots',
      unique_key='user_id',
      strategy='check',
      check_cols=['address', 'city', 'email'],
    )
}}

select * from {{ ref('stg_identity') }}

{% endsnapshot %}