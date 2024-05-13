with tab as (
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost,
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
    from vk_ads
    where utm_medium != 'organic'
    group by utm_source, utm_medium, utm_campaign, campaign_date
    union all
    select
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost,
        to_char(campaign_date, 'YYYY-MM-DD') as campaign_date
    from ya_ads
    where utm_medium != 'organic'
    group by utm_source, utm_medium, utm_campaign, campaign_date
)
,
tab2 as (
    select
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        s.visitor_id,
        l.lead_id,
        l.closing_reason,
        l.status_id,
        l.amount,
        row_number()
        over (partition by s.visitor_id order by visit_date desc)
        as rn,
        to_char(s.visit_date, 'YYYY-MM-DD') as visit_date,
        lower(s.source) as utm_source,
        to_char(l.created_at, 'YYYY-MM-DD') as created_at
    from sessions as s
    left join
        leads as l
        on s.visitor_id = l.visitor_id and s.visit_date <= l.created_at
    where s.medium != 'organic'
),

tab3 as (
    select
        tab2.rn,
        tab2.visit_date,
        tab2.utm_source,
        tab2.utm_medium,
        tab2.utm_campaign,
        tab.total_cost,
        count(tab2.visitor_id) as visitors_count,
        count(tab2.lead_id) as leads_count,
        count(
            case
                when
                    tab2.closing_reason = 'Успешно реализовано'
                    or tab2.status_id = '142'
                    then 'one'
            end
        ) as purchases_count,
        sum(case when tab2.status_id = '142' then tab2.amount end) as revenue
    from tab2
    left join
        tab
        on
            tab2.utm_campaign = tab.utm_campaign
            and tab2.utm_medium = tab.utm_medium
            and tab2.utm_source = tab.utm_source
            and tab2.visit_date >= tab.campaign_date
    where tab2.rn = '1'
    group by
        tab2.rn,
        tab2.visit_date,
        tab2.utm_source,
        tab2.utm_medium,
        tab2.utm_campaign,
        tab.total_cost
)

select
    tab3.visit_date,
    tab3.visitors_count,
    tab3.utm_source,
    tab3.utm_medium,
    tab3.utm_campaign,
    tab3.total_cost,
    tab3.leads_count,
    tab3.purchases_count,
    tab3.revenue
from tab3
order by
    tab3.revenue desc nulls last,
    tab3.visit_date asc,
    tab3.visitors_count desc,
    tab3.utm_source asc,
    tab3.utm_medium asc,
    tab3.utm_campaign asc
limit 15;
