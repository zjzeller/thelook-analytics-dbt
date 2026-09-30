-- Each cohort should have exactly one row per month since first order.
select
    cohort_month,
    months_since_first_order,
    count(*) as row_count
from {{ ref('fct_cohort_retention') }}
group by 1, 2
having count(*) > 1
