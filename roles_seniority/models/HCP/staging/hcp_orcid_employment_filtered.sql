-- Filter ORCID employment records and drop
-- clearly non-clinical / academic roles. This stage produces the
-- employment rows that can be scored for HCP identification.
SELECT
  snid,
  orcid_id,
  role_clean,
  org_clean,
  dept_clean,
  country_code,
  full_start_date,
  full_end_date
FROM {{ ref('orcid_researchers') }}
WHERE
  role_clean IS NULL
  OR (
    -- A: Academic / research / non-clinical identities
    NOT REGEXP_CONTAINS(role_clean,
      r'(student|phd\s*student|postdoc(?:toral)?|'
      r'research\s*fellow|research\s*associate|research\s*scientist|'
      r'bioinformatic|computational\s*biolog|data\s*scientist|'
      r'epidemiologist|biostatistician|scientific\s*officer|'
      r'laboratory\s*manager|lab\s*manager|'
      r'\btechnician\b|administrative|secretary|'
      r'librarian|archivist|curator)'
    )
    -- B: Non-clinical IT / data / management professional roles
    AND NOT REGEXP_CONTAINS(role_clean,
      r'(management\s*consultant|it\s*consultant|'
      r'data\s*analyst|data\s*engineer|data\s*architect|'
      r'systems?\s*analyst|business\s*analyst|'
      r'project\s*manager|programme\s*manager|program\s*manager|'
      r'operations\s*manager|'
      r'chief\s*(information|technology|digital)\s*officer|'
      r'\bcio\b|\bcto\b|\bcdo\b)'
    )
    -- C: Consultant + non-clinical modifier
    AND NOT (
      REGEXP_CONTAINS(role_clean, r'\bconsultant\b')
      AND REGEXP_CONTAINS(role_clean,
        r'\b(data|it|digital|analytics|technology|business|strategy|financial|marketing)\b'
      )
    )
  )