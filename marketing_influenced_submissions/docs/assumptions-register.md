# MIS dbt migration — assumptions register (SN review)

This file lists every assumption ported from the Colab pipeline into the dbt models
that Springer Nature must confirm. Each assumption is a dbt `var` in
[dbt_project.yml](../dbt_project.yml) with a Colab-faithful default, or an inline
`-- SN-REVIEW:` comment in the model. Reviewers can change behaviour by overriding
the var — no SQL edit needed.

Scope of this pass: **SNAPP end-to-end (Phases 1B-8)** in the dev dataset
`dev_RM_Submissions_mktg_infl`. EJP/EM are a follow-up. Nothing is promoted to prod.

Legend: [DEFAULT] = current model behaviour · [VERIFIED] = checked on BigQuery · [CONFIRMED] = SN confirmed in writing.

## A. Identity resolution (Phase 1B)

| # | Var / decision | Default | Rationale / evidence | SN question |
|---|---|---|---|---|
| A1 | `identity_include_cdp_new` | true | `mis_2_email_clientid_new` refreshed 2026-07-06 [VERIFIED]; active monthly | [CONFIRMED] Giorgia 2026-07-16 — active |
| A2 | `identity_include_ga4_sap` | true | GA4+SMC path; **deprecated from June 2026** (Giorgia) but kept for historical mappings | [CONFIRMED] Giorgia 2026-07-16 — deprecated, keep in union |
| A3 | `identity_include_braze` | true | `braze_ga4_email` active monthly | [CONFIRMED] Giorgia 2026-07-16 — active |
| A4 | `identity_include_cdp_legacy` | **true** | `mis_2_email_clientid` frozen 2025-09-04 [VERIFIED]; historical mappings still useful | [CONFIRMED] Giorgia 2026-07-16 — keep in union despite no refresh |
| A5 | `identity_include_cdp_user_traits` | **true** | `mis_2_email_clientid_cdp` frozen 2025-02-05 [VERIFIED]; historical mappings still useful | [CONFIRMED] Giorgia 2026-07-16 — keep in union |
| A6 | `identity_include_snid` | **true** | `mis_1_email_clientid` / `mis_1_snid_clientid` stopped Oct 2025 (Giorgia); part of the final union but not refreshed | [CONFIRMED] Giorgia 2026-07-16 — keep in union; process not active |
| A7 | `identity_conflict_strategy` | keep_all | Keep all (email, client_id) pairs — the CDP can map multiple GA4 client_ids to one email, so all mappings are wanted | [CONFIRMED] Giorgia 2026-07-16 — no priority, keep all |
| A8 | GA client_id trim | `substr(value,7,30)` | Colab `_new` uses 30; deprecated `_cdp` used 21 | Confirm 30 is correct |
| A9 | Power author labels | `['d. Power author (21+)','Power author']` | Colab CASE on `Total_AMT_5yr_Author_Group` | Confirm label set |
| A10 | `identity_extract_from_prod` | **true** | `int_ga4_sap_ids` / `int_braze_cep_ids` read prod's accumulated maps (`mis_2_sap_ids_ga4_2` / `braze_cep_ids`) instead of scanning raw GA4 events for the processing window only. Full-history mapping coverage; closes the email_rm gap (see reconciliation). Same pattern as `ga_extract_from_prod`. `false` = Colab-faithful windowed raw-events scan (undercounts in a single-month dev build). | Confirm reading prod identity maps is acceptable for the dev validation build |

## B. Submissions (Phase 2)

| # | Decision | Default | SN question |
|---|---|---|---|
| B1 | Author-role inclusion filter in `int_sub_details` | coauthor OR corresp OR (ga_submitter-only) | Confirm the "real author" rule; ≈98 EM subs dropped (null roles) |
| B2 | SNAPP submissions source | `snapp_submission_funnel_new` where `snapp_process='snapp_success'` | Confirm |

## C. GA4 attribution (Phases 3-4)

