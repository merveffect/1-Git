{{
config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
        'field': 'execution_date', 
        'data_type': 'date', 
    }
)
}}


Select
lower(CONCAT(canvas_name,'_', canvas_variation_name,'_',canvas_step_name)) AS utm_campaign,
lower(canvas_name) as canvas_name,
lower(canvas_step_name) as canvas_step_name,
lower(canvas_variation_name) as canvas_variation_name,
date as execution_date,
sum(email_sent) as email_sent,
sum(email_delivered) as email_delivered,
sum(email_bounced) as email_bounced,
sum(email_opened) as email_opened,
sum(email_soft_bounced) as email_soft_bounced,
sum(unsubscribed) as email_unsubscribed,
sum(email_click) as email_click

 from

(

SELECT
  COALESCE(t1.canvas_name, t2.canvas_name, t3.canvas_name,t4.canvas_name,t5.canvas_name,t6.canvas_name,t7.canvas_name) AS canvas_name,
  COALESCE(t1.canvas_step_name, t2.canvas_step_name, t3.canvas_step_name,t4.canvas_step_name,t5.canvas_step_name,t6.canvas_step_name,t7.canvas_step_name) AS canvas_step_name,
  COALESCE(t1.canvas_variation_name, t2.canvas_variation_name, t3.canvas_variation_name,t4.canvas_variation_name,t5.canvas_variation_name,t6.canvas_variation_name,t7.canvas_variation_name) AS canvas_variation_name,
  COALESCE(t1.date, t2.date, t3.date,t4.date,t5.date,t6.date,t7.date) AS date,
  t1.email_sent,
  t2.email_delivered,
  t3.email_bounced,
  t4.email_opened,
  t5.email_soft_bounced,
  t6.unsubscribed,
  t7.email_click
FROM
  {{ ref('stg_email_sent') }} t1
FULL OUTER JOIN
  {{ ref('stg_email_delivered') }} t2
ON
  t1.canvas_name = t2.canvas_name AND t1.canvas_step_name=t2.canvas_step_name AND t1.canvas_variation_name =t2.canvas_variation_name AND t1.date = t2.date
FULL OUTER JOIN
  {{ ref('stg_email_bounce') }} t3
ON
  COALESCE(t1.canvas_name, t2.canvas_name) = t3.canvas_name AND
  COALESCE(t1.canvas_step_name, t2.canvas_step_name) = t3.canvas_step_name AND
  COALESCE(t1.canvas_variation_name, t2.canvas_variation_name) = t3.canvas_variation_name AND
  COALESCE(t1.date, t2.date) = t3.date
FULL OUTER JOIN
  {{ ref('stg_email_opened') }} t4
ON
 COALESCE(t1.canvas_name, t2.canvas_name,t3.canvas_name)=t4.canvas_name AND
 COALESCE(t1.canvas_step_name, t2.canvas_step_name,t3.canvas_step_name)=t4.canvas_step_name AND
 COALESCE(t1.canvas_variation_name, t2.canvas_variation_name,t3.canvas_variation_name)=t4.canvas_variation_name AND
 COALESCE(t1.date, t2.date,t3.date) = t4.date
FULL OUTER JOIN
  {{ ref('stg_email_soft_bounce') }} t5
ON
COALESCE(t1.canvas_name, t2.canvas_name,t3.canvas_name,t4.canvas_name)=t5.canvas_name AND
COALESCE(t1.canvas_step_name, t2.canvas_step_name,t3.canvas_step_name,t4.canvas_step_name)=t5.canvas_step_name AND
COALESCE(t1.canvas_variation_name, t2.canvas_variation_name,t3.canvas_variation_name,t4.canvas_variation_name)=t5.canvas_variation_name AND
COALESCE(t1.date, t2.date,t3.date,t4.date) = t5.date
FULL OUTER JOIN
  {{ ref('stg_email_unsubscribed') }} t6
ON
  COALESCE(t1.canvas_name, t2.canvas_name,t3.canvas_name,t4.canvas_name,t5.canvas_name)=t6.canvas_name AND
  COALESCE(t1.canvas_step_name, t2.canvas_step_name,t3.canvas_step_name,t4.canvas_step_name,t5.canvas_step_name)=t6.canvas_step_name AND
  COALESCE(t1.canvas_variation_name, t2.canvas_variation_name,t3.canvas_variation_name,t4.canvas_variation_name,t5.canvas_variation_name)=t6.canvas_variation_name AND
  COALESCE(t1.date, t2.date,t3.date,t4.date,t5.date) = t6.date
FULL OUTER JOIN
  {{ ref('stg_email_link_clicked') }} t7
ON
COALESCE(t1.canvas_name, t2.canvas_name,t3.canvas_name,t4.canvas_name,t5.canvas_name,t6.canvas_name)=t7.canvas_name AND
COALESCE(t1.canvas_step_name, t2.canvas_step_name,t3.canvas_step_name,t4.canvas_step_name,t5.canvas_step_name,t6.canvas_step_name)=t7.canvas_step_name AND
COALESCE(t1.canvas_variation_name, t2.canvas_variation_name,t3.canvas_variation_name,t4.canvas_variation_name,t5.canvas_variation_name,t6.canvas_variation_name)=t7.canvas_variation_name AND
COALESCE(t1.date, t2.date,t3.date,t4.date,t5.date,t6.date) = t7.date

)
group by 1,2,3,4,5