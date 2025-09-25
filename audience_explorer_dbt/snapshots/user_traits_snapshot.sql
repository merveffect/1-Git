{% snapshot user_traits_snapshot %}


{{

config(
  target_schema= 'snapshots',
  unique_key= 'canonical_segment_id',
  strategy= 'timestamp',
  updated_at= 'loaded_at'
)
}}



select 
 
distinct name as column_names,
loaded_at,
value, 
received_at

 from {{ source('cdp_profile_sync', 'user_traits') }}

{% endsnapshot %}

