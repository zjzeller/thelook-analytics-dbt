-- 90-day repeat purchase rate and average lifetime revenue by customer segment.
-- Only customers with a full 90-day observation window are included (see dim_customers).

with eligible as (
    select * from {{ ref('dim_customers') }}
    where repeated_within_90_days is not null
),

by_traffic_source as (
    select
        'traffic_source'                                  as segment_type,
        traffic_source                                    as segment_value,
        count(*)                                          as customers,
        avg(cast(repeated_within_90_days as int64))       as repeat_rate_90d,
        avg(lifetime_revenue)                             as avg_lifetime_revenue
    from eligible
    group by 1, 2
),

by_first_category as (
    select
        'first_order_category',
        first_order_category,
        count(*),
        avg(cast(repeated_within_90_days as int64)),
        avg(lifetime_revenue)
    from eligible
    group by 1, 2
),

by_age_band as (
    select
        'age_band',
        age_band,
        count(*),
        avg(cast(repeated_within_90_days as int64)),
        avg(lifetime_revenue)
    from eligible
    group by 1, 2
)

select * from by_traffic_source
union all
select * from by_first_category
union all
select * from by_age_band
