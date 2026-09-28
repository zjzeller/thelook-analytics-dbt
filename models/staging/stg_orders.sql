with source as (
    select * from {{ source('thelook', 'orders') }}
)

select
    order_id,
    user_id,
    status,
    created_at,
    num_of_item as num_items
from source
