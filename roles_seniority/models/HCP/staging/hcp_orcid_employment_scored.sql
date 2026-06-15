-- Score each ORCID employment record for HCP likelihood.
-- Reads directly from orcid_researchers; records with no health signals score 0
-- and are excluded by downstream phase1 threshold filtering.
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
  -- All health-identified roles score 1.00; bucket classification is separate.
  CASE
    -- Non-clinical consultant → 0 (checked first)
    WHEN role_clean IS NOT NULL
         AND REGEXP_CONTAINS(role_clean, r'\bconsultant\b')
         AND REGEXP_CONTAINS(role_clean,
           r'\b(data|it|digital|analytics|technology|management|'
           r'business|strategy|financial|marketing)\b')
         THEN 0.0

    -- 1.00: All explicitly health-identified roles
    -- Practitioner
    WHEN role_clean IS NOT NULL AND REGEXP_CONTAINS(role_clean,
      r'(physician|surgeon|cardiologist|oncologist|radiologist|'
      r'dermatologist|neurologist|psychiatrist|'
      r'general\s*practitioner|\bgp\b|'
      r'registrar|resident\s*physician|attending\s*physician|attending\b|'
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
      r'\bnurse\b|ward\s*sister|enrolled\s*nurse|'
      r'\bdentist\b|general\s*dental\s*practitioner|\bgdp\b|'
      r'dental\s*partner|dental\s*practice\s*owner|dental\s*director|'
      r'clinician|clinical\s*fellow|clinical\s*specialist|'
      r'medical\s*officer|clinical\s*officer|house\s*officer|'
      r'senior\s*house\s*officer|foundation\s*doctor|junior\s*doctor|'
      r'specialist\s*registrar|consultant\b|'
      r'nurse\s*specialist|advanced\s*practice\s*nurse|'
      r'advanced\s*practice\s*provider|ward\s*nurse|'
      r'clinical\s*pharmacist|hospital\s*pharmacist|'
      r'community\s*pharmacist|specialist\s*pharmacist|'
      r'lead\s*pharmacist|pharmacy\s*manager|'
      r'specialist\s*nurse|research\s*nurse|practice\s*nurse|'
      r'district\s*nurse|health\s*visitor|nurse\s*manager|'
      r'ward\s*manager|clinical\s*nurse\s*specialist|'
      r'advanced\s*nurse|community\s*nurse|school\s*nurse|'
      r'occupational\s*health\s*nurse|'
      r'\bpharmacist\b|dietitian|dietician|optometrist|podiatrist|'
      r'practitioner|specialist|\bmd\b|\bdo\b|doctor\b|practice\s*owner|'
      -- Researcher
      r'principal\s*investigator|\bpi\b|chief\s*investigator|'
      r'group\s*leader|lab\s*director|laboratory\s*director|'
      r'clinical\s*professor|'
      r'professor\s*(of\s*)?(medicine|surgery|nursing|oncology|'
      r'cardiology|pharmacology|pharmacy|neuroscience|biochemistry|immunology)|'
      r'(medicine|surgery|oncology|pharmacology|pharmacy)\s*professor|'
      r'senior\s*scientist|senior\s*researcher|research\s*scientist|'
      r'research\s*fellow|postdoc|research\s*associate\b|'
      r'molecular\s*biolog|biopharma|'
      r'clinical\s*researcher|clinical\s*research\s*(associate|coordinator|manager)|'
      -- Administrator
      r'chief\s*scientific\s*officer|\bcso\b|'
      r'vp.*(research|r&d|medical\s*affairs)|'
      r'vice\s*president.*(research|r&d|medical)|'
      r'practice\s*manager|clinic\s*manager|'
      r'lab\s*manager|laboratory\s*manager|'
      r'health\s*service\s*manager|healthcare\s*manager|'
      -- Generic HCP (self-identified)
      r'healthcare\s*professional|health\s*professional|'
      r'medical\s*professional|health\s*worker|health\s*practitioner|'
      r'health\s*officer|medical\s*officer)')
      THEN 1.00

    -- 1.00: Generic management title in health org or dept context
    WHEN role_clean IS NOT NULL
         AND REGEXP_CONTAINS(role_clean,
           r'(\bhead\s+of\b|\bdirector\b|\bmanager\b|\bchief\b|'
           r'\bsuperintendent\b|\bexecutive\b|\bvice\s*president\b|\bvp\b|\badministrator\b)')
         AND (
           REGEXP_CONTAINS(COALESCE(org_clean, ''),
             r'(health|hospital|\bclinic\b|nhs\b|pharma|medical|dental|'
             r'cancer|clinical\s*research|biotech|biopharma)')
           OR REGEXP_CONTAINS(COALESCE(dept_clean, ''),
             r'(medicine|clinical|nursing|oncology|pharmacy|health|'
             r'cardiology|neurology|surgery|dental|radiology)')
         )
         THEN 1.00

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
      r'ambulance\s*service|emergency\s*services|'
      r'dental\s*practice|dental\s*surgery)')
      THEN 1.00

    WHEN org_clean IS NOT NULL AND REGEXP_CONTAINS(org_clean,
      r'(school\s*of\s*medicine|college\s*of\s*medicine|'
      r'faculty\s*of\s*(medicine|health)|medical\s*university|'
      r'university\s*of\s*medicine|medical\s*school|'
      r'academic\s*medical\s*cent(er|re)|teaching\s*hospital|'
      r'pharmaceutical|pharma\b|biopharma|biotech|'
      r'cancer\s*(research|centre|center)|'
      r'clinical\s*research\s*(organisation|organization)|'
      r'medical\s*research\s*council|\bmrc\b)')
      THEN 0.60

    WHEN org_clean IS NOT NULL
         AND REGEXP_CONTAINS(org_clean, r'\buniversit')
         AND (
           REGEXP_CONTAINS(COALESCE(role_clean, ''),
             r'(physician|surgeon|nurse|nursing|clinician|registrar|'
             r'consultant|practitioner|paramedic|physiotherapist|'
             r'occupational\s*ther|radiographer|\bgp\b|'
             r'nurse\s*practitioner|research\s*nurse|practice\s*nurse|'
             r'principal\s*investigator|researcher|scientist)')
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
             r'nurse\s*practitioner|research\s*nurse|researcher|scientist)')
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
      r'nursing|midwifery|dentistry|dental|'
      r'primary\s*care|community\s*health|'
      r'allied\s*health|occupational\s*therapy|'
      r'physiotherapy|speech\s*therapy|dietetics|'
      r'pharmacology|pharmacy\b)')
      THEN 1.00

    WHEN dept_clean IS NOT NULL AND REGEXP_CONTAINS(dept_clean,
      r'(clinical|patient\s*care|ward\b|outpatient|inpatient|'
      r'secondary\s*care|tertiary\s*care|pharmacy|'
      r'\bmedicine\b)')
      THEN 0.50

    ELSE 0.0
  END AS dept_score,

  -- HCP BUCKET: PRACTITIONER / RESEARCHER / ADMINISTRATOR
  CASE
    -- PRACTITIONER: direct patient-care and clinical roles
    WHEN REGEXP_CONTAINS(COALESCE(role_clean, ''),
      r'(physician|surgeon|\bdoctor\b|clinician|clinical\s*fellow|'
      r'registrar|resident\s*physician|attending\b|hospitalist|intensivist|'
      r'house\s*officer|foundation\s*doctor|junior\s*doctor|'
      r'\bnurse\b|nurse\s*practitioner|\bnp\b|\banp\b|'
      r'nurse\s*specialist|ward\s*nurse|ward\s*sister|staff\s*nurse|'
      r'charge\s*nurse|enrolled\s*nurse|registered\s*nurse|\brn\b|'
      r'clinical\s*nurse|practice\s*nurse|research\s*nurse|district\s*nurse|'
      r'community\s*nurse|advanced\s*nurse|specialist\s*nurse|school\s*nurse|'
      r'health\s*visitor|nurse\s*manager|ward\s*manager|'
      r'\bdentist\b|\bgdp\b|dental\s*partner|dental\s*practice\s*owner|'
      r'\bgp\b|general\s*practitioner|'
      r'paramedic|physiotherapist|occupational\s*therapist|radiographer|'
      r'anesthesiologist|anaesthetist|obstetrician|gynecologist|gynaecologist|'
      r'urologist|orthop(a)?edic|emergency\s*physician|'
      r'cardiologist|oncologist|radiologist|neurologist|psychiatrist|'
      r'dermatologist|infectious\s*disease\s*physician|palliative\s*care|'
      r'physician\s*assoc|physician\s*assist|'
      r'medical\s*director|clinical\s*director|chief\s*of\s*(medicine|surgery|staff)|'
      r'dietitian|dietician|optometrist|podiatrist|'
      r'\bpharmacist\b|clinical\s*pharmacist|hospital\s*pharmacist|'
      r'community\s*pharmacist|specialist\s*pharmacist|'
      r'healthcare\s*professional|health\s*professional|'
      r'medical\s*professional|health\s*worker|health\s*practitioner|'
      r'practitioner|specialist|\bmd\b|\bdo\b|doctor\b)')
      THEN 'PRACTITIONER'

    -- RESEARCHER: scientific / research roles in health/pharma context
    WHEN REGEXP_CONTAINS(COALESCE(role_clean, ''),
      r'(principal\s*investigator|\bpi\b|chief\s*investigator|'
      r'senior\s*scientist|senior\s*researcher|research\s*scientist|'
      r'research\s*fellow|postdoc|research\s*associate\b|'
      r'molecular\s*biolog|group\s*leader|'
      r'professor\s*(of\s*)?(medicine|surgery|nursing|oncology|cardiology|'
      r'pharmacology|pharmacy|neuroscience|biochemistry|immunology)|'
      r'(medicine|surgery|oncology|pharmacology|pharmacy)\s*(professor|chair)|'
      r'clinical\s*professor|biopharma|'
      r'clinical\s*research\s*(associate|coordinator|manager))')
      THEN 'RESEARCHER'

    -- ADMINISTRATOR: explicit health leadership/exec roles, or generic management title in health org/dept
    WHEN REGEXP_CONTAINS(COALESCE(role_clean, ''),
      r'(chief\s*scientific\s*officer|\bcso\b|'
      r'vp.*(research|r&d|medical\s*affairs)|'
      r'vice\s*president.*(research|r&d|medical)|'
      r'lab\s*director|laboratory\s*director|'
      r'lab\s*manager|laboratory\s*manager|'
      r'practice\s*manager|clinic\s*manager|'
      r'health\s*service\s*manager|healthcare\s*manager)')
      OR (
        REGEXP_CONTAINS(COALESCE(role_clean, ''),
          r'(\bhead\s+of\b|\bdirector\b|\bmanager\b|\bchief\b|'
          r'\bsuperintendent\b|\bexecutive\b|\bvice\s*president\b|\bvp\b|\badministrator\b)')
        AND (
          REGEXP_CONTAINS(COALESCE(org_clean, ''),
            r'(health|hospital|\bclinic\b|nhs\b|pharma|medical|dental|'
            r'cancer|clinical\s*research|biotech|biopharma)')
          OR REGEXP_CONTAINS(COALESCE(dept_clean, ''),
            r'(medicine|clinical|nursing|oncology|pharmacy|health|'
            r'cardiology|neurology|surgery|dental|radiology)')
        )
      )
      THEN 'ADMINISTRATOR'

    ELSE NULL
  END AS hcp_bucket

FROM {{ ref('orcid_researchers') }}
