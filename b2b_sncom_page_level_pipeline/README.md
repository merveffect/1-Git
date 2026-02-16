# B2B SNCOM Page Level Pipeline

## Overview

The **B2B SNCOM Page Level Pipeline** is a comprehensive dbt data transformation project that processes and enriches Google Analytics 4 (GA4) event data for B2B website analytics. It provides detailed insights into user behavior, campaign attribution, channel effectiveness, and funnel progression across Springer Nature's B2B web properties.

## Purpose

This pipeline transforms raw GA4 event logs into a clean, denormalized presentation table with:

- **Campaign Attribution**: Automatically decodes campaign codes to identify products, audiences, goals, and geographies
- **Channel Classification**: Attributes traffic to main channels (SEO, Paid Social, Email, Display, etc.) and sub-channels with AI SEO detection
- **Funnel Tracking**: Maps pages to marketing funnel stages (Awareness, Interest, Evaluation, Conversion)
- **Event Standardization**: Transforms raw GA4 events into business-friendly event names with context


## Key Features

### Incremental Processing
- **Lookback Window**: 2-day incremental processing captures late-arriving GA4 data
- **Full Refresh**: Loads all historical data up to 2 days ago for data quality and completeness
- **Cost Optimization**: Partition pruning and clustering reduce BigQuery scan costs by ~30-50%


## Data Flow

```
GA4 Events (b2b_ga4_test_static)
    ↓
[RAW] Naming Conventions (dict + v2 versioning)
    ↓
[STAGING CTE0] Field normalization + webpage mapping
    ↓
[STAGING CTE1] HubSpot categorization + funnel assignment
    ↓
[STAGING CORE] URL pattern extraction
    ↓
[STAGING FINAL_CTE] Channel attribution + AI SEO detection
    ↓
[LOOKUP TABLES] Version-tracked code decoding
    ↓
[PRESENTATION] b2b_ga4_final (fully enriched)
    ↓
Ready for analytics, BI tools, dashboards
```