| # | Var / decision | Default | SN question |
|---|---|---|---|
| C1 | `attribution_window_days` | 180 | Confirm 6-month = 180 days, event strictly before submission |
| C2 | `ga_lookback_months` | 6 | Confirm GA pull window |
| C3 | `google_multichannel_threshold` | 0.8 | Confirm >80% allocation + tie-break (both can be 1) |
| C4 | Channel groupings source | `ae_metadata.channel_groupings_native` | **Confirmed** [CONFIRMED] — Anup Mane (2026-07-15): correct cross-project source; AE team owns table; sheet updated quarterly. Open: native refresh job cadence (daily copy vs on-change); confirm `journal_table_native` same pattern |
| C5 | RM workspace filter | `%Authors%`/`%India%`/`hpaut`/`letpb`/`naver` | Confirm |

## D. Combination + collections (Phases 5-6)

| # | Var / decision | Default | SN question |
|---|---|---|---|
| D1 | `gr_*` genuine-researcher thresholds | sessions (1,360), pv/session (1,100) | Confirm; imprint-match stays disabled |
| D2 | `repeated_author_full_history` | **true** | [CONFIRMED] Giorgia 2026-07-16 — lookback must span full history to the submission date (=1 if any author previously submitted); one flag per submission |
| D3 | `collection_email_types` (fixed pivot) | 5 known types | Colab pivot is dynamic (EXECUTE IMMEDIATE); dashboard hardcodes 5 — fixed list OK? |
| D4 | Collections input source | native `mis_input_data_collections_emails_2` | Sheets-backed base blocked by Drive scope; confirm source for prod |
| D5 | `is_in_collection` point-in-time vs latest-view | [OPEN - later] Derived from `collection_id` in the submissions "latest view" (mutable). Prod `mis_2_subs_all` froze it at build date; dev re-derives from current state -> May 2026 dev 24,388 vs prod 25,496 (bidirectional churn: 1,351 lost a collection since prod's build, 243 gained one; dev matches the source's current state). NOT a bug/windowing/join issue. | Should `is_in_collection` be point-in-time (frozen at first processing month, like prod today) or latest-view? Decides whether we snapshot the flag per month (dbt snapshot / seed historical months) or keep re-deriving. Deferred. |

## E. Dashboards + channel planning (Phases 7-8)

| # | Decision | Default | SN question |
|---|---|---|---|
| E1 | Dashboard column contracts | column-for-column parity with prod `mis_2_subs_all` / `mis_2_subs_coll_2` / `_4_v8` | Confirm exact contract before promotion |
| E1a | `repeated_author_flag` as a dashboard output | [CONFIRMED] Giorgia 2026-07-16 lists `repeated_author_flag` as a direct dashboard table (with `mis_2_subs_all`, `_4_v8`, + the two EM tables). Exposed as a `presentation` model (thin contract over `int_repeated_author_flag`; schema = prod: internal_submission_id STRING, source_system STRING, month DATE, repeated_author INT). May-2026 dev vs prod: rows 340,310 vs 340,880 (−0.17%), repeated rate 0.9502 vs 0.9501 (≈0); rows = distinct submission in both (one flag per submission holds). | Line-by-line check vs Giorgia's refreshed Colab still advisable, but numbers already match prod |
| E2 | `snapp_regional_clusters` (region, country_grouping) | Sheets-backed external table — Drive scope BLOCKED; join gated by `enable_regional_clusters` var (default false -> null in dev) | Need native/seed equivalent |
| E3 | `channel_planning_multi_threshold` | 0.5 | Confirm Phase 8 uses 0.5 (vs 0.8 main path) |
| E4 | `_3` accumulation idempotency | dbt incremental insert_overwrite by month (replaces Colab non-atomic INSERT) | Confirm month-grain replace is acceptable |
| E5 | `int_channel_planning_google_2` transform | Colab `mis_..._google_2` SQL not in export; approximated (channel_from_lookup -> main_channels, sub_channels null) | Provide/confirm exact Google planning channel mapping |
| E6 | Channel-planning run cadence | [CONFIRMED] Giorgia 2026-07-16 — `mis_3_..._4_v8` (+ `_ejp_em`) must be refreshed over the FULL historical dataset every month (journal status can change retroactively, e.g. a January submission accepted in June). Models are `table` (full rebuild, no incremental staleness) but windowed by `mis_start_date`/`mis_end_date`; run the v8 chain with a full-history window (e.g. `mis_start_date=2024-07-01`). The rest of the pipeline stays monthly-incremental (past months static). | None — operational note |
| E7 | `journal_table` -> `journal_catalog` | [PENDING] Giorgia 2026-07-16 — plans to replace `journal_table_native` (Strategy-team Google Sheet, manual business_model) with `braze-3f553fdf.prod_cdi_presentation.journal_catalog` once she verifies equivalence. Current dep on `journal_table_native` valid for now. | Confirm timing + run equivalence check before switching |

