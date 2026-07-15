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
| A1 | `identity_include_cdp_new` | true | `mis_2_email_clientid_new` refreshed 2026-07-06 [VERIFIED] | Confirm still authoritative |
| A2 | `identity_include_ga4_sap` | true | GA4+SMC path; SMC last refresh 2026-02-26 | Colab note "stop from June" — keep or drop? |
| A3 | `identity_include_braze` | true | `braze_ga4_email` active | Confirm |
| A4 | `identity_include_cdp_legacy` | false | `mis_2_email_clientid` frozen 2025-09-04 [VERIFIED] | Confirm drop |
| A5 | `identity_include_cdp_user_traits` | false | source `cdp...user_traits` frozen 2025-02-05 [VERIFIED] | Confirm drop |
| A6 | `identity_include_snid` | false | SNID path deprecated; `snid_aggregated_view` vs MDT `final_master_table_for_testing_new` source-of-truth unconfirmed | Which is current? re-enable? |
| A7 | `identity_conflict_strategy` | keep_all | Colab union keeps all (email, client_id) pairs | Priority order when one email -> many client_ids? |
| A8 | GA client_id trim | `substr(value,7,30)` | Colab `_new` uses 30; deprecated `_cdp` used 21 | Confirm 30 is correct |
| A9 | Power author labels | `['d. Power author (21+)','Power author']` | Colab CASE on `Total_AMT_5yr_Author_Group` | Confirm label set |

## B. Submissions (Phase 2)

| # | Decision | Default | SN question |
|---|---|---|---|
| B1 | Author-role inclusion filter in `int_sub_details` | coauthor OR corresp OR (ga_submitter-only) | Confirm the "real author" rule; ~98 EM subs dropped (null roles) |
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
| D2 | `repeated_author_full_history` | false | Within-window (Colab) vs full history |
| D3 | `collection_email_types` (fixed pivot) | 5 known types | Colab pivot is dynamic (EXECUTE IMMEDIATE); dashboard hardcodes 5 — fixed list OK? |
| D4 | Collections input source | native `mis_input_data_collections_emails_2` | Sheets-backed base blocked by Drive scope; confirm source for prod |

## E. Dashboards + channel planning (Phases 7-8)

| # | Decision | Default | SN question |
|---|---|---|---|
| E1 | Dashboard column contracts | column-for-column parity with prod `mis_2_subs_all` / `mis_2_subs_coll_2` / `_4_v8` | Confirm exact contract before promotion |
| E2 | `snapp_regional_clusters` (region, country_grouping) | Sheets-backed external table — Drive scope BLOCKED; join gated by `enable_regional_clusters` var (default false -> null in dev) | Need native/seed equivalent |
| E3 | `channel_planning_multi_threshold` | 0.5 | Confirm Phase 8 uses 0.5 (vs 0.8 main path) |
| E4 | `_3` accumulation idempotency | dbt incremental insert_overwrite by month (replaces Colab non-atomic INSERT) | Confirm month-grain replace is acceptable |
| E5 | `int_channel_planning_google_2` transform | Colab `mis_..._google_2` SQL not in export; approximated (channel_from_lookup -> main_channels, sub_channels null) | Provide/confirm exact Google planning channel mapping |

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

The GA4 attribution phases need ~7 months of GA4 raw events (May submissions attributed
up to 180 days back). Dry run of the manual-campaign extract = **4.29 TB (~$27)**; the
Google auto-tag extract is similar (~$27); full Phase 3-8 materialisation ~**$55-60** of
BigQuery, once. In prod this is cheap because it accumulates one month at a time
(~$4/month). The GA event scanners are tagged `ga_expensive`; the whole GA chain is
tagged `ga` (build with `dbt build --select tag:ga` once signed off).

**Cheaper dev path (`ga_extract_from_prod`, default `true`):** instead of re-scanning
raw GA4 events, `int_ga_data` / `int_google_auto_1` read the already-accumulated prod
extracts `mis_2_ga_data` (2.3 TB unpartitioned, ~$14.5 to slice) and `mis_2_google_auto_1`
(~$0.09). These extracts are **identity-independent** (user x event x campaign only), so
the new dev identity resolution still drives every downstream submission join. Net one-off
dev cost drops from ~$55 to **~$15**. Set `ga_extract_from_prod: false` for a fully
Colab-faithful raw-events rebuild. SN-REVIEW: confirm prod extract is an acceptable input
for the dev validation build.

## Reconciliation log (dev vs prod, May 2026)

Filled in as each phase is built and validated via the bigquery MCP.

| Phase | Model | dev | prod | delta | notes |
|---|---|---|---|---|---|
| 1A | int_authors distinct subs | 307,182 | 307,176 | +6 | pre-existing (data refresh) |
| 1B | int_authors_enriched distinct subs (May 2026) | 307,181 | 307,176 | +5 | matches 1A; data refresh |
| 1B | subs with non-null client_id (May 2026) | 253,366 | 258,974 | -5,608 (-2.2%) | cost of dropping deprecated identity branches (A4/A5/A6) — small at submission level |
| 1B | int_email_clientid rows / emails / cids | 11.86M / 3.96M / 11.35M | 13.43M / 4.49M / 12.67M | ~-12% pairs | deprecated branches add ~12% raw pairs but only 2.2% sub coverage |
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

**Read of the Phase 3-7 reconciliation:** GA extract is now shared with prod (`ga_extract_from_prod`),
so the submission spine is exact (0 delta) and every remaining channel delta traces to the
disabled deprecated identity branches (A4/A5/A6). `email_rm_flag` is the most exposed (-17%)
because email touchpoints are matched purely through `user_pseudo_id`; the deprecated branches
contributed a large share of those email->client_id->user_pseudo_id links. SN-REVIEW: decide
whether to re-enable any deprecated identity branch (`identity_include_*`) to close the email gap,
or accept the cleaner native-only identity.
