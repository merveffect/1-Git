{{ config(materialized='view') }}

/*
    HAM KATMAN - orcid_researchers

    Tek isi: kaynagi oldugu gibi getirmek + GORUNURLUK FILTRESI.

    Public olmayan veriyi hicbir yerde kullanmayacagiz. O yuzden filtreyi
    tek sefer burada uyguluyoruz; ustteki modellerin hicbiri visibility
    bilmek zorunda degil.

    ORCID'de gorunurluk KAYIT bazinda: ayni kisinin bir isi PUBLIC,
    digeri PRIVATE olabilir. O yuzden dizileri yeniden kuruyoruz -
    kisiyi degil, kaydi eliyoruz.
*/

{% set public_only = var('public_visibility_only', true) %}

select
    snid,
    orcid_id,
    created_at,
    last_updated_at,
    name,
    biography,
    country_codes,
    keywords,

    {% if public_only %}
    -- sadece PUBLIC kayitlar kalir, dizi yapisi korunur
    array(select e from unnest(employments)  e where upper(e.visibility) = 'PUBLIC') as employments,
    array(select d from unnest(educations)   d where upper(d.visibility) = 'PUBLIC') as educations,
    array(select p from unnest(publications) p where upper(p.visibility) = 'PUBLIC') as publications,
    array(select m from unnest(emails)       m where upper(m.visibility) = 'PUBLIC') as emails,
    array(select v from unnest(peer_reviews) v where upper(v.visibility) = 'PUBLIC') as peer_reviews
    {% else %}
    employments,
    educations,
    publications,
    emails,
    peer_reviews
    {% endif %}

from {{ source('researcher_profiles', 'orcid_researchers') }}
where snid is not null
