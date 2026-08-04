use healthcare_analytics;

SET SQL_SAFE_UPDATES = 0;

select * from appointments
limit 10;

alter table appointments
	change column Hipertension hypertension int,
    change column Handcap disability_count int,
    change column `No-show` no_show varchar(3);
	

select disability_count,count(*)
from appointments
group by disability_count;

alter table appointments
	modify column ScheduledDay datetime,
	modify column AppointmentDay date;

alter table appointments
	add column ScheduledDay_clean datetime,
	add column AppointmentDay_clean date;
    
update appointments
set ScheduledDay_clean = str_to_date(replace(replace(ScheduledDay,'T',' '), 'Z', ''),'%Y-%m-%d %H:%i:%s'),AppointmentDay_clean = str_to_date(replace(replace(
AppointmentDay,'T',' '), 'Z', ''),'%Y-%m-%d %H:%i:%s');
    
alter table appointments
	drop column ScheduledDay ,
	drop column AppointmentDay;
    
alter table appointments
	change column ScheduledDay_clean ScheduledDay datetime,
    change column AppointmentDay_clean AppointmentDay date;
    
    
SELECT 
    SUM(CASE WHEN PatientId IS NULL THEN 1 ELSE 0 END) AS PatientId_nulls,
    SUM(CASE WHEN AppointmentID IS NULL THEN 1 ELSE 0 END) AS AppointmentID_nulls,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS Gender_nulls,
    SUM(CASE WHEN Neighbourhood IS NULL THEN 1 ELSE 0 END) AS Neighbourhood_nulls,
    SUM(CASE WHEN Scholarship IS NULL THEN 1 ELSE 0 END) AS Scholarship_nulls,
    SUM(CASE WHEN hypertension IS NULL THEN 1 ELSE 0 END) AS hypertension_nulls,
    SUM(CASE WHEN Diabetes IS NULL THEN 1 ELSE 0 END) AS Diabetes_nulls,
    SUM(CASE WHEN Alcoholism IS NULL THEN 1 ELSE 0 END) AS Alcoholism_nulls,
    SUM(CASE WHEN disability_count IS NULL THEN 1 ELSE 0 END) AS disability_count_nulls,
    SUM(CASE WHEN SMS_received IS NULL THEN 1 ELSE 0 END) AS SMS_received_nulls,
    SUM(CASE WHEN no_show IS NULL THEN 1 ELSE 0 END) AS no_show_nulls,
    SUM(CASE WHEN ScheduledDay IS NULL THEN 1 ELSE 0 END) AS ScheduledDay_nulls,
    SUM(CASE WHEN AppointmentDay IS NULL THEN 1 ELSE 0 END) AS AppointmentDay_nulls
FROM appointments;
    
    
SELECT 
    COUNT(Age) AS `count`,
    AVG(Age) AS `mean`,
    STDDEV(Age) AS `std`,
    MIN(Age) AS `min`,
    MAX(Age) AS `max`
FROM appointments;

delete from appointments
where age = -1;

alter table appointments
	add column lead_time_days int;

update appointments
set lead_time_days = datediff(AppointmentDay,date(ScheduledDay));

select 
	min(lead_time_days),max(lead_time_days)
from appointments ;

select * from appointments
where lead_time_days <0;

delete from appointments
where lead_time_days < 0;

-- data exploration
-- 1) What's our overall no-show rate?

SELECT 
    no_show,
    COUNT(*) AS total_appointments,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS percentage
FROM appointments
GROUP BY no_show;

-- 2 does the day of week matter

select
	dayname(AppointmentDay) as appointmentday,
    count(*) as total_appointments,
    sum(case when no_show = 'Yes' then 1 else 0 end) as no_shows,
    round(sum(case when no_show = 'Yes' then 1 else 0 end) * 100/count(*),2) as rate_of_no_shows
from appointments
group by dayname(appointmentday)
order by rate_of_no_shows desc;

-- 3 does lead time matter
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

-- 4 Age groups
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

-- 5 Do sms reminders help

select 
	case 
		when SMS_received = 1 then 'Received SMS' else 'No SMS'
        end as sms_status,
    count(*) as total_appointments,
    round(sum(case when no_show = 'Yes' then 1 else 0 end)*100/count(*),2) as no_show_rate
from appointments
group by sms_status
order by no_show_rate desc;

-- 6 which neighbourhoods have highest risk? (ie highest no show rates)
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
        
-- Scholarship (government welfare recipient) and no_show rate
SELECT 
    Scholarship,
    COUNT(*) AS total_appointments,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY Scholarship;

-- Hypertension, Diabetes, Alcoholism vs noshow rate
SELECT 
    hypertension,
    Diabetes,
    Alcoholism,
    COUNT(*) AS total_appointments,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_show_rate
FROM appointments
GROUP BY hypertension, Diabetes, Alcoholism
ORDER BY no_show_rate DESC;


        
-- Patient level scoring

-- ---------

CREATE VIEW v_appointment_risk AS
WITH patient_history AS (
    SELECT
        PatientId,
        AppointmentID,
        AppointmentDay,
        Neighbourhood,
        lead_time_days,
        sms_received,
        Scholarship,
        no_show,
        COUNT(*) OVER (
            PARTITION BY PatientId 
            ORDER BY AppointmentDay 
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_appointments,
        SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) OVER (
            PARTITION BY PatientId 
            ORDER BY AppointmentDay 
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_no_shows
    FROM appointments
)
SELECT
    PatientId,
    AppointmentID,
    AppointmentDay,
    Neighbourhood,
    lead_time_days,
    sms_received,
    Scholarship,
    no_show,               
    prior_appointments,
    prior_no_shows,
    ROUND(prior_no_shows / NULLIF(prior_appointments, 0), 2) AS prior_no_show_rate,
    CASE
        WHEN prior_appointments = 0 THEN 'New Patient - Monitor'
        WHEN (prior_no_shows / NULLIF(prior_appointments, 0)) >= 0.5 
             OR lead_time_days >= 8 THEN 'High Risk'
        WHEN (prior_no_shows / NULLIF(prior_appointments, 0)) >= 0.2 
             OR lead_time_days BETWEEN 4 AND 7 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_tier
FROM patient_history;

-- ----------

SELECT
* 
FROM v_appointment_risk
WHERE risk_tier = 'High Risk'
ORDER BY AppointmentDay
Limit 50;

-- 1 Risk tier distribution

SELECT 
    risk_tier,
    COUNT(*) AS total_appointments,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM v_appointment_risk), 2) AS percentage
FROM v_appointment_risk
GROUP BY risk_tier
ORDER BY total_appointments DESC;


-- 2 Does the risk tier actually predict no-shows?
SELECT 
    risk_tier,
    COUNT(*) AS total_appointments,
    SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) AS actual_no_shows,
    ROUND(SUM(CASE WHEN no_show = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS actual_no_show_rate
FROM v_appointment_risk
GROUP BY risk_tier
ORDER BY actual_no_show_rate DESC;


