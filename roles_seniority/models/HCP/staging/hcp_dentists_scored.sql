{{ config(materialized='table') }}

-- All dentistry-related professionals identified from ORCID employment records.
--
-- Bucketing logic (dentist_bucket):
--   Primary  : earliest dental role full_start_date >= 3 years ago → PRINCIPAL_DENTIST
--   Primary  : earliest dental role full_start_date <  3 years ago → ASSOCIATE_DENTIST
--   Fallback : no start date → title keyword match
--              (principal / practice owner / dental partner / director / clinic owner → PRINCIPAL_DENTIST,
--               everything else → ASSOCIATE_DENTIST)

WITH all_dental_records AS (
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
  -- BigQuery REGEXP is case-insensitive by default if configured, but patterns here are lowercase-optimized.
  -- Covers: English, Spanish, Portuguese, French, German, Italian, Turkish, Dutch, Polish, Russian, 
  -- Ukrainian, Arabic, Persian, Chinese, Japanese, Korean, Hindi, Swedish, Danish, Norwegian, Finnish, 
  -- Greek, Czech, Romanian, Hungarian, Vietnamese, etc.
  WHERE REGEXP_CONTAINS(LOWER(COALESCE(role_clean, '')),
    -- 1. English & International Roots (Extensively Expanded)
    r'(dentist|dental|dentistry|orthodont|endodont|periodont|prosthodont|pedodont|paedodont|'
    r'implantolog|stomatolog|gnatholog|orofacial|maxillofacial|dentoalveolar|odontolog|'
    r'oral\s*surg|oral\s*med|oral\s*patholog|oral\s*radiolog|oral\s*health|oral\s*biolog|'
    r'operative\s*dentis|aesthetic\s*dentis|esthetic\s*dentis|cosmetic\s*dentis|restorative\s*dentis|'
    r'dental\s*surgeon|dental\s*hygien|dental\s*therap|dental\s*assist|dental\s*technic|dental\s*nurs|'
    r'gdp\b|bds\b|dds\b|dmd\b|mscd\b|mdsc\b|bchd\b|mdent\b|ddsc\b|fds\rcs|'
    -- 2. Spanish, Portuguese, Italian & Romanian (Romance Languages)
    r'dentista|cirujano\s*dentista|cirurgi[aã]o?\s*dentista|m[eé]dico\s*dentista|odontolog|odontoiatra|'
    r'ortodontista|odontólogo|odontóloga|odontologo|odontologa|stomatolog|medic\s*dentistar|'
    r'higienista\s*dental|protésico\s*dental|protesico\s*dental|chirurgia\s*orale|'
    -- 3. French
    r'chirurgien.{0,2}dentiste|stomatologue|orthodontiste|parodontiste|dentisterie|'
    r'hygiéniste\s*dentaire|prothésiste\s*dentaire|'
    -- 4. German & Dutch (Germanic Languages)
    r'zahnarzt|zahnärztin|zahnärzt|kieferorthop|kieferchirurg|zahnmedizin|tandarts|parodontoloog|'
    r'orthodontist|tandheelkunde|dr\s*med\s*dent|zahnärztlicher|oralchirurgie|zahngesundheit|'
    -- 5. Turkish
    r'diş\s*hekim|dis\s*hekim|ortodonti|endodonti|periodontoloji|pedodonti|ağız\s*çene|agiz\s*cene|çene\s*cerrah|cene\s*cerrah|restoratif\s*diş|periyodontoloji|'
    r'diş\s*tabib|dis\s*tabib|ağız\s*sağlığı|agiz\s*sagligi|diş\s*protez|dis\s*protez|'
    -- 6. Scandinavian & Finnish (Nordic)
    r'tandläkare|tandlaege|tandlege|hammaslääkäri|ortodonti|tandplejer|tandtekniker|'
    -- 7. Polish, Czech, Russian, Ukrainian (Slavic Languages - Cyrillic & Romanized)
    r'stomatolog|dentysta|ortodonta|ortodont|зубной\s*врач|стоматолог|ортодонт|зубний\s*ліkar|stomatol|'
    r'zubní|zubari|chइrurgıa\s*stomatolog|protetyka\s*stomatolog|'
    -- 8. Greek & Hungarian
    r'οδοντίατρος|fogorvos|fogászat|orthodontus|οδοντική|'
    -- 9. Arabic & Persian/Farsi (Arabic Script & Romanized)
    r'طبيب\s*أسنان|طبيبة\s*أسنان|طب\s*الأسنان|جراحة\s*الفم|دندان‌پزشک|دندانپزشک|tabib\s*asnan|dandanpezeshk|'
    -- 10. Asian Languages: Chinese, Japanese, Korean, Vietnamese (Native & Romanized)
    r'牙医|牙醫師|牙科|口腔|歯科|歯科医|치과의사|치과|nha\s*sĩ|nha\s*khoa|răng\s*hàm\s*mặt)')
),

