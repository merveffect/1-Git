/*
    ILK CALISTIRILACAK SORGU.
    Sozlugun ne kadar buyuk olacagini ve maliyeti belirler.
    Ciktiyi paylas - embedding maliyeti ve sure tahmini buradan cikar.
*/
SELECT
    COUNT(*)                                            AS toplam_kayit,
    COUNT(DISTINCT snid)                                AS kisi,
    COUNT(DISTINCT LOWER(TRIM(orcid_role)))             AS farkli_unvan,
    COUNT(DISTINCT LOWER(TRIM(orcid_organisation)))     AS farkli_kurum,
    COUNT(DISTINCT LOWER(TRIM(orcid_department)))       AS farkli_departman,
    COUNTIF(orcid_role IS NULL)                         AS unvan_bos,
    COUNTIF(orcid_department IS NULL)                   AS departman_bos
FROM `researcher-360-prod-e7fd74be.researcher_profiles.v_orcid_researchers`;

/* En sik 50 unvan ve kumulatif kapsama - insan review kuyrugunun on izlemesi */
-- SELECT
--     LOWER(TRIM(orcid_role))                                   AS title,
--     COUNT(*)                                                  AS freq,
--     SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC)
--       / SUM(COUNT(*)) OVER ()                                 AS cumulative_coverage
-- FROM `researcher-360-prod-e7fd74be.researcher_profiles.v_orcid_researchers`
-- WHERE orcid_role IS NOT NULL
-- GROUP BY title ORDER BY freq DESC LIMIT 50;
