# Yeni Rol Ekleme

Tasarimin amaci: **yeni rol eklemek 2 dosya degisikligi olsun.**
Model dosyalarina, macro'lara, SQL'e DOKUNULMAZ.

---

## 1. `dbt/dbt_project.yml` -> `vars.roles` altina blok ekle

```yaml
    veterinarian:
      enabled: true
      label: 'Veterinarian'
      axis: profession                # profession | position
      description: >
        Veteriner hekim. Klinik pratik, hayvan sagligi arastirmasi.
        Bu metin LLM hakemine AYNEN gider - net ve sinirlari belirgin yaz.
      isco_groups: ['2250']
      weights:         {role: 0.60, org: 0.25, dept: 0.15}
      education_bonus: 0.20
      thresholds:      {confirmed: 0.60, probable: 0.30}
      current_only:    false
      # parent: hcp                   # varsa ebeveyn role de roll-up olur
      # parent_bucket: PRACTITIONER
```

## 2. `dbt/seeds/role_anchors.csv` -> anchor satirlari ekle

En az 10-15 `include`, birkac `exclude`. Birden fazla dilde yaz.

```csv
veterinarian,veterinarian,include,en,
veterinarian,veterinary surgeon,include,en,
veterinarian,tierarzt,include,de,
veterinarian,veteriner hekim,include,tr,
veterinarian,veterinary nurse,exclude,en,ayri meslek
```

Opsiyonel: `org_type_scores.csv`, `dept_signals.csv`, `education_signals.csv`
icin de satir ekleyebilirsin. Eklemezsen o bilesen 0 skor alir.

## 3. Calistir

```bash
dbt seed
dbt run --select int_anchor_terms+
```

Sadece yeni anchor'lar embed edilir (incremental). Mevcut 50.000 unvanin
embedding'i tekrar hesaplanmaz.

## 4. Kontrol et

```sql
SELECT * FROM marts.rpt_title_review_queue
WHERE role_key = 'veterinarian' ORDER BY frequency DESC LIMIT 100;
```

En sik gecen 100 unvani gozden gecir, hatalilari
`seeds/role_title_overrides.csv`'ye yaz, `dbt seed && dbt run -s dim_title_role+`.

---

## Rolu kapatmak

`enabled: false`. **Silme** - gecmis skorlar ve bloklar korunur.
Kapatilan rol butun donguelerden otomatik duser.

## Kalibrasyon

| Belirti | Cozum |
|---|---|
| Cok fazla yanlis pozitif | `thresholds.confirmed` yukselt VEYA `exclude` anchor ekle |
| Cok az kisi yakalaniyor | `include` anchor cesitlendir (dil, kisaltma, varyant) |
| Kurum yanlis agirlikta | `org_type_scores.csv` duzenle |
| Unvan dogru ama skor dusuk | `weights.role` yukselt |
