with tab as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads as vk 
    union all
    select
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads as ya
),
tab1 as (
    select
        visitor_id,
        visit_date,
        row_number() over(partition by visitor_id order by visit_date  desc) as rn
    from sessions
),
tab2 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(s.visitor_id) as visitors_count,
        sum(daily_spent) as total_cost,
        count(l.lead_id) as leads_count,
        count(case when closing_reason = 'Успешно реализовано' or status_id = '142' then 'one' end) as purchases_count,
        status_id,
        closing_reason,
        status_id,
        rn,
        sum(case when status_id = '142' then amount end) as revenue
    from sessions s 
    inner join leads l on s.visitor_id = l.visitor_id
    inner join tab on s.campaign = tab.utm_campaign and s.medium = tab.utm_medium and s."source" = tab.utm_source
    inner join tab1 using(visit_date)
    where utm_medium <> 'organic' and rn = 1
    group by
        s.visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        l.status_id,
        closing_reason,
        s.visitor_id,
        rn 
),
calculated_metrics as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        visitors_count,
        total_cost,
        leads_count,
        purchases_count,
        revenue,
        total_cost / nullif(visitors_count, 0) as cpu,
        total_cost / nullif(leads_count, 0) as cpl,
        total_cost / nullif(purchases_count, 0) as cppu,
        case
            when total_cost = 0 then null
            else ((revenue - total_cost) / total_cost) * 100
        end as roi
    from tab2
)
SELECT
    to_char(visit_date, 'yyyy-mm-dd') as visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    visitors_count,
    total_cost,
    leads_count,
    purchases_count,
    revenue,
    cpu,
    cpl,
    cppu,
    roi
from calculated_metrics
order by
    revenue desc nulls last,
    visit_date,
    visitors_count desc,
    utm_source,
    utm_medium,
    utm_campaign 
limit 15;
