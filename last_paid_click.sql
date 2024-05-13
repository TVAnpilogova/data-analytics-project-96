with tab as (
    select
        s.visitor_id, --уникальный человек на сайте
        s.visit_date, --время визита
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign, --метки c учетом модели атрибуции
        l.lead_id, --идентификатор лида
        l.created_at, --время создания лида
        l.amount, --сумма лида (в деньгах)
        l.closing_reason, --причина закрытия
        l.status_id, --код причины закрытия
        row_number() over (
            partition by s.visitor_id
            order by s.visit_date desc
        ) as number
    from sessions as s
    inner join
        leads as l
        on
            s.visitor_id = l.visitor_id
    where
        s.source != 'organic' and s.medium != 'organic'
        and s.campaign != 'organic'
)

select
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
from tab
where number = 1
order by
    amount desc nulls last,--от большего к меньшему, null записи идут последними
    visit_date asc,--от ранних к поздним
    utm_source asc,
    utm_medium asc,
    utm_campaign asc --в алфавитном порядке
limit 10;
