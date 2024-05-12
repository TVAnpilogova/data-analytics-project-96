with tab as(
select distinct on(s.visitor_id)
       s.visitor_id, 
       s.visit_date, 
       l.created_at, 
       l.status_id, amount, 
       lead_id, closing_reason, 
       medium, 
       source, 
       campaign 
from sessions s 
left join leads l 
on s.visitor_id = l.visitor_id
and s.visit_date <= l.created_at
where medium != 'organic'
order by s.visitor_id, visit_date desc
),

tab2 as (
select utm_source, 
       utm_medium, 
       utm_campaign, 
       cast(campaign_date as date) as campaign_date,
       sum(daily_spent) as total_cost
from vk_ads va
group by 1,2,3,4
union
select utm_source, 
       utm_medium, 
       utm_campaign, 
       cast(campaign_date as date) as campaign_date,
       sum(daily_spent) as total_cost
from ya_ads ya
group by 1,2,3,4
),

tab3 as(
select
source, 
medium, 
campaign, 
cast(visit_date as date) as visit_date,
count (visitor_id) as visitors_count,
count (visitor_id) filter(where tab.created_at is not null)as leads_count,
count (visitor_id) filter(where tab.status_id = 142) as purchases_count,
sum(amount) filter(where tab.status_id = 142) as revenue
from tab
group by source, medium, campaign, visit_date
)
select
to_char(visit_date, 'yyyy-mm-dd') as visit_date,
tab3.source as utm_source, 
tab3.medium as utm_medium, 
tab3.campaign as  utm_campaign,
visitors_count,
total_cost,
leads_count, 
purchases_count, 
revenue
from tab3
left join tab2
on tab3.medium = tab2.utm_medium and 
tab3.source = tab2.utm_source and 
tab3.campaign = tab2.utm_campaign and 
tab3.visit_date = tab2.campaign_date
where tab3.medium != 'organic'
order by 9 desc nulls last, 1 asc, visitors_count desc, utm_source asc, utm_medium asc, utm_campaign asc
limit 15
;
limit 15
;