## Build / materialization status (dev, 2026-07-14)

Two phases were built and reconciled against prod; the GA4-dependent phases are
written, statically validated (`dbt compile`: 60 models / 50 tests / 110 checks all
pass) but NOT materialised yet, pending client sign-off on BigQuery scan cost.

| Phase | Models | Status |
|---|---|---|
| 0 / 1A | staging, int_authors, int_repeated_author_flag | Built (pre-existing) |
| 1B | int_email_clientid* , int_authors_enriched, int_power_author_flag | Built + reconciled |
| 2 | int_subs_unique, int_subs_clientids_ga, int_sub_details | Built + reconciled |
| 5 (non-GA) | int_country, int_snapp_otr | Built |
| 3 | int_ga_data*, int_ga_data_channel, int_ga_activity* | Built (GA extract from prod) |
| 4 | int_google_auto_* | Built (GA extract from prod) |
| 5 (GA) | int_genuine_users, int_trackable_subs, int_subs_ga_combined, int_subs_all_inter | Built |
| 6 | int_coll_email_1, int_coll_email_pivot, int_subs_coll | Built |
| 7 | mis_2_subs_all, mis_2_subs_coll_2 | Built + reconciled |
| 8 | int_channel_planning_*, mis_3_..._4_v8 | Built (region gated by E2) |

### Cost note (GA4 scans)

The GA4 attribution phases need ≈7 months of GA4 raw events (May submissions attributed
up to 180 days back). Dry run of the manual-campaign extract = **4.29 TB (≈$27)**; the
Google auto-tag extract is similar (≈$27); full Phase 3-8 materialisation ≈**$55-60** of
BigQuery, once. In prod this is cheap because it accumulates one month at a time
(≈$4/month). The GA event scanners are tagged `ga_expensive`; the whole GA chain is
tagged `ga` (build with `dbt build --select tag:ga` once signed off).

**Cheaper dev path (`ga_extract_from_prod`, default `true`):** instead of re-scanning
raw GA4 events, `int_ga_data` / `int_google_auto_1` read the already-accumulated prod
extracts `mis_2_ga_data` (2.3 TB unpartitioned, ≈$14.5 to slice) and `mis_2_google_auto_1`
(≈$0.09). These extracts are **identity-independent** (user x event x campaign only), so
the new dev identity resolution still drives every downstream submission join. Net one-off
dev cost drops from ≈$55 to **≈$15**. Set `ga_extract_from_prod: false` for a fully
Colab-faithful raw-events rebuild. SN-REVIEW: confirm prod extract is an acceptable input
for the dev validation build.

**Identity extract source (`identity_extract_from_prod`, default `true`):** the two active
GA4-derived identity extracts read prod's accumulated maps instead of scanning raw GA4 events
for the processing window only:
- `int_ga4_sap_ids` reads `mis_prod.mis_2_sap_ids_ga4_2` (2.26M rows, ≈137MB) — column
  `sap_outbound_id_36` (already the 36-char id that `int_ga4_sap_clientid` joins on), aliased to
  `sap_outbound_id`.
- `int_braze_cep_ids` reads `mis_prod.braze_cep_ids` (1.17M rows, ≈57MB).

Both maps are tiny (<0.2 GB total, ≈$0.001 to scan). All accumulated pairs are stamped with the
processing month partition; downstream `int_*_clientid` dedups via `group by`, correct for the dev
single-month reconciliation. This is the identity analogue of `ga_extract_from_prod` and closes the
residual email_rm gap (see reconciliation). Set `identity_extract_from_prod: false` for a fully
Colab-faithful windowed identity extract (which undercounts email coverage in a single-month build).

## Reconciliation log (dev vs prod, May 2026)

Filled in as each phase is built and validated via the bigquery MCP.

