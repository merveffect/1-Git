-- Phase 5 combination: genuine/trackable researcher filter (Colab
-- mis_2_latest_month_users_2). Keeps users whose GA behaviour over the lookback window
-- looks like a real researcher (session / pageview thresholds + reached an article or
-- submission guidelines). Submission-system hostnames are excluded.
--
-- SN-REVIEW (D1): thresholds are gr_* vars (defaults: sessions in (1,360),
-- pageviews/session in (1,100)). The imprint-match filter is intentionally left off
-- (commented in the Colab).

{{ config(materialized='table', tags=['ga']) }}

select *
from (
    select
        *,
        n_pageviews / n_session_starts as n_pageviews_per_session
    from (
        select
            us1.user_pseudo_id,
            us2.hostname_cleaned,
            sum(case when event_name = "session_start" then event_count else 0 end) as n_session_starts,
            sum(case when event_name = "page_view" then event_count else 0 end) as n_pageviews,
            sum(case when event_name = "reach_full_text_article" or event_name = "reach_fta_page" then event_count else 0 end) as n_reach_ftas,
            sum(case when event_name = "reach_journal_submission_guidelines" then event_count else 0 end) as n_reach_submission_guidelines
        from {{ ref('int_latest_month_users') }} us1
        inner join {{ ref('int_ga_data') }} us2
            on us1.user_pseudo_id = us2.user_pseudo_id
        where us2.event_date >= date_sub(date('{{ var("mis_start_date") }}'), interval {{ var("ga_lookback_months") }} month)
          and us2.event_date <= date('{{ var("mis_end_date") }}')
          and hostname <> "idp-personal-authenticator.springernature.com"
          and hostname <> "submission.springernature.com"
          and hostname <> "editorial.springernature.com"
        group by 1, 2
    )
    where n_session_starts > {{ var("gr_min_sessions") }}
      and n_session_starts < {{ var("gr_max_sessions") }}
      and (n_reach_ftas > 0 or n_reach_submission_guidelines > 0)
)
where n_pageviews_per_session > {{ var("gr_min_pv_per_session") }}
  and n_pageviews_per_session < {{ var("gr_max_pv_per_session") }}
