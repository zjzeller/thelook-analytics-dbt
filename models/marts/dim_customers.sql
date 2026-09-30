-- One row per customer with at least one completed order.
-- Adds acquisition attributes, lifetime value, and a fair repeat-purchase flag.

with users as (
    select * from {{ ref('stg_users') }}
),

orders as (
    select * from {{ ref('int_orders_with_revenue') }}
),

customer_orders as (
    select
        user_id,
        min(created_at)                                              as first_order_at,
        max(created_at)                                              as last_order_at,
        min(case when customer_order_number = 2 then created_at end) as second_order_at,
        count(*)                                                     as lifetime_orders,
        sum(order_revenue)                                           as lifetime_revenue
    from orders
    group by 1
),

-- Category of the most expensive item in each customer's first order
first_order_category as (
    select
        o.user_id,
        p.category
    from orders as o
    inner join {{ ref('stg_order_items') }} as i
        on o.order_id = i.order_id
    inner join {{ ref('stg_products') }} as p
        on i.product_id = p.product_id
    where o.customer_order_number = 1
      and i.status not in ('Cancelled', 'Returned')
    qualify row_number() over (
        partition by o.user_id
        order by i.sale_price desc, i.order_item_id
    ) = 1
)

select
    u.user_id,
    u.country,
    u.age,
    case
        when u.age < 25 then '18-24'
        when u.age < 35 then '25-34'
        when u.age < 45 then '35-44'
        when u.age < 55 then '45-54'
        else '55+'
    end                                                    as age_band,
    u.traffic_source,
    date(u.created_at)                                     as signup_date,
    c.first_order_at,
    date_trunc(date(c.first_order_at), month)              as cohort_month,
    c.second_order_at,
    c.last_order_at,
    c.lifetime_orders,
    c.lifetime_revenue,
    c.lifetime_orders > 1                                  as is_repeat_customer,
    date_diff(date(c.second_order_at), date(c.first_order_at), day) as days_to_second_order,
    -- Fair comparison across cohorts: only customers who have had a full 90 days
    -- to come back get a value; newer customers are null instead of counted as "no".
    case
        when date(c.first_order_at)
             <= date_sub(date_trunc(current_date(), month), interval 90 day)
        then coalesce(
            date_diff(date(c.second_order_at), date(c.first_order_at), day) <= 90,
            false
        )
    end                                                    as repeated_within_90_days,
    f.category                                             as first_order_category
from customer_orders as c
inner join users as u
    on c.user_id = u.user_id
left join first_order_category as f
    on c.user_id = f.user_id
