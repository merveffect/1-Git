-- Extract CDP behavioral signals for Phase 2 validation.
-- This model converts readership and keyword fields into binary
-- clinical signals, plus collects submission-guideline activity.
SELECT
  cdp.snid,

  CASE
    WHEN REGEXP_CONTAINS(
      LOWER(
        COALESCE(cdp.list_article_title_from_readership, '') || ' ' ||
        COALESCE(cdp.list_article_title_from_view, '')
      ),
      r'(clinical\s*trial|patient|diagnosis|treatment|therapy|'
      r'surgical|medical\s*management|drug\s*dosage|'
      r'clinical\s*practice|guidelines|case\s*report|'
      r'randomized\s*controlled|adverse\s*event|'
      r'pharmacotherapy|prognosis|symptom|comorbidity|'
      r'emergency|intensive\s*care|postoperative|'
      r'evidence.?based|dosing|prescribing|protocol|wound\s*care|'
      r'infection\s*control|perioperative|intraoperative|'
      r'discharge|outpatient|inpatient|ward\b|bedside)'
    ) THEN 1 ELSE 0
  END AS has_clinical_article_reads,

  CASE
    WHEN REGEXP_CONTAINS(
      LOWER(REGEXP_REPLACE(COALESCE(cdp.list_keywords_dois_last_60_d, ''), r'\\', ' ')),
      r'(clinical|pharmacology|therapeutics|diagnostics|'
      r'patient\s*management|evidence.?based\s*medicine|'
      r'drug\s*interaction|dosing|prescribing|'
      r'treatment\s*protocol|surgical\s*technique|'
      r'medical\s*device|wound\s*care|infection\s*control|'
      r'nursing|allied\s*health|pharmacy\b)'
    ) THEN 1 ELSE 0
  END AS has_clinical_keywords,

  CAST(COALESCE(cdp.count_submguidelines_last_30_d, 0) AS INT64) AS submguidelines_30d

FROM {{ ref('audience_builder_big') }} cdp
WHERE cdp.snid IS NOT NULL