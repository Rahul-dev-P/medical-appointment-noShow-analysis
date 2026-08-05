use healthcare_analytics;

-- data exploration
-- 1) What's our overall no-show rate?

SELECT 
    no_show,
    COUNT(*) AS total_appointments,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS percentage
FROM appointments
GROUP BY no_show;

-- 2) does the day of week matter

select
	dayname(AppointmentDay) as appointmentday,
    count(*) as total_appointments,
    sum(case when no_show = 'Yes' then 1 else 0 end) as no_shows,
    round(sum(case when no_show = 'Yes' then 1 else 0 end) * 100/count(*),2) as rate_of_no_shows
from appointments
group by dayname(appointmentday)
order by rate_of_no_shows desc;

-- 3) does lead time matter    
	-- same day
    -- 1-3 days
    -- within a weel 4-7 days
    -- long lead 8+ days
select 
	case 
		when lead_time_days = 0 then 'Same day'
        when lead_time_days between 1 and 3 then 'Short (1-3 Days)'
        when lead_time_days between 4 and 7 then 'within a week'
        else 'Long Lead (8+ days)'
	end as lead_time_bucket,
    count(*) as total_appointments,
    round(sum(case when no_show = 'Yes' then 1 else 0 end)*100/count(*),2) as no_show_rate
from appointments
group by lead_time_bucket
order by no_show_rate desc;

-- 4) Do sms reminders help
select 
	case 
		when SMS_received = 1 then 'Received SMS' else 'No SMS'
        end as sms_status,
    count(*) as total_appointments,
    round(sum(case when no_show = 'Yes' then 1 else 0 end)*100/count(*),2) as no_show_rate
from appointments
group by sms_status
order by no_show_rate desc;


-- 5) SMS and Lead_time Relation
SELECT 
    CASE 
        WHEN lead_time_days = 0 THEN 'Same day'
        WHEN lead_time_days BETWEEN 1 AND 3 THEN 'Short (1-3 Days)'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN 'Within a week (4-7 Days)'
        ELSE 'Long Lead (8+ Days)'
    END AS lead_time_bucket,
    COUNT(*) AS total_appointments,
    SUM(SMS_received) AS sms_sent_count,
    ROUND(SUM(SMS_received) * 100.0 / COUNT(*), 2) AS sms_reception_rate_pct
FROM appointments
GROUP BY lead_time_bucket
ORDER BY MIN(lead_time_days);

-- 6) Age groups  
	-- child 0-12
    -- teen 13-19
    -- young adult 20-39
    -- adult 40-59
select
	case 
        when Age between 0 and 12 then 'Child'
        when Age between 13 and 19 then 'Teen'
        when Age between 20 and 39 then 'Young Adult'
        when Age between 40 and 59 then 'Adult'
        else 'Senior'
	end as age_group,
    count(*) as total_appointments,
    round(sum(case when no_show = 'Yes' then 1 else 0 end)*100/count(*),2) as no_show_rate
from appointments
group by age_group
order by no_show_rate desc;


-- 7) which neighbourhoods have highest risk? (ie highest no show rates)
select
	Neighbourhood,
    count(*) as total_appointments,
    round(sum(case when no_show = 'Yes' then 1 else 0 end)*100/count(*),2) as no_show_rate,
    rank() over (order by round(sum(case when no_show = 'Yes' then 1 else 0 end)*100/count(*),2) desc) as risk_rank
from appointments
group by Neighbourhood
having count(*) >= 100
order by no_show_rate desc
limit 15;
        
        
-- 8) Scholarship (government welfare recipient) and no_show rate
SELECT 
    Scholarship,
    COUNT(*) AS total_appointments,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY Scholarship;


-- 9) Hypertension, Diabetes, Alcoholism vs noshow rate
SELECT 
    hypertension,
    Diabetes,
    Alcoholism,
    COUNT(*) AS total_appointments,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY hypertension, Diabetes, Alcoholism
ORDER BY no_show_rate DESC;


-- 10) Risk tier distribution

SELECT 
    risk_tier,
    COUNT(*) AS total_appointments,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM v_appointment_risk), 2) AS percentage
FROM v_appointment_risk
GROUP BY risk_tier
ORDER BY total_appointments DESC;


-- 11) Does the risk tier actually predict no-shows?
SELECT 
    risk_tier,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS actual_no_shows,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS actual_no_show_rate
FROM v_appointment_risk
GROUP BY risk_tier
ORDER BY actual_no_show_rate DESC;


