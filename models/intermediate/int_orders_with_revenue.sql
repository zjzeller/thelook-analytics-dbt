-- One row per completed order, with revenue from its items and the customer's order sequence.
-- Cancelled and returned orders/items are excluded, and only complete calendar months are kept
-- so the current partial month doesn't drag retention numbers down.

with orders as (
    select * from {{ ref('stg_orders') }}
),

items as (
    select * from {{ ref('stg_order_items') }}
),

order_revenue as (
    select
        order_id,
        sum(sale_price) as order_revenue,
        count(*)        as item_count
    from items
    where status not in ('Cancelled', 'Returned')
    group by 1
)

select
    o.order_id,
    o.user_id,
    o.created_at,
    date_trunc(date(o.created_at), month) as order_month,
    r.order_revenue,
    r.item_count,
    -- 1 = the customer's first completed order, 2 = second, and so on
    row_number() over (
        partition by o.user_id
        order by o.created_at, o.order_id
    ) as customer_order_number
from orders as o
inner join order_revenue as r
    on o.order_id = r.order_id
where o.status not in ('Cancelled', 'Returned')
  and o.created_at < timestamp_trunc(current_timestamp(), month)
