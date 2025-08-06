SELECT 
* 
FROM {{ source('info_schema','COLUMNS') }}
