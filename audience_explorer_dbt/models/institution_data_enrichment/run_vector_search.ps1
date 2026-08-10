$target = "prod"
$model  = "stg_ror_matches_vector_search"
$table  = "dat-analytics-eng-ec869189.prod_audience_explorer_institution_data_enrichment_staging.stg_ror_matches_vector_search"
$maxRuns = 45
$prevCount = -1

for ($i = 1; $i -le $maxRuns; $i++) {
    Write-Host "===== Run $i / $maxRuns  ($(Get-Date -Format 'HH:mm:ss')) ====="

    dbt run --select $model --target $target

    # count rows after this run
    $countJson = bq query --use_legacy_sql=false --format=json "SELECT COUNT(*) AS c FROM ``$table``"
    $currentCount = [int]($countJson | ConvertFrom-Json)[0].c

    Write-Host "Rows so far: $currentCount (previous: $prevCount)"

    if ($currentCount -eq $prevCount) {
        Write-Host "No new rows added -> done (or stuck). Stopping."
        break
    }
    $prevCount = $currentCount
}

Write-Host "===== Loop finished. Final count: $currentCount ====="