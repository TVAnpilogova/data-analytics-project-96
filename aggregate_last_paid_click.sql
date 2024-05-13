  with tab as(
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost,
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
    from vk_ads
    where utm_medium <> 'organic'
    group by utm_source, utm_medium, utm_campaign, campaign_date 
    union all
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost,
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
    from ya_ads
    where utm_medium <> 'organic'
    group by utm_source, utm_medium, utm_campaign, campaign_date )
    ,
tab2 as 
(
    select
    row_number() over(partition by s.visitor_id order by visit_date desc) as rn,
    to_char(visit_date, 'YYYY-MM-DD') as visit_date,
    lower(source) as utm_source,
    medium as utm_medium,
    campaign as utm_campaign,
    s.visitor_id,
    lead_id,
    closing_reason,
    status_id,
    to_char(created_at, 'YYYY-MM-DD') as created_at,
    amount
  from sessions s
  left join leads l on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
  where medium <> 'organic'
),
tab3 as (
  select
    rn,
    visit_date,
    count(tab2.visitor_id) as visitors_count, 
    tab2.utm_source, tab2.utm_medium, 
    tab2.utm_campaign,
    count(lead_id) as leads_count, 
    count(case when closing_reason = 'Успешно реализовано' or status_id = '142' then 'one'end) as purchases_count,
    sum(case when status_id = '142' then amount end) as revenue,
    total_cost
  from tab2
  left join tab on tab2.utm_campaign = tab.utm_campaign and tab2.utm_medium = tab.utm_medium and tab2.utm_source = tab.utm_source and tab2.visit_date >= tab.campaign_date
  where rn = '1'
  group by rn, visit_date, tab2.utm_source, tab2.utm_medium, tab2.utm_campaign, total_cost)
  select
    visit_date,
    visitors_count,
    tab3.utm_source, 
    tab3.utm_medium, 
    tab3.utm_campaign, 
    total_cost, 
    leads_count,
    purchases_count, 
    revenue
  from tab3 
  order by revenue desc nulls last,
  visit_date,
  visitors_count desc,
  utm_source,
  utm_medium,
  utm_campaign
  limit 15
;
