-- A singular test fails if it returns any rows.
-- precision, recall, F1 and at-least-one-correct are all ratios, so each must
-- be between 0 and 1. A NULL means the ground-truth join came back empty.

SELECT run_id, run_date, precision, recall, f1_score, at_least_one_correct_accuracy
FROM {{ ref('evaluation_metrics') }}
WHERE precision IS NULL OR precision NOT BETWEEN 0 AND 1
   OR recall IS NULL OR recall NOT BETWEEN 0 AND 1
   OR f1_score IS NULL OR f1_score NOT BETWEEN 0 AND 1
   OR at_least_one_correct_accuracy IS NULL OR at_least_one_correct_accuracy NOT BETWEEN 0 AND 1
