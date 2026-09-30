-- One row per acquisition cohort (month of first order) per month since first order.
-- Retention = share of the cohort that placed at least one order in that month.

with customers as (
    select user_id, cohort_month from {{ ref('dim_customers') }}
),

orders as (
    select user_id, order_month, order_revenue from {{ ref('int_orders_with_revenue') }}
),

cohort_sizes as (
    select cohort_month, count(*) as cohort_customers
    from customers
    group by 1
),

activity as (
    select
        c.cohort_month,
        date_diff(o.order_month, c.cohort_month, month) as months_since_first_order,
        count(distinct o.user_id)                       as active_customers,
        sum(o.order_revenue)                            as revenue
    from orders as o
    inner join customers as c
        on o.user_id = c.user_id
    group by 1, 2
)

select
    a.cohort_month,
    a.months_since_first_order,
    s.cohort_customers,
    a.active_customers,
    safe_divide(a.active_customers, s.cohort_customers) as retention_rate,
    a.revenue,
    -- running revenue per original cohort member, a simple customer value curve
    safe_divide(
        sum(a.revenue) over (
            partition by a.cohort_month
            order by a.months_since_first_order
        ),
        s.cohort_customers
    )                                                   as cumulative_revenue_per_customer
from activity as a
inner join cohort_sizes as s
    on a.cohort_month = s.cohort_month