career_start AS (
  SELECT
    snid,
    MIN(full_start_date) AS earliest_dental_start
  FROM all_dental_records
  WHERE full_start_date IS NOT NULL
  GROUP BY snid
),

latest_record AS (
  SELECT
    snid,
    orcid_id,
    role_clean,
    org_clean,
    dept_clean,
    country_code,
    full_start_date,
    full_end_date,
    ROW_NUMBER() OVER (
      PARTITION BY snid
      ORDER BY
        CASE WHEN full_end_date IS NULL THEN 0 ELSE 1 END ASC,
        full_end_date   DESC NULLS LAST,
        full_start_date DESC NULLS LAST
    ) AS rn
  FROM all_dental_records
)

SELECT
  r.snid,
  r.orcid_id,
  r.role_clean                                                 AS dentist_role,
  r.org_clean                                                  AS organisation,
  r.dept_clean                                                 AS department,
  r.country_code,
  r.full_start_date,
  r.full_end_date,
  c.earliest_dental_start,
  DATE_DIFF(CURRENT_DATE(), DATE(c.earliest_dental_start), YEAR) AS years_experience,

  CASE
    -- Rule 1: Has start date and >= 3 years of experience
    WHEN c.earliest_dental_start IS NOT NULL
      AND DATE_DIFF(CURRENT_DATE(), DATE(c.earliest_dental_start), YEAR) >= 3
      THEN 'PRINCIPAL_DENTIST'
      
    -- Rule 2: Has start date and < 3 years of experience
    WHEN c.earliest_dental_start IS NOT NULL
      AND DATE_DIFF(CURRENT_DATE(), DATE(c.earliest_dental_start), YEAR) < 3
      THEN 'ASSOCIATE_DENTIST'
      
    -- Rule 3: No start date, fallback to executive/owner keywords (Multilingual)
    WHEN REGEXP_CONTAINS(LOWER(COALESCE(r.role_clean, '')),
      -- English
      r'(principal\s*dentist|practice\s*owner|dental\s*partner|dental\s*practice\s*owner|'
      r'dental\s*director|chief\s*dental|head\s*of\s*dental|lead\s*dentist|founder|co-founder|'
      r'owner\s*(of\s*)?(a\s*)?(dental|dentist)|dental\s*(practice|surgery|clinic)\s*(owner|partner|principal|director)|'
      -- Spanish / Portuguese
      r'propietario|director\s*médico|director\s*medico|dono\s*de\s*cl[ií]nica|cl[ií]nica\s*propia|'
      -- French
      r'titulaire|chef\s*de\s*clinique|propriétaire|'
      -- German / Dutch
      r'praxisinhaber|praxisinhaberin|klinikleiter|praktijkowner|praktijkeigenaar|'
      -- Turkish
      r'klinik\s*sahibi|muayenehane\s*sahibi|başhekim|bashekim|kurucu|'
      -- Russian / Polish
      r'главный\s*врач|владелец\s*клиники|właściciel\s*gabinetu)')
      THEN 'PRINCIPAL_DENTIST'
      
    -- Rule 4: Default fallback
    ELSE 'ASSOCIATE_DENTIST'
  END                                                          AS dentist_bucket

FROM latest_record r
LEFT JOIN career_start c ON r.snid = c.snid
WHERE r.rn = 1