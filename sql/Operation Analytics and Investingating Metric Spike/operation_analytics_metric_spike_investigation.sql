show variables like 'secure_file_priv';
-- o/p -> 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/'

create database project3;
use project3; 

# 1. creating and importing data into job_data table

create table job_data (
ds varchar(100),
job_id int ,
actor_id int,
event varchar(50),
language varchar(50),
time_spent int,
org char(1)
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/job_data.csv'
into table job_data
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from job_data;

alter table job_data add column temp_ds datetime;
# 11/30/2020 date %m-%d-%Y
update job_data set temp_ds = str_to_date(ds, '%m/%d/%Y');
alter table job_data drop column ds;
alter table job_data change column temp_ds ds datetime;

select * from job_data;
-- drop table job_data;
-- -------------------------------- ---------------------------------------;		
# 2. creating and importing data into users table

create table users (
user_id int,
created_at varchar(100) ,
company_id int,
language varchar(50),
activated_at varchar(100),
state varchar(50)
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users.csv'
into table users
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from users;

alter table users add column temp_ct datetime;
# 01-01-2013 20:59  date format %d-%m-%Y %H:%i
update users set temp_ct = str_to_date(created_at, '%d-%m-%Y %H:%i');
alter table users drop column created_at;
alter table users change column temp_ct created_at datetime;

select * from users;

alter table users add column temp_at datetime;
# 01-01-2013 20:59  date format %d-%m-%Y %H:%i
update users set temp_at = str_to_date(activated_at, '%d-%m-%Y %H:%i');
alter table users drop column activated_at;
alter table users change column temp_at activated_at datetime;
-- -------------------------------- -------------------------------;					
# 3. creating and importing data into events table

create table events(
user_id int,
occurred_at varchar(100) ,
event_type varchar(50),
event_name varchar(100),
location varchar(50),
device varchar(50),
user_type int
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/events.csv'
into table events
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from events;

alter table events add column temp_ot datetime;
# 01-01-2013 20:59  date format %d-%m-%Y %H:%i
update events set temp_ot = str_to_date(occurred_at, '%d-%m-%Y %H:%i');
alter table events drop column occurred_at;
alter table events change column temp_ot occurred_at datetime;

-- ------------------------------------------- ---------------------------;
# 4. creating and importing data into email_events table

create table email_events(
user_id int,
occurred_at varchar(100),
action varchar(100),
user_type int
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/email_events.csv'
into table email_events
fields terminated by ","
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from email_events;

alter table email_events add column temp_ot datetime;
# 01-01-2013 20:59  date format %d-%m-%Y %H:%i
update email_events set temp_ot = str_to_date(occurred_at, '%d-%m-%Y %H:%i');
alter table email_events drop column occurred_at;
alter table email_events change column temp_ot occurred_at datetime;

-- --------------------------------------------- -------------------------------;

use project3; 

select count(*) from job_data;
select count(*) from users;
select count(*) from events;
select count(*) from email_events;

select * from job_data;
select * from users;
select * from events;
select * from email_events;


# Assignments
--  Case Study 1: 
# A) Write an SQL query to calculate the number of jobs reviewed 
-- per hour for each day in November 2020.
select ds, 
	count(job_id) as no_of_jobs_reviewed, 
	sum(time_spent)/3600 as time_spent_in_hours, 
	count(job_id) * 3600 /sum(time_spent) as per_day_per_hour,
	avg(count(job_id) * 3600 /sum(time_spent)) over() as avg_per_hour_per_day
from job_data 
where ds between '2020-11-01' and '2020-11-30' 
group by ds;

# B) Write an SQL query to calculate the 7-day rolling average of throughput. 
-- - Additionally, explain whether you prefer using the daily metric or 
-- - the 7-day rolling average for throughput, and why?
-- SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
with daily_rolling as (select ds,
	count(job_id) as drj,
	sum(time_spent) as drt
from job_data
where ds between '2020-11-01' and '2020-11-30'
group by ds),
seven_days_rolling as (select ds,
	sum(drj) over(order by ds rows between 6 preceding  and current row) as srj,
	sum(drt) over(order by ds rows between 6 preceding  and current row) as srt
from daily_rolling
where ds between '2020-11-01' and '2020-11-30'
order by ds
)
select daily_rolling.ds, drj/drt as daily, srj/srt as seven_day 
from daily_rolling inner join seven_days_rolling 
on daily_rolling.ds = seven_days_rolling.ds
order by daily_rolling.ds;

# C) Write an SQL query to calculate the percentage share of each language over the last 30 days.
with extra_query as 
(select max(ds)  as recent_data from job_data)
select distinct language, 100*(count(job_id) over(
	partition by language rows between unbounded preceding and unbounded following) /count(*) over(
	order by ds rows between unbounded preceding and unbounded following)) as percentage_share 
 from
(select * From job_data cross join extra_query
where datediff(recent_data, date(ds)) between 0 and 30) full_query;


# D) Write an SQL query to display duplicate rows from the job_data table.
with dup_rows as (
	select *, row_number() over( 
			partition by job_id, actor_id, event, language, time_spent, org, ds
			order by job_id, actor_id, event, language, time_spent, org, ds
			) as row_num
	from job_data)
select * from dup_rows where row_num > 1;

-- --OR--
select * from (
	select *, row_number() over( 
			partition by job_id, actor_id, event, language, time_spent, org, ds) AS row_num
            from job_data) dup_rows
where row_num > 1;

-- Case Study 2: 
# A) Write an SQL query to calculate the weekly user engagement
-- (Measure the activeness of users on a weekly basis).
select count(distinct(user_id)), count(distinct(event_name)) from events;

select *, user_engagement-lag(user_engagement, 1) over(order by week) as engagement_growth
from(
select year(occurred_at) as year, week(occurred_at) as week, 
count(event_name) as engagement, count(user_id) as user_engagement  
from events
where event_type = 'engagement'
group by week(occurred_at)) eng_table;


-- select count(user_id), TIMESTAMPDIFF(second, created_at, activated_at) 
-- from users group by TIMESTAMPDIFF(second, created_at, activated_at);

# B) Write an SQL query to calculate the user growth for the product
-- (Analyze the growth of users over time for a product).
select *, 
quarterly_active_users-lag(quarterly_active_users, 1) over(order by year) as quarterly_user_growth 
from(
select year(DATE(activated_at)) as year, 
	quarter(DATE(activated_at)) as quarter, 
    state,
    count(user_id) as quarterly_active_users
from users
where state like "%active%" and activated_at is not null
group by year(DATE(activated_at)), quarter(DATE(activated_at))) qrtr_usr_growth;
-- -----------------------------------------------------------------------------------
select state, length(rtrim(state)), count(*) from users group by state;
select length(state) from users;

-- --------------------------------------------------------------------------------------
use project3; 

select *, weekly_user-lag(weekly_user,1) over(order by week) as retained_user
from(
select year(date(occurred_at)) as year, week(date(occurred_at)) as week, count(user_id) as weekly_user
 from events where event_type = 'signup_flow' group by year(date(occurred_at)), week(date(occurred_at)) )n;
 
 with ret_table as(
 select users.user_id, activated_at, occurred_at from users
 inner join
 events
 on users.user_id = events.user_id
 where users.state like '%active%'),
 -- select count(distinct(user_id)), timestampdiff(week, activated_at, occurred_at) as week_p from ret
--  group by timestampdiff(week, activated_at, occurred_at);
 week_table as(
 select count(distinct(user_id)), activated_at, occurred_at, week(activated_at) as activated_week, week(occurred_at) as event_week 
 from ret_table
 group by week(activated_at), week(occurred_at))
 select * from week_table;
 -- ----------------------------------------------------------  -----------------------------
 # C) Write an SQL query to calculate the weekly retention of users based on their sign-up cohort.
-- (Analyze the retention of users on a weekly basis after signing up for a product)
with sign_up_user as(
select distinct user_id, extract(week from occurred_at) as sign_up_week
from events
where event_type = 'signup_flow'
and event_name = 'complete_signup'),
engaged_user as(
select distinct user_id, extract(week from occurred_at) as engagement_week
from events
where event_type = 'engagement')
select sign_up_week, engagement_week, count(sign_up_user.user_id) as total_user,
count(sign_up_user.user_id)-lag(count(sign_up_user.user_id), 1) 
over(partition by sign_up_week order by engagement_week) as retained_user
from sign_up_user
left join
engaged_user
on sign_up_user.user_id = engaged_user.user_id
group by sign_up_week, engagement_week
order by sign_up_week, engagement_week;
 
# D) Write an SQL query to calculate the weekly engagement per device.
-- (Measure the activeness of users on a weekly basis per device)
select occurred_at, extract(year from occurred_at) as year, 
extract(week from occurred_at) as week,
device, count(distinct(user_id)) as total_user
from events
where event_type = 'engagement'
group by device, extract(week from occurred_at)
order by extract(year from occurred_at), extract(week from occurred_at), count(distinct(user_id));

# E) Write an SQL query to calculate the email engagement metrics.
-- (Analyze how users are engaging with the email service)
set @email_click=(select count(user_id) from email_events where action = 'email_clickthrough');
set @email_opened=(select count(user_id) from email_events where action = 'email_open');
set @email_sent=(select count(user_id) from email_events where action = 'sent_reengagement_email')+
				(select count(user_id) from email_events where action = 'sent_weekly_digest');

select @email_click*100/@email_sent as percent_email_clicked, 
		@email_opened*100/@email_sent as percent_email_opened;











-- -------------------------------------------- ---------------------------------
select 
100.0 * sum(case when email_cat = 'email_opened' then 1 else 0 end)
        /sum(case when email_cat = 'email_sent' then 1 else 0 end)
as email_opening_rate,
100.0 * sum(case when email_cat = 'email_clicked' then 1 else 0 end)
        /sum(case when email_cat = 'email_sent' then 1 else 0 end)
as email_clicking_rate
from
(
select *,
case when action in ('sent_weekly_digest', 'sent_reengagement_email')
     then 'email_sent'
     when action in ('email_open')
     then 'email_opened'
     when action in ('email_clickthrough')
     then 'email_clicked'
end as email_cat
from tutorial.yammer_events
)a;
























































































