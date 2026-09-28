/*
    ============================================================================
    ALAN DOLULUK ANALIZI
    ============================================================================
    Tasarim kararlarindan ONCE calistirilmasi gereken sorgular.
    "Hangi alan ne kadar dolu, hangisine guvenebiliriz?"

    Cikti alindiktan sonra karar verecegimiz seyler:
      - department_name bos ise dept agirligi (0.20) anlamsiz -> yeniden dagit
      - ROR kapsamasi dusukse isim eslestirme sart, yuksekse gereksiz
      - CDP ortakligi dusukse audience beklentisi bastan dusmeli
      - publications doluysa Phase-2 sinyalleri ORCID'den uretilebilir
    ============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. KISI SEVIYESI - hangi dizi kac kiside dolu?
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                             AS kisi,
    COUNTIF(ARRAY_LENGTH(employments) > 0)               AS employment_var,
    COUNTIF(ARRAY_LENGTH(educations)  > 0)               AS education_var,
    COUNTIF(ARRAY_LENGTH(publications)> 0)               AS publication_var,
    COUNTIF(ARRAY_LENGTH(keywords)    > 0)               AS keyword_var,
    COUNTIF(ARRAY_LENGTH(peer_reviews)> 0)               AS peer_review_var,
    COUNTIF(ARRAY_LENGTH(emails)      > 0)               AS email_var,
    ROUND(COUNTIF(ARRAY_LENGTH(employments) > 0) / COUNT(*), 3)  AS employment_orani
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- ---------------------------------------------------------------------------
-- 2. ⭐ EMPLOYMENT ALT ALANLARI - skorlamanin dayandigi alanlar
--    role 0.50 / organisation 0.30 / department 0.20 agirliginda.
--    department cogunlukla bossa o agirlik bosa gidiyor demektir.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS employment_kaydi,
    ROUND(COUNTIF(e.role              IS NOT NULL) / COUNT(*), 3) AS role_dolu,
    ROUND(COUNTIF(e.organisation_name IS NOT NULL) / COUNT(*), 3) AS organisation_dolu,
    ROUND(COUNTIF(e.department_name   IS NOT NULL) / COUNT(*), 3) AS department_dolu,
    ROUND(COUNTIF(e.organisation_address_country_code IS NOT NULL) / COUNT(*), 3) AS ulke_dolu,
    ROUND(COUNTIF(e.full_start_date   IS NOT NULL) / COUNT(*), 3) AS baslangic_dolu,
    ROUND(COUNTIF(e.disambiguated_organisation_id IS NOT NULL) / COUNT(*), 3) AS kurum_kimligi_dolu,
    -- uc alan birden dolu olan kayit orani: tam skorlanabilir kayitlar
    ROUND(COUNTIF(e.role IS NOT NULL
              AND e.organisation_name IS NOT NULL
              AND e.department_name IS NOT NULL) / COUNT(*), 3)  AS uc_alan_birden
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e;


-- ---------------------------------------------------------------------------
-- 3. EDUCATION ALT ALANLARI
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                      AS education_kaydi,
    ROUND(COUNTIF(d.degree            IS NOT NULL) / COUNT(*), 3) AS degree_dolu,
    ROUND(COUNTIF(d.department_name   IS NOT NULL) / COUNT(*), 3) AS department_dolu,
    ROUND(COUNTIF(d.organisation_name IS NOT NULL) / COUNT(*), 3) AS organisation_dolu
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(educations) d;


-- ---------------------------------------------------------------------------
-- 4. ⭐ KURUM KIMLIGI KAYNAGI - kac kayit BEDAVA ROR kimligi tasiyor?
--    ROR yuksekse isim eslestirmeye gerek yok.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.disambiguated_organisation_source)      AS kimlik_kaynagi,
    COUNT(*)                                        AS kayit,
    COUNT(DISTINCT e.organisation_name)             AS farkli_kurum,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)      AS oran
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e
GROUP BY kimlik_kaynagi
ORDER BY kayit DESC;


-- ---------------------------------------------------------------------------
-- 5. ⚠️ GORUNURLUK - PUBLIC disi veriyi kullanmayacagiz.
--    PUBLIC orani dusukse hacim beklentisi bastan dusmeli.
-- ---------------------------------------------------------------------------
SELECT
    UPPER(e.visibility)                             AS gorunurluk,
    COUNT(*)                                        AS kayit,
    COUNT(DISTINCT r.snid)                          AS kisi,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)      AS oran
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.employments) e
GROUP BY gorunurluk ORDER BY kayit DESC;

-- PUBLIC employment kaydi HIC olmayan kisi sayisi (tamamen disarida kalanlar)
SELECT
    COUNT(*)                                                    AS kisi,
    COUNTIF((SELECT COUNT(*) FROM UNNEST(employments) e
             WHERE UPPER(e.visibility) = 'PUBLIC') = 0)         AS public_employment_yok
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`;


-- ---------------------------------------------------------------------------
-- 6. ⭐ CDP ORTAKLIGI - kac ORCID kisisine gercekten ulasabiliriz?
--    Phase-1'de bu oran %21'di. Audience beklentisini bu belirliyor.
-- ---------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.snid)                                      AS orcid_kisi,
    COUNT(DISTINCT c.snid)                                      AS cdp_de_var,
    COUNT(DISTINCT IF(c.mkt_pref_opt_in,    c.snid, NULL))      AS marketing_izinli,
    COUNT(DISTINCT IF(c.advertising_opt_in, c.snid, NULL))      AS reklam_izinli,
    ROUND(COUNT(DISTINCT c.snid) / COUNT(DISTINCT o.snid), 3)   AS cdp_kapsamasi
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` o
LEFT JOIN `researcher-360-prod-e7fd74be.researcher_profiles.audience_builder_big` c
       ON o.snid = c.snid;


-- ---------------------------------------------------------------------------
-- 7. DIL DAGILIMI - cok dilli model gercekten gerekli mi?
--    Latin disi karakter iceren unvanlarin orani.
-- ---------------------------------------------------------------------------
SELECT
    CASE
        WHEN REGEXP_CONTAINS(e.role, r'[\p{Han}\p{Hiragana}\p{Katakana}]') THEN 'CJK'
        WHEN REGEXP_CONTAINS(e.role, r'[\p{Cyrillic}]')                    THEN 'Kiril'
        WHEN REGEXP_CONTAINS(e.role, r'[\p{Arabic}]')                      THEN 'Arapca'
        WHEN REGEXP_CONTAINS(e.role, r'[äöüßàâçéèêëñõçğışİÖÜÇ]')           THEN 'Latin-aksanli'
        ELSE 'Latin-sade'
    END                                             AS karakter_seti,
    COUNT(*)                                        AS kayit,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3)      AS oran
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers`,
UNNEST(employments) e
WHERE e.role IS NOT NULL
GROUP BY karakter_seti ORDER BY kayit DESC;


-- ---------------------------------------------------------------------------
-- 8. PUBLICATIONS - Phase-2 sinyalleri ORCID'den uretilebilir mi?
--    (Faz 6 icin; CDP'de olmayan %79'u kurtarabilir)
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS publication_kaydi,
    COUNT(DISTINCT r.snid)                                      AS yayini_olan_kisi,
    ROUND(COUNTIF(p.journal_title IS NOT NULL) / COUNT(*), 3)   AS dergi_adi_dolu,
    ROUND(COUNTIF(p.doi IS NOT NULL) / COUNT(*), 3)             AS doi_dolu,
    COUNT(DISTINCT p.journal_title)                             AS farkli_dergi
FROM `researcher-360-prod-e7fd74be.researcher_profiles.orcid_researchers` r,
UNNEST(r.publications) p;
