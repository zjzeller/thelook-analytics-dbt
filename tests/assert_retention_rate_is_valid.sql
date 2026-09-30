-- Retention is a share of the cohort, so it must fall between 0 and 1,
-- and month 0 (the first-order month) must be 100%.
select *
from {{ ref('fct_cohort_retention') }}
where retention_rate < 0
   or retention_rate > 1
   or (months_since_first_order = 0 and retention_rate != 1)
