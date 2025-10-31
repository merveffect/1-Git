select * from 
{{ source('prod_braze_currents', 'email_open') }}