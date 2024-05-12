with tab as( 
select 
s.visitor_id, --уникальный человек на сайте
s.visit_date, --время визита
s.source as utm_source,
s.medium as utm_medium,
s.campaign as utm_campaign, --метки c учетом модели атрибуции
l.lead_id, --идентификатор лида, если пользователь сконвертился в лид после(во время) визита, NULL — если пользователь не оставил лид
l.created_at, --время создания лида, NULL — если пользователь не оставил лид
l.amount, --сумма лида (в деньгах), NULL — если пользователь не оставил лид
l.closing_reason, --причина закрытия, NULL — если пользователь не оставил лид
l.status_id --код причины закрытия, NULL — если пользователь не оставил лид
from sessions as s
join leads as l on
s.visitor_id=l.visitor_id
WHERE s.source != 'organic' AND s.medium != 'organic' AND s.campaign != 'organic'
)
select
visitor_id, 
to_char(visit_date, 'yyyy-mm-dd') as visit_date,
utm_source,
utm_medium,
utm_campaign, 
lead_id,
created_at, 
amount, 
closing_reason, 
status_id 
from tab
order by 
amount desc,--от большего к меньшему, null записи идут последними
visit_date asc,--от ранних к поздним
utm_source ASC, 
utm_medium ASC, 
utm_campaign ASC --в алфавитном порядке
;


