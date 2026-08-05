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


-- Patient Risk Framework

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
