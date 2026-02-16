SELECT *, 'dict' as version FROM {{source('hex_final_tables', 'b2b_naming_conventions_dict')}}
UNION ALL
SELECT *, 'v2' as version FROM {{source('hex_final_tables', 'b2b_naming_conventions_dict_v2')}}