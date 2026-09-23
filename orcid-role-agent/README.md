# ORCID Role Agent

ORCID employment/education verisinden **rol bazli audience** uretir.
Mevcut HCP Phase-1/Phase-2 pipeline'inin genellestirilmis hali: HCP'ye ozel
elle yazilmis regex yerine, herhangi bir rol icin calisan tek bir boru hatti.

Cikti: `snid` bazinda **multi-label** rol etiketleri + skor + kanit + consent.

---

## Temel fikir

204.000 kisiyi siniflandirmaya calismiyoruz. **Benzersiz unvanlari**
siniflandiriyoruz - onlar cok daha az. Sonra kisilere JOIN atiyoruz.

```
204.000 kisi   -> her calistirmada AI = pahali, yavas, tekrarlanamaz
 ~50.000 unvan -> BIR KEZ AI        = ucuz, hizli, deterministik
```

AI sadece **sozluk kurulurken** calisir. Sozluk hazir olduktan sonra
kisileri etiketlemek duz SQL JOIN'dir.

---

## Roller

Rol kayit defteri: `dbt/dbt_project.yml` -> `vars.roles`

| role_key | eksen | current_only | not |
|---|---|---|---|
| `hcp` | meslek | hayir | bucket: PRACTITIONER / HCP_RESEARCHER / ADMINISTRATOR |
| `pharmacist` | meslek | hayir | **ayrica** `hcp` / PRACTITIONER olarak roll-up olur |
| `librarian` | meslek | **evet** | kurumsal satis audience'i; guncel gorev sart |
| `researcher` | pozisyon | hayir | **tum alanlar** - saglikla sinirli degil |
| `faculty_head` | pozisyon | **evet** | gecici gorev; sadece guncel kayit |
| `lecturer` | pozisyon | - | `enabled: false` - sonra eklenecek |

Bir kisi birden fazla rol tasiyabilir. `Professor of Cardiology, Head of
Department` -> `hcp` + `researcher` + `faculty_head`.

Yeni rol eklemek icin: [docs/ADDING_A_ROLE.md](docs/ADDING_A_ROLE.md)

---

## Boru hatti

```
staging/          ham ORCID + ROR eslestirmesi, normalize edilmis metin
   |
dictionary/       ⭐ SOZLUK  (AI burada, sadece burada)
   |  int_title_distinct      benzersiz unvan + frekans
   |  int_anchor_terms        rol basina anchor'lar (seed + ESCO)
   |  int_*_embeddings        ML.GENERATE_EMBEDDING   (unvan basina 1 kez)
   |  int_title_role_match    VECTOR_SEARCH -> benzerlik
   |  int_title_role_judged   AI.GENERATE_BOOL -> sadece belirsizler
   |  dim_title_role          ⭐ unvan x rol sozlugu
   |
scoring/          ⭐ int_employment_scored -> fct_researcher_roles
   |                 (snid x role_key x score x label)
   |
presentation/     dim_researcher_role_flags   (kisi basina genis gorunum)
                  fct_role_audience           (consent ile audience)
                  fct_role_audience_summary   (bulunan / ulasilabilir)
                  rpt_title_review_queue      (insan review kuyrugu)
                  ⭐ fct_braze_contact_roles  (Braze data contract ciktisi)
```

### Karar kademeleri

| Benzerlik | Karar | Maliyet |
|---|---|---|
| exclude anchor daha yakin | `REJECTED_EXCLUSION` | bedava |
| `>= 0.90` | `AUTO_ACCEPT` | bedava |
| `0.55 - 0.90` | `NEEDS_JUDGE` -> Gemini | ucuz |
| `< 0.55` | `REJECTED_LOW_SIMILARITY` | bedava |

Insan karari (`seeds/role_title_overrides.csv`) her zaman ezer.

> Institution matching'de 1.0 confidence kullanilmisti - orada dogruydu,
> cunku kurumun canonical hali **tek** bir seydir. Rol siniflandirmada
> tek dogru cevap yok, o yuzden kademeli gidiyoruz.

---

## Kurulum

```bash
# 1. Vertex AI baglantisi (bir kez, altyapi yetkisi gerekir)
./dbt/setup/01_vertex_setup.sh
# 2. Uzak modeller - BigQuery'de calistir
#    dbt/setup/02_create_models.sql

# 3. dbt
cp dbt/profiles.yml.example ~/.dbt/profiles.yml   # duzenle
cd dbt && dbt deps && dbt seed && dbt run
```

### Once yapilmasi gerekenler

- [ ] `dbt_project.yml` -> `ror_mapping_table` doldur
- [ ] `models/staging/*.sql` kolon adlarini `bq show --schema` ile dogrula
- [ ] `analyses/00_source_profile.sql` calistir - sozluk boyutunu ogren
- [ ] ESCO indir, yukle, `use_esco: true` yap (opsiyonel ama tavsiye edilir)

---

## Kullanim

```sql
-- Almanya'daki HCP arastirmacilar, pazarlanabilir
SELECT a.snid, a.evidence_title, a.evidence_org
FROM marts.fct_role_audience a
JOIN marts.dim_researcher_role_flags f USING (snid)
WHERE f.is_hcp AND f.is_researcher
  AND a.country_code = 'DE'
  AND a.is_marketable;

-- Her rol icin ulasilabilirlik ozeti
SELECT * FROM marts.fct_role_audience_summary ORDER BY marketable DESC;
```

---

## Dogrulama

Mevcut `hcp_identified_phase1` ciktisi bu pipeline'in **regression testi**.
Ayni 204.130 kisi uzerinde ayni etiketleri uretebiliyorsa sistem
dogrulanmistir. `dbt/analyses/` altina karsilastirma sorgusu eklenecek.

---

## AI agent (Faz 2 - henuz yok)

dbt boru hatti **tek basina calisir**; agent zorunlu degil. Agent iki is yapar:

1. **Sorgulama** - dogal dilde istek -> dogru `role_key` + filtreler -> SQL
2. **Yeni rol ekleme asistani** - "lecturer ekle" -> ESCO'dan anchor toplar,
   veride ne eslestigini gosterir, YAML + seed satirlarini yazar, **onayini
   ister**. Kendi basina calistirmaz.

Agent 204.000 satira dokunmaz; sadece sozlugu ve mart'lari okur.


---

## Braze data contract

`marts.fct_braze_contact_roles` - bir satir = bir contact.

| alan | ornek |
|---|---|
| `contact_email` | xx@xcv.com |
| `snid` | 1233 |
| `role_inferred` | `['Head of Faculty', 'Healthcare Professional']` |
| `role_detailed_inferred` | `['Head of Faculty - University', 'Healthcare Professional - Practitioner']` |
| `role_inferred_data_source` | `['Orcid', 'Orcid + Web scraping']` |
| `role_inferred_data_source_last_updated` | `[ts, ts]` |

### Dizi hizalamasi

Dort dizi **pozisyonel** olarak hizali olmak zorunda: `role_inferred[i]`
ile `role_inferred_data_source[i]` ayni role ait olmali. Braze bu
hizalamayi dogrulayamaz - bozulursa yanlis kisi yanlis segmente duser
ve kimse fark etmez.

Bu yuzden dort dizi de **tek bir siralanmis kaynaktan**, ayni `ORDER BY`
ile turetilir. Ayrica her build'de iki test kosar:

- `assert_contract_arrays_aligned` - dizi uzunluklari esit mi
- `assert_detailed_prefix_matches_role` - `detailed[i]` gercekten
  `role_inferred[i]` ile mi basliyor

Kanonik form `roles_struct` kolonunda da tutulur (dizi yerine nesne
dizisi) - hata ayiklarken buraya bak.

### Ayarlar - `dbt_project.yml` -> `vars.contract`

| ayar | secenekler | not |
|---|---|---|
| `consent_basis` | `marketing_opt_in` / `legitimate_interest` / `both` | DPO karari; varsayilan guvenli secenek |
| `include_labels` | `['CONFIRMED']` / `+ 'PROBABLE'` | PROBABLE eklenirse hacim ~2x |
| `array_order` | `alphabetical` / `score` | contract alfabetik diyor; `score` daha kullanisli |
| `detail_separator` | `' - '` | |

### Gorunen isimler

`role_inferred` degerleri `vars.roles.<rol>.display_name`'den gelir ve
**MPC 'role' alanindaki yazimla birebir ayni olmali**. Farkli yazim =
segmentlerin ikiye bolunmesi. Degistirmeden once MPC'deki degerleri
dogrula.

### Yeni veri kaynagi eklemek

`vars.sources` altina blok ekle (`web_scraping: {enabled: true}`),
`fct_researcher_roles`'a UNION ALL ile besle. Contract kirilmaz -
`role_inferred_data_source` otomatik `'Orcid + Web scraping'` uretir.
