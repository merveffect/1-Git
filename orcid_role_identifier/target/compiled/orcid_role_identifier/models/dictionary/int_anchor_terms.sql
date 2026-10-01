

/*
    ANCHORS FOR BOTH AXES

    An anchor is an example that defines what a group looks like. We embed
    the anchors once, embed the real values once, and the nearest group
    wins. They are the only hand-written input in the whole dictionary.

        axis = 'title'       9 groups, matched against job titles
        axis = 'discipline' 12 groups, matched against department names

    The two axes answer different questions, which is why they are
    separate. Measured: assigning a discipline from the job title leaves
    73.5% of records unusable, because the common titles - professor,
    lecturer, postdoc - state a rung on the academic ladder, not a field.
    From the department the same method leaves 1.6% unusable.

    There is no '__distractor' list any more. With 21 groups competing,
    the non-target groups are the distractors.
*/

select
    'title'                                 as axis,
    title_group                             as group_key,
    
    NULLIF(TRIM(REGEXP_REPLACE(
        
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE(anchor_term, ''), NFKC)),
                    r'[^\p{L}\p{N}\s&/+-]', ' '
                ),
                r'\s+', ' '
            )
        ),
        ''
    )

,
        r'\s+', ' '
    )), '')
    as anchor_term,
    language_code,
    note
from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_seeds`.`title_group_anchors`

union all

select
    'discipline'                            as axis,
    discipline                              as group_key,
    
    NULLIF(TRIM(REGEXP_REPLACE(
        
    NULLIF(
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    LOWER(NORMALIZE_AND_CASEFOLD(COALESCE(anchor_term, ''), NFKC)),
                    r'[^\p{L}\p{N}\s&/+-]', ' '
                ),
                r'\s+', ' '
            )
        ),
        ''
    )

,
        r'\s+', ' '
    )), '')
    as anchor_term,
    language_code,
    note
from `dat-analytics-eng-ec869189`.`dev_orcid_role_identifier_seeds`.`discipline_anchors`