with source as (
    select * from {{ source('thelook', 'users') }}
)

-- Names and emails are left out on purpose: no downstream model needs PII.
select
    id as user_id,
    age,
    state,
    country,
    traffic_source,
    created_at
from source
