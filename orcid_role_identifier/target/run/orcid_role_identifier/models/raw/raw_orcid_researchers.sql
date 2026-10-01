

  create or replace view `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_raw`.`raw_orcid_researchers`
  OPTIONS(
      description="""orcid_researchers as-is, plus the VISIBILITY FILTER and the SNID filter. Non-public records are dropped from the arrays here so no model above needs to repeat the condition.\n"""
    )
  as 

/*
    RAW LAYER - orcid_researchers

    Its only job: surface the source as-is, plus the VISIBILITY FILTER.

    We will never use non-public data anywhere, so the filter is applied
    once here; no model above this needs to know about visibility.

    In ORCID visibility is per RECORD: the same person can have one
    employment marked PUBLIC and another PRIVATE. So the arrays are
    rebuilt - we drop records, not people.

    Note the snid filter: the table holds 24.8M ORCID profiles but only
    ~1.76M carry an SNID. Without an SNID the person is unreachable, so
    they never enter the pipeline.
*/



select
    snid,
    orcid_id,
    created_at,
    last_updated_at,
    name,
    biography,
    country_codes,
    keywords,

    
    -- keep PUBLIC records only; array shape is preserved
    array(select e from unnest(employments)  e where upper(e.visibility) = 'PUBLIC') as employments,
    array(select d from unnest(educations)   d where upper(d.visibility) = 'PUBLIC') as educations,
    array(select p from unnest(publications) p where upper(p.visibility) = 'PUBLIC') as publications,
    array(select m from unnest(emails)       m where upper(m.visibility) = 'PUBLIC') as emails,
    array(select v from unnest(peer_reviews) v where upper(v.visibility) = 'PUBLIC') as peer_reviews
    

from `researcher-360-prod-e7fd74be`.`researcher_profiles`.`orcid_researchers`
where snid is not null;

