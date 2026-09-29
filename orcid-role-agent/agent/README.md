# Agent katmani (Faz 2 - henuz gercek degil)

`demo_agent.py` ogrenme amacli. Sahte veri kullanir, BigQuery'ye
baglanmaz. Amaci tek bir seyi gostermek: **agent bir urun degil, bir
dongu.**

## Calistir

```bash
pip install -r requirements.txt
gcloud auth application-default login
export GCP_PROJECT=researcher-360-prod-e7fd74be
export GCP_LOCATION=europe-west1     # Vertex baglantinla AYNI bolge

python demo_agent.py "hangi roller var?"
python demo_agent.py "almanyadaki hcp kac kisi, kacina ulasabiliriz?"
python demo_agent.py "en buyuk audience hangi rolde?"
```

Ikinci ve ucuncu soruda ciktinin sonundaki **[modelin kendi kararlari]**
bolumune bak. Modelin hangi araci hangi sirayla cagirdigini goreceksin -
o sirayi biz yazmadik. Agent olan kisim orasi.

> Bu sandbox'ta GCP kimlik bilgisi olmadigi icin test EDILEMEDI.
> Ilk calistirmada SDK surum farkindan kaynakli kucuk bir duzeltme
> gerekebilir.

## Gercek agent'ta olacak araclar

| arac | ne yapar |
|---|---|
| `list_roles()` | kayit defterindeki rolleri dondurur |
| `search_titles(query)` | sozlukte VECTOR_SEARCH ile unvan arar |
| `preview_role(role_key)` | bir rolun hangi unvanlari kapsadigini gosterir |
| `count_audience(role, filters)` | identified / in_cdp / marketable sayilari |
| `export_audience(role, filters)` | SNID listesi cikarir |
| `propose_new_role(description)` | ESCO'dan anchor toplar, YAML taslagi yazar |
| `explain_person(snid)` | bu kisi neden bu rolde - kanit zinciri |

Hepsi BigQuery'deki mart tablolarini **okur**. Agent 204.000 satirlik
veriye dokunmaz, yazma yetkisi olmaz.
