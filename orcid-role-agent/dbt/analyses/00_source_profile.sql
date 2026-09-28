/*
    KAYNAK PROFILI - maliyet ve strateji bu sayilardan cikar.
    Sirayla calistir, ciktilari kaydet.
*/

-- ---------------------------------------------------------------------------
-- A. Genel hacim
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                    AS kisi,
    SUM(ARRAY_LENGTH(employments))              AS employment_kaydi,
    SUM(ARRAY_LENGTH(educations))               AS education_kaydi,
    SUM(ARRAY_LENGTH(publications))             AS publication_kaydi,
    SUM(ARRAY_LENGTH(keywords))                 AS keyword_kaydi,
    COUNTIF(ARRAY_LENGTH(employments) = 0)      AS employment_yok
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- ---------------------------------------------------------------------------
-- B. NORMALIZE EDILMIS distinct unvan sayisi
--    Ham sayi 355.803. Normalize edince ne kadar dusuyor?
--    Bu fark dogrudan maliyet tasarrufu.
-- ---------------------------------------------------------------------------
WITH roles AS (
  SELECT
      e.role                                                AS raw_role,
      TRIM(REGEXP_REPLACE(
        REGEXP_REPLACE(
          LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
          r'[^\p{L}\p{N}\s&/+-]', ' '),
        r'\s+', ' '))                                       AS norm_role
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
  UNNEST(employments) e
  WHERE e.role IS NOT NULL AND TRIM(e.role) != ''
)
SELECT
    COUNT(*)                        AS toplam_kayit,
    COUNT(DISTINCT raw_role)        AS ham_distinct,
    COUNT(DISTINCT norm_role)       AS normalize_distinct,
    ROUND(1 - COUNT(DISTINCT norm_role) / COUNT(DISTINCT raw_role), 3) AS tasarruf_orani
FROM roles;


-- ---------------------------------------------------------------------------
-- C. ⭐ FREKANS DAGILIMI - butun maliyet stratejisi buna dayaniyor
--    "En sik N unvan, kayitlarin yuzde kacini kapsiyor?"
-- ---------------------------------------------------------------------------
WITH roles AS (
  SELECT TRIM(REGEXP_REPLACE(
           REGEXP_REPLACE(LOWER(NORMALIZE_AND_CASEFOLD(e.role, NFKC)),
             r'[^\p{L}\p{N}\s&/+-]', ' '), r'\s+', ' ')) AS norm_role
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
  UNNEST(employments) e
  WHERE e.role IS NOT NULL AND TRIM(e.role) != ''
),
freq AS (
  SELECT norm_role, COUNT(*) AS n,
         ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM roles GROUP BY norm_role
),
cum AS (
  SELECT *, SUM(n) OVER (ORDER BY rnk) / SUM(n) OVER () AS kapsama
  FROM freq
)
SELECT
    esik AS ilk_n_unvan,
    (SELECT ROUND(MAX(kapsama), 4) FROM cum WHERE rnk <= esik) AS kayit_kapsamasi
FROM UNNEST([100, 500, 1000, 2000, 5000, 10000, 25000, 50000, 100000]) AS esik
ORDER BY esik;


-- ---------------------------------------------------------------------------
-- D. Tek seferlik (singleton) unvanlar - uzun kuyruk ne kadar buyuk?
-- ---------------------------------------------------------------------------
WITH roles AS (
  SELECT TRIM(LOWER(e.role)) AS r
  FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
  UNNEST(employments) e WHERE e.role IS NOT NULL
),
freq AS (SELECT r, COUNT(*) n FROM roles GROUP BY r)
SELECT
    COUNTIF(n = 1)                              AS bir_kez_gecen,
    COUNTIF(n BETWEEN 2 AND 9)                  AS az_gecen,
    COUNTIF(n >= 10)                            AS sik_gecen,
    ROUND(COUNTIF(n = 1) / COUNT(*), 3)         AS singleton_orani,
    ROUND(AVG(LENGTH(r)), 1)                    AS ort_uzunluk,
    COUNTIF(LENGTH(r) > 100)                    AS cok_uzun_supheli
FROM freq;


-- ---------------------------------------------------------------------------
-- E. ⭐ KURUM KIMLIGI - kac kayit BEDAVA ROR kimligi tasiyor?
--    Tasiyorsa isim eslestirmeye hic gerek yok.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.disambiguated_organisation_source)  AS kaynak,
    COUNT(*)                                    AS kayit,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)  AS oran
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e
GROUP BY kaynak ORDER BY kayit DESC;


-- ---------------------------------------------------------------------------
-- F. ⚠️ VISIBILITY - pazarlama icin sadece PUBLIC kullanilabilir.
--    PUBLIC olmayan oran yuksekse hacim beklentisi dusmeli.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.visibility)                         AS gorunurluk,
    COUNT(*)                                    AS kayit,
    COUNT(DISTINCT r.snid)                      AS kisi,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)  AS oran
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
GROUP BY gorunurluk ORDER BY kayit DESC;


-- ---------------------------------------------------------------------------
-- G. Guncel vs gecmis gorev (librarian / faculty_head current_only icin)
-- ---------------------------------------------------------------------------
SELECT
    e.full_end_date IS NULL                     AS guncel_gorev,
    COUNT(*)                                    AS kayit,
    COUNT(DISTINCT r.snid)                      AS kisi
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
GROUP BY guncel_gorev;


-- ---------------------------------------------------------------------------
-- H. En sik 100 unvan - insan review kuyrugunun on izlemesi
-- ---------------------------------------------------------------------------
SELECT
    TRIM(LOWER(e.role))     AS unvan,
    COUNT(*)                AS kayit,
    COUNT(DISTINCT r.snid)  AS kisi
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
WHERE e.role IS NOT NULL
GROUP BY unvan ORDER BY kayit DESC LIMIT 100;
