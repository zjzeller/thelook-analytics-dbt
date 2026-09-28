{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
)

select
    order_id,
    user_id,
    status,
    created_at,
    num_items
from orders

{% if is_incremental() %}
    where created_at > (select max(created_at) from {{ this }})
{% endif %}
