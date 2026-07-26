select * from 
{{ source('prod_cdi_presentation', 'segment_known_users_with_email') }}