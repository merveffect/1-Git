
   
      -- generated script to merge partitions into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria`
      declare dbt_partitions_for_replacement array<date>;

      
      
       -- 1. create a temp table with model data
        
  
    

    create or replace table `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria__dbt_tmp`
      
    partition by etoc_date
    

    
    OPTIONS(
      description="""""",
    
      expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 12 hour)
    )
    as (
      

WITH main AS (
    SELECT
        DISTINCT rcpt_to AS rcpt_to,
        JSON_EXTRACT(rcpt_meta.json, '$.journalId') AS journal_id,
        REGEXP_EXTRACT(subject, r'(.*?)[-:]') AS journal_title,
        MIN(DATE(timestamp)) AS time_firstseen
    FROM `poc-spring-email-metrics`.`sparkpost_metrics_live`.`message_event`
    WHERE type = 'delivery'
      AND REGEXP_CONTAINS(campaign_id, 'toc-alert')
      AND subject != 'Confirm your email for journal alerts'
    GROUP BY 1,2,3
)

SELECT
  time_firstseen AS etoc_date,
  journal_id,
  journal_title,
  COUNT(DISTINCT(rcpt_to)) AS num_etoc_signups
FROM
  main


  WHERE DATE(time_firstseen) BETWEEN 
    
      DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
    
    AND
    
      CURRENT_DATE()
    

GROUP BY
  1,
  2,
  3
    );
  
      -- 2. define partitions to update
      set (dbt_partitions_for_replacement) = (
          select as struct
              -- IGNORE NULLS: this needs to be aligned to _dbt_max_partition, which ignores null
              array_agg(distinct date(etoc_date) IGNORE NULLS)
          from `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria__dbt_tmp`
      );

      -- 3. run the merge statement
      

    merge into `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria` as DBT_INTERNAL_DEST
        using (
        select
        * from `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria__dbt_tmp`
      ) as DBT_INTERNAL_SOURCE
        on FALSE

    when not matched by source
         and date(DBT_INTERNAL_DEST.etoc_date) in unnest(dbt_partitions_for_replacement) 
        then delete

    when not matched then insert
        (`etoc_date`, `journal_id`, `journal_title`, `num_etoc_signups`)
    values
        (`etoc_date`, `journal_id`, `journal_title`, `num_etoc_signups`)

;

      -- 4. clean up the temp table
      drop table if exists `snproject-cbb9ca25`.`dbt_dev_ga4_ria_researcher_report`.`etoc_4ria__dbt_tmp`

  


  

    