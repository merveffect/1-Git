{% macro generic_email_domains() %}

{{ return([

'gmail.com','googlemail.com','outlook.com','hotmail.com','hotmail.co.uk',

'yahoo.com','yahoo.co.uk','ymail.com','live.com','msn.com','aol.com',

'icloud.com','me.com','mac.com','gmx.com','gmx.de','gmx.net','web.de',

't-online.de','protonmail.com','proton.me','pm.me','qq.com','163.com',

'126.com','sina.com','foxmail.com','yandex.ru','mail.ru','zoho.com'

]) }}

{% endmacro %}



{% macro is_generic_domain(domain_column) %}

{{ domain_column }} in (

{%- for d in generic_email_domains() -%}

'{{ d }}'{{ ',' if not loop.last }}

{%- endfor -%}

)

{% endmacro %}