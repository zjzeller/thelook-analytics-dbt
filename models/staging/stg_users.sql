with source as (
    select * from {{ source('thelook', 'users') }}
)

select
    id as user_id,
    first_name,
    last_name,
    email,
    age,
    state,
    country,
    created_at
from source
