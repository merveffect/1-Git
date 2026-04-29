
-- Calculate role, organization, and department scores for filtered employment records
SELECT
  snid,
  orcid_id,
  role_clean,
  org_clean,
  dept_clean,
  country_code,
  full_start_date,
  full_end_date,

  -- ROLE TITLE SCORE (weight = 0.50)
  CASE
    WHEN role_clean IS NOT NULL
         AND REGEXP_CONTAINS(role_clean, r'\bconsultant\b')
         AND REGEXP_CONTAINS(role_clean,
           r'\b(data|it|digital|analytics|technology|management|'
           r'business|strategy|financial|marketing)\b')
         THEN 0.0

    WHEN role_clean IS NOT NULL AND REGEXP_CONTAINS(role_clean,
      r'(physician|surgeon|cardiologist|oncologist|radiologist|'
      r'dermatologist|neurologist|psychiatrist|'
      r'general\s*practitioner|\bgp\b|'
      r'registrar|resident\s*physician|attending\s*physician|'
      r'hospitalist|intensivist|medical\s*director|clinical\s*director|'
      r'consultant\s*physician|chief\s*of\s*(medicine|surgery|staff)|'
      r'registered\s*nurse|\brn\b|staff\s*nurse|charge\s*nurse|'
      r'clinical\s*nurse|nurse\s*practitioner|\bnp\b|\banp\b|'
      r'physician\s*associate|physician\s*assistant|\bpa\b|'
      r'paramedic|physiotherapist|occupational\s*therapist|'
      r'radiographer|anesthesiologist|anaesthetist|'
      r'obstetrician|gynecologist|gynaecologist|urologist|'
      r'orthop(a)?edic\s*surgeon|emergency\s*physician|'
      r'infectious\s*disease\s*physician|palliative\s*care|'
      r'\bnurse\b|'
      r'ward\s*sister|enrolled\s*nurse)')
      THEN 1.00

    WHEN role_clean IS NOT NULL AND REGEXP_CONTAINS(role_clean,
      r'(clinician|clinical\s*fellow|clinical\s*specialist|'
      r'medical\s*officer|clinical\s*officer|house\s*officer|'
      r'senior\s*house\s*officer|foundation\s*doctor|junior\s*doctor|'
      r'specialist\s*registrar|consultant\b|attending\b|'
      r'nurse\s*specialist|advanced\s*practice\s*nurse|'
      r'advanced\s*practice\s*provider|ward\s*nurse|'
      r'clinical\s*pharmacist|specialist\s*nurse|'
      r'research\s*nurse|practice\s*nurse|district\s*nurse|'
      r'health\s*visitor|nurse\s*manager|ward\s*manager|'
      r'clinical\s*nurse\s*specialist|advanced\s*nurse|'
      r'community\s*nurse|school\s*nurse|'
      r'occupational\s*health\s*nurse)')
      THEN 0.70

    WHEN role_clean IS NOT NULL AND REGEXP_CONTAINS(role_clean,
      r'(practitioner|specialist|clinician|'
      r'\bmd\b|\bdo\b|doctor\b|'
      r'clinical\s*professor|'
      r'professor\s*of\s*(medicine|surgery|nursing|oncology|cardiology|radiology))')
      THEN 0.40

    WHEN role_clean IS NOT NULL AND REGEXP_CONTAINS(role_clean,
      r'(pharmacist|dietitian|dietician|optometrist|podiatrist|'
      r'healthcare\s*professional|health\s*professional|'
      r'medical\s*professional|health\s*worker|health\s*practitioner|'
      r'health\s*officer|medical\s*officer|clinical\s*researcher)')
      THEN 0.20

    ELSE 0.0
  END AS role_score,

  -- ORGANISATION SCORE (weight = 0.30)
  CASE
    WHEN org_clean IS NOT NULL AND REGEXP_CONTAINS(org_clean,
      r'(hospital|medical\s*cent(er|re)|health\s*system|'
      r'clinic\b|nhs|national\s*health\s*service|'
      r'memorial\s*hospital|general\s*hospital|university\s*hospital|'
      r'veterans\s*affairs|\bva\s*medical|royal\s*infirmary|infirmary|'
      r'integrated\s*health|community\s*health\s*cent(er|re)|'
      r'ambulance\s*service|emergency\s*services)')
      THEN 1.00

    WHEN org_clean IS NOT NULL AND REGEXP_CONTAINS(org_clean,
      r'(school\s*of\s*medicine|college\s*of\s*medicine|'
      r'faculty\s*of\s*(medicine|health)|medical\s*university|'
      r'university\s*of\s*medicine|medical\s*school|'
      r'academic\s*medical\s*cent(er|re)|teaching\s*hospital)')
      THEN 0.60

    WHEN org_clean IS NOT NULL
         AND REGEXP_CONTAINS(org_clean, r'\buniversit')
         AND (
           REGEXP_CONTAINS(COALESCE(role_clean, ''),
             r'(physician|surgeon|nurse|nursing|clinician|registrar|'
             r'consultant|practitioner|paramedic|physiotherapist|'
             r'occupational\s*ther|radiographer|\bgp\b|'
             r'nurse\s*practitioner|research\s*nurse|practice\s*nurse)')
           OR
           REGEXP_CONTAINS(COALESCE(dept_clean, ''),
             r'(medicine|surgery|cardiology|oncology|radiology|'
             r'emergency|paediatrics|pediatrics|neurology|'
             r'obstetrics|gynaecology|gynecology|urology|'
             r'nursing|clinical|patient\s*care|school\s*of\s*medicine|'
             r'faculty\s*of\s*medicine|college\s*of\s*medicine)')
         )
      THEN 0.60

    WHEN org_clean IS NOT NULL
         AND REGEXP_CONTAINS(org_clean, r'(health|medical|healthcare)')
         AND (
           REGEXP_CONTAINS(COALESCE(role_clean, ''),
             r'(physician|surgeon|nurse|nursing|clinician|registrar|'
             r'consultant|practitioner|paramedic|\bgp\b|doctor\b|'
             r'nurse\s*practitioner|research\s*nurse)')
           OR
           REGEXP_CONTAINS(COALESCE(dept_clean, ''),
             r'(medicine|surgery|cardiology|oncology|nursing|'
             r'emergency|clinical|patient\s*care)')
         )
      THEN 0.40

    WHEN org_clean IS NOT NULL AND REGEXP_CONTAINS(org_clean,
      r'(health|medical|healthcare)')
      THEN 0.25

    ELSE 0.0
  END AS org_score,

  -- DEPARTMENT SCORE (weight = 0.20)
  CASE
    WHEN dept_clean IS NOT NULL AND REGEXP_CONTAINS(dept_clean,
      r'(cardiology|oncology|radiology|internal\s*medicine|'
      r'emergency\s*(medicine|department|room)|paediatrics|pediatrics|'
      r'neurology|neurosurgery|obstetrics|gynaecology|gynecology|'
      r'urology|orthopaed|orthoped|anaesthesiology|anesthesiology|'
      r'dermatology|psychiatry|rheumatology|gastroenterology|'
      r'endocrinology|infectious\s*disease|pulmonology|'
      r'nephrology|haematology|hematology|ophthalmology|'
      r'intensive\s*care|\bicu\b|'
      r'department\s*of\s*(medicine|surgery|clinical)|'
      r'general\s*surgery|vascular\s*surgery|trauma\s*surgery|'
      r'breast\s*surgery|plastic\s*surgery|surgical\b|'
      r'school\s*of\s*medicine|faculty\s*of\s*medicine|'
      r'college\s*of\s*medicine|medical\s*school|'
      r'nursing|midwifery|'
      r'primary\s*care|community\s*health|'
      r'allied\s*health|occupational\s*therapy|'
      r'physiotherapy|speech\s*therapy|dietetics)')
      THEN 1.00

    WHEN dept_clean IS NOT NULL AND REGEXP_CONTAINS(dept_clean,
      r'(clinical|patient\s*care|ward\b|outpatient|inpatient|'
      r'secondary\s*care|tertiary\s*care|pharmacy|'
      r'\bmedicine\b)')
      THEN 0.50

    ELSE 0.0
  END AS dept_score

FROM {{ ref('hcp_orcid_employment_filtered') }}