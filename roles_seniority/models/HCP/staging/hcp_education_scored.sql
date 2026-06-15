{{ config(materialized='table') }}

SELECT
  snid,
  orcid_id,
  degree_clean,
  dept_clean,
  full_start_date,
  full_end_date,
  ROUND((degree_score * 0.50) + (dept_score * 0.50), 4) AS education_score

FROM (
  SELECT
    snid,
    orcid_id,
    LOWER(TRIM(e.degree))          AS degree_clean,
    LOWER(TRIM(e.department_name)) AS dept_clean,
    e.full_start_date,
    e.full_end_date,

    CASE
      WHEN REGEXP_CONTAINS(LOWER(TRIM(COALESCE(e.degree, ''))),
        r'(\bmd\b|\bm\.d\.\b|mbbs|mbbch|mb\s*bch|mbchb|'
        r'\bbds\b|\bdds\b|'
        r'doctor\s*of\s*medicine|bachelor\s*of\s*medicine|'
        r'bachelor\s*of\s*nursing|master\s*of\s*nursing|'
        r'bachelor\s*of\s*pharmacy|doctor\s*of\s*pharmacy|'
        r'\bpharmd\b|\bpharm\.d\b|'
        r'registered\s*nurse|'
        r'medicine\s*and\s*surgery|bachelor\s*of\s*dental\s*surgery|'
        r'\bbpharm\b|bachelor\s*of\s*science\s*in\s*nursing)')
        THEN 1.00
      ELSE 0.0
    END AS degree_score,

    CASE
      WHEN REGEXP_CONTAINS(LOWER(TRIM(COALESCE(e.department_name, ''))),
        r'(\bmedicine\b|surgery|nursing|midwifery|dentistry|\bdental\b|'
        r'pharmacy|pharmacology|clinical\s*medicine|'
        r'school\s*of\s*medicine|faculty\s*of\s*medicine|medical\s*school|'
        r'haematology|hematology|oncology|cardiology|radiology|'
        r'neurology|neurosurgery|psychiatry|dermatology|'
        r'paediatrics|pediatrics|obstetrics|gynaecology|gynecology|'
        r'urology|anaesthesiology|anesthesiology|'
        r'emergency\s*medicine|infectious\s*disease|'
        r'physiotherapy|occupational\s*therapy|allied\s*health|'
        r'nursing\s*and\s*midwifery|faculty\s*of\s*health|'
        r'\bclinical\b|department\s*of\s*(medicine|surgery|clinical))')
        THEN 1.00
      WHEN REGEXP_CONTAINS(LOWER(TRIM(COALESCE(e.department_name, ''))),
        r'(health\s*science|public\s*health|biomedical|'
        r'health\s*and\s*medical|\bmedical\b|\bhealth\b)')
        THEN 0.80
      ELSE 0.0
    END AS dept_score

  FROM {{ source('researcher_profiles', 'v_orcid_researchers') }},
  UNNEST(educations) AS e
  WHERE snid IS NOT NULL
    AND (e.degree IS NOT NULL OR e.department_name IS NOT NULL)
)
WHERE (degree_score + dept_score) > 0
