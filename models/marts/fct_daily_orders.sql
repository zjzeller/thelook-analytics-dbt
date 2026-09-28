with orders as (
    select * from {{ ref('stg_orders') }}
)

select
    date(created_at) as order_date,
    count(*)         as total_orders,
    sum(num_items)   as total_items
from orders
group by 1
order by 1
