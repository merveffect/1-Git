select * from 
{{ source('prod_braze_currents', 'email_soft_bounce') }}

