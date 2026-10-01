-- ===========================================================================
-- ACCESS TESTS
-- No new Vertex connection is needed - a remote model already exists:
--     datasn-rm-live.institution_disambiguation.embedding_model
-- Only cross-project read access to that project is required.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- TEST 1: can we reach the existing embedding model?
-- ---------------------------------------------------------------------------
SELECT
    content,
    ARRAY_LENGTH(ml_generate_embedding_result) AS dimensions
FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT 'consultant cardiologist' AS content
     UNION ALL SELECT 'librarian')
);
-- PASS: 2 rows, dimensions populated.  [verified: 768]
-- FAIL "Access Denied": read access to datasn-rm-live is required.


-- ---------------------------------------------------------------------------
-- TEST 1b: IS THE MODEL MULTILINGUAL?   [PASSED - see results below]
--
-- The model was provisioned for institution disambiguation, where names
-- are mostly English, so multilingual behaviour was not guaranteed.
-- ORCID job titles span 100+ languages, and an English-only model would
-- silently drop "kardiyolog" and "Oberarztin".
-- ---------------------------------------------------------------------------
WITH e AS (
  SELECT content, ml_generate_embedding_result AS v
  FROM ML.GENERATE_EMBEDDING(
    MODEL `datasn-rm-live.institution_disambiguation.embedding_model`,
    (SELECT 'cardiologist' AS content
     UNION ALL SELECT 'kardiyolog'                      -- TR
     UNION ALL SELECT 'Facharzt fur Kardiologie'        -- DE
     UNION ALL SELECT 'cardiologue'                     -- FR
     UNION ALL SELECT 'librarian'))                     -- unrelated control
SELECT
    b.content                                           AS term,
    ROUND(1 - ML.DISTANCE(a.v, b.v, 'COSINE'), 3)       AS similarity
FROM e a CROSS JOIN e b
WHERE a.content = 'cardiologist' AND b.content != 'cardiologist'
ORDER BY similarity DESC;

/*
    MEASURED RESULT - the model IS multilingual:
        cardiologue                 0.928
        Facharzt fur Kardiologie    0.795
        kardiyolog                  0.760
        librarian                   0.572   <-- unrelated control

    Note the control still scores 0.572: this model has a HIGH BASELINE
    similarity. That is why absolute thresholds do not work here and the
    decision rule is built on the distractor margin instead. See
    analyses/02_similarity_calibration.sql.
*/


-- ---------------------------------------------------------------------------
-- TEST 2: VECTOR_SEARCH
--
-- NOTE: VECTOR_SEARCH requires REAL TABLES as its first argument - a CTE
-- raises "Only SELECT expressions and WHERE clauses are allowed in the
-- 1st argument query". The dbt models already materialise the embedding
-- tables, so this is only a constraint for ad-hoc testing. To try it by
-- hand, create the two tables first, or use ML.DISTANCE with a CROSS
-- JOIN as analyses/02 does.
-- ---------------------------------------------------------------------------


-- ---------------------------------------------------------------------------
-- TEST 3: LLM judge - which route works?   [BOTH FAILED - no connection]
-- ---------------------------------------------------------------------------
-- 3a) AI.GENERATE_BOOL (preferred, concise)
SELECT
    t,
    AI.GENERATE_BOOL(
        CONCAT('Is "', t, '" a healthcare professional job title?'),
        connection_id => 'EU.vertex_ai_conn',
        endpoint      => 'gemini-2.5-flash').result AS is_hcp
FROM UNNEST(['consultant cardiologist', 'data consultant']) AS t;
-- RESULT: "Not found: Connection vertex_ai_conn"
--   -> this project has no Vertex connection.

-- 3b) ML.GENERATE_TEXT (safe harbour) - needs a remote model, which
--     itself needs a Vertex connection, so it hits the same blocker:
-- CREATE OR REPLACE MODEL `<project>.<dataset>.remote_gemini_2_5_flash`
-- REMOTE WITH CONNECTION `<project>.EU.vertex_ai_conn`
-- OPTIONS (ENDPOINT = 'gemini-2.5-flash');

/*
    CONSEQUENCE
    The LLM judge is disabled (dbt_project.yml -> use_llm_judge: false)
    and the pipeline runs on vectors alone. This is NOT a blocker:
      - clear cases are decided automatically by the distractor margin
      - ambiguous generic titles ("Director", "Consultant", "Head of
        Research") have no second opinion and fall to the human review
        queue (rpt_title_review_queue)

    To enable it later, either provision a Vertex AI connection in this
    project, or reuse an existing one from another team. Then set
    use_llm_judge: true - no other change is needed.

    We cannot list the models in datasn-rm-live - INFORMATION_SCHEMA is
    not readable with our permissions. The embedding model itself IS
    callable (Test 1 and 1b both passed), so the grant covers invoking
    that specific model but not browsing the dataset. Whether a text
    model also exists there has to be asked, not discovered.
*/