| Phase | Model | dev | prod | delta | notes |
|---|---|---|---|---|---|
| 1A | int_authors distinct subs | 307,182 | 307,176 | +6 | pre-existing (data refresh) |
| 1B | int_authors_enriched distinct subs (May 2026) | 307,181 | 307,176 | +5 | matches 1A; data refresh |
| 1B | subs with non-null client_id (May 2026) | 253,366 | 258,974 | -5,608 (-2.2%) | cost of dropping deprecated identity branches (A4/A5/A6) — small at submission level |
| 1B | int_email_clientid rows / emails / cids | 11.86M / 3.96M / 11.35M | 13.43M / 4.49M / 12.67M | ≈-12% pairs | deprecated branches add ≈12% raw pairs but only 2.2% sub coverage |
| 2 | int_sub_details distinct subs (May 2026) | 307,181 | 307,176 | +5 | data refresh; submission-level parity holds |
| 2 | int_sub_details rows (May 2026) | 4.04M | 4.33M | -6.9% | fewer (sub,user) pairs from dropping deprecated multi-client_id fan-out |
| 3-7 | mis_2_subs_all submissions (May 2026) | 208,797 | 208,797 | 0 | spine exact once GA extract is shared |
| 3-7 | mis_2_subs_all trackable_sub | 169,397 | 169,785 | -388 (-0.23%) | genuine-researcher filter near-identical |
| 3-7 | mis_2_subs_all is_in_collection | 24,388 | 25,496 | -1,108 (-4.3%) | follows identity delta |
| 3-7 | mis_2_subs_all sea_rm_flag | 1,256 | 1,290 | -34 (-2.6%) | within identity-driven range |
| 3-7 | mis_2_subs_all email_rm_flag | 39,600 | 47,851 | -8,251 (-17.2%) | largest delta: email touchpoints matched via user_pseudo_id, so most sensitive to disabled deprecated identity branches |
| 3-7 | mis_2_subs_all external_display_rm_flag | 11,242 | 11,431 | -189 (-1.65%) | within range |
| 3-7 | mis_2_subs_all paid_social_rm_flag | 616 | 660 | -44 (-6.7%) | low base, identity-driven |

| 7 | mis_2_subs_coll_2 n_subs (May 2026) | 24,388 | 25,496 | -1,108 (-4.3%) | matches mis_2_subs_all is_in_collection; identity delta |
| 7 | mis_2_subs_coll_2 email_rm / email_col | 34,824 / 1,276 | 42,358 / 1,706 | -17.8% / -25.2% | collections-email most sensitive to disabled identity branches |
| 7 | mis_2_subs_coll_2 collections_activity | 1,291 | 1,722 | -25.0% | follows collections-email delta |
| 8 | mis_3_..._4_v8 rows / distinct subs (May 2026) | 155,661 / 82,964 | 189,977 / 86,580 | -18.1% / -4.2% | row-level (sub x touchpoint) more exposed than sub-level; identity-driven |
| 8 | mis_3_..._4_v8 out_to_review | 23,817 | 28,110 | -15.3% | follows row-level reduction |
| 8 | mis_3_..._4_v8 region not-null | 0 | 171,057 | E2 (expected) | region gated off in dev (snapp_regional_clusters Drive-blocked) — not a defect |

### After including the deprecated identity branches (Giorgia 2026-07-16, all identity_include_* = true)

Rebuilt the identity subtree + downstream. May 2026, `mis_2_subs_all` dev vs prod:

| Metric | dev (branches ON) | prod | delta | vs branches OFF |
|---|---|---|---|---|
| submissions | 208,797 | 208,797 | 0 | unchanged |
| trackable_sub | 170,473 | 169,785 | +688 (+0.4%) | 169,397 -> closer (now slightly above) |
| is_in_collection | 24,388 | 25,496 | -1,108 (-4.3%) | **unchanged** (identity-independent) |
| sea_rm_flag | 1,299 | 1,290 | +9 (+0.7%) | 1,256 -> closed |
| email_rm_flag | 40,546 | 47,851 | -7,305 (-15.3%) | 39,600 -> only marginally closed |
| external_display_rm_flag | 11,605 | 11,431 | +174 (+1.5%) | 11,242 -> closed |
| paid_social_rm_flag | 645 | 660 | -15 (-2.3%) | 616 -> closer |

**Revised read:** including the deprecated branches moved almost every channel to within ±2% of
prod (some now slightly above), but the **email gap barely moved (-17.2% -> -15.3%)**. Identity
coverage is therefore **not** the dominant driver of the email delta. The identity table did grow
(`int_email_clientid`: 11.86M -> **12.48M** pairs, 3.96M -> **4.14M** emails), but dev is still ≈7%
below prod (13.43M pairs / 4.49M emails). The residual is explained by the **ACTIVE** identity
branches, not the deprecated ones: `int_ga4_sap_ids` / `int_braze_cep_ids` scan only the processing
window of GA4 events, whereas prod has accumulated those GA4->SAP/CEP mappings over many months. So
to fully match prod's email coverage we would need to accumulate the active identity branches over
full history (the same pattern as `ga_extract_from_prod`), or read prod's accumulated identity
tables. Two residuals remain:
- **email_rm -15.3%**: driven by the windowed active identity branches (GA4->SAP/CEP), not the
  deprecated tables. Fix = accumulate identity over history, or read prod identity extracts.
- **is_in_collection -4.3%**: fully identity-independent (unchanged when branches flipped) — a
  collection-membership data/definition difference upstream, not an attribution issue.

SN-REVIEW: the deprecated branches are now IN the union per Giorgia; the residual email gap is a
separate matter (windowed active-identity accumulation), not the identity-inclusion decision.

### After reading prod's accumulated identity maps (`identity_extract_from_prod: true`, 2026-07-16)

Rebuilt `int_ga4_sap_ids+` and `int_braze_cep_ids+` (identity subtree + all downstream). The two
active GA4-derived extracts now read prod's cumulative maps instead of the single-month GA4 window.
May 2026, `mis_2_subs_all` dev vs prod:

| Metric | dev (from_prod) | prod | delta | vs windowed extract |
|---|---|---|---|---|
| submissions | 208,797 | 208,797 | 0 | unchanged |
| trackable_sub | 171,401 | 169,785 | +1,616 (+0.95%) | 170,473 -> now slightly above |
| is_in_collection | 24,388 | 25,496 | -1,108 (-4.3%) | **unchanged** (identity-independent) |
| sea_rm_flag | 1,310 | 1,290 | +20 (+1.6%) | 1,299 -> still ≈parity |
| email_rm_flag | 48,142 | 47,851 | **+291 (+0.61%)** | 40,546 -> **gap closed (was -15.3%)** |
| external_display_rm_flag | 11,694 | 11,431 | +263 (+2.3%) | 11,605 -> ≈parity |
| paid_social_rm_flag | 674 | 660 | +14 (+2.1%) | 645 -> now slightly above |

`int_email_clientid` pairs: dev **13.62M** vs prod 13.43M (**+1.4%**), up from 12.48M (was -7%). The
identity map now slightly *exceeds* prod because the full cumulative prod maps are combined with all
`identity_include_*` branches ON (and downstream dedups), which is expected and immaterial.

**Corrected read of the reconciliation.** The earlier hypothesis — that the email gap was mainly a
consequence of the disabled deprecated identity branches — was **wrong**. Flipping those branches on
barely moved email_rm (-17.2% -> -15.3%). The actual driver was the **windowed active identity
extracts**: `int_ga4_sap_ids` / `int_braze_cep_ids` scanned only the processing month of raw GA4
events, while prod accumulates those user_pseudo_id -> SAP/CEP mappings over full history. Reading
prod's accumulated maps (`identity_extract_from_prod: true`) closes the email_rm gap from **-15.3%
to +0.61%** and lifts `int_email_clientid` from -7% to +1.4% vs prod. This mirrors the
`ga_extract_from_prod` fix for the GA event extract.

**Only residual now:**
- **is_in_collection -4.3%**: fully identity-independent (unchanged across every identity experiment
  above — deprecated branches, then from_prod). This is a collection-membership data/definition
  difference upstream (`mis_input_data_collections_emails_2` / collections activity), not an
  attribution or identity-coverage issue. All identity-driven channel flags (email, sea, external
  display, paid social) are now within ±2.5% of prod, mostly slightly above.
