


create database decode_gaming_behaviour;
use decode_gaming_behaviour;

select * from Level_Details;

create table Player_Details(
p_id int not null primary key,
P_name varchar (25),
L1_Status varchar (26),
L2_status varchar (26),
L1_code varchar (26),
L2_code varchar (26)
);

create table Level_Details(
P_id int not null,
Dev_id varchar (35),
Start_time varchar (24),
Stage_crossed varchar (24),
Level varchar (20),
difficulty varchar (50),
kill_count varchar (200),
head_shots_count varchar (200),
score varchar (200),
lives_earned varchar (30), 
Foreign key (P_id) references Player_Details (p_id) on delete cascade);


## 1. Extract `P_ID`, `Dev_ID`, PName`, and `Difficulty_level` of all players at Level 0. ##

select p.p_id, l.Dev_id, p.P_name , l.difficulty
from Level_Details as l
inner join Player_Details as p
on l.P_id = p.p_id
where l.Level = 0;

## 2. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed. ##

select p.L1_code , round(avg (l.kill_count)) as average_Kill_Count
from Player_Details as p
Inner join Level_Details as l
on p.p_id = l.P_id
where l.lives_earned = 2 and l.Stage_crossed >=3
group by p.L1_code ;


/* 3. Find the total number of stages crossed at each difficulty level for Level 2 with players
using `zm_series` devices. Arrange the result in decreasing order of the total number of
stages crossed. */

select difficulty , sum(Stage_crossed) as 'the_total_number_of_stages_crossed'
from Level_Details as l
where Level = 2 and Dev_Id like "zm%"
group by difficulty
order by 'the_total_number_of_stages_crossed' desc;


/*4. Extract `P_ID` and the total number of unique dates for those players who have played
games on multiple days.*/

select P_id, count(distinct date (Start_time)) as total_number_of_unique_dates
from Level_Details
group by P_id
having total_number_of_unique_dates
order by P_id;

/*5. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the
average kill count for Medium difficulty.*/

with Medium_avg As (
Select Avg (kill_count) as Avg_kill_count
from Level_Details
where difficulty = 'Medium')
Select P_id, Level, sum(kill_count) as 
Total_kill_count 
from Level_Details
where kill_count > (select  Avg_kill_count from Medium_avg)
group by P_id, Level;

/*6. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level
0. Arrange in ascending order of level.*/

Select Level, sum(lives_earned)
from Level_Details
where Level !=0
group by Level
order by Level;

/*7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using
`Row_Number`. Display the difficulty as well.*/

with top_3 as 
(select Dev_id, score, 
row_number() over(partition by Dev_id order by score desc) as rnk,
difficulty
from Level_Details)
select Dev_id, score, difficulty, rnk
from top_3
where rnk <=3;
	
/*8. Find the `first_login` datetime for each device ID */

with first_login as (
select Dev_id, Start_time,
row_number() over(partition by Dev_id order by Start_time asc ) as rnk
from Level_Details)
select Dev_id, Start_time
from first_login
where rnk = 1;

/*9. Find the top 5 scores based on each difficulty level and
rank them in increasing order using `Rank`. Display
`Dev_ID` as well.*/

with top_5 as (
select Dev_id, difficulty, score,
rank() over(partition by difficulty order by score desc ) as rnk
from Level_Details)
select *
from top_5
where rnk <=5;

/*10. Find the device ID that is first logged in (based on
`start_datetime`) for each player (`P_ID`). Output should
contain player ID, device ID, and first login datetime */

with first_logged as (
select P_id, Dev_id, Start_time,
row_number() over(partition by P_id order by Start_time asc ) as rnk
from Level_Details)
select P_id, Dev_id, Start_time
from first_logged
where rnk = 1;

/*11. For each player and date, determine how many `kill_counts`
were played by the player so far.
a) with window function */

select P_id, Date (Start_time) as date,
sum(kill_count) over (partition by P_id order by Start_time)
as kill_counts_played
from Level_Details;

/*b) Without window function */

select P_id, Start_time, kill_count
from(select P_id, Start_time,kill_count,
(select sum(kill_count) from Level_details as l1
where l1.P_id = l2.P_id and date (l1.Start_time) = date(l2.Start_time)) as 
total_kill_counts
from Level_details as l2
order by P_id, Start_time) as l3;

/*12. Find the cumulative sum of stages crossed over
`start_datetime` for each `P_ID`, excluding the most
recent `start_datetime`.*/

with start_date_time as (
select Start_time, P_id, Stage_crossed, sum(Stage_crossed)
over(partition by P_id order by Start_time asc) as sum_stages,
row_number() over (partition by P_id order by Start_time asc) as rnk
from Level_Details)
select Start_time, P_id, sum_stages,Stage_crossed,rnk
from start_date_time
where rnk != 1;


/*13. Extract the top 3 highest sums of scores for each
`Dev_ID` and the corresponding `P_ID`.*/

with top_3_score as (
select P_id, Dev_id, sum(score) as sum_of_score,
row_number() over (partition by Dev_id order by sum(score)desc) as rnk
from Level_Details
group by P_id, Dev_id)
select P_id, Dev_id, sum_of_score, rnk
from top_3_score
where rnk <=3;

/* 14. Find players who scored more than 50% of the
average score, scored by the sum of scores for each
`P_ID`.*/

select P_id, sum(score) as sum_score, round(avg(score),0) as avg_score
from Level_Details
group by P_id
having sum(score) > avg(score) * 0.5;

/*15. Create a stored procedure to find the top `n`
`headshots_count` based on each `Dev_ID` and rank
them in increasing order using `Row_Number`. Display
the difficulty as well*/

DELIMITER //
Create Procedure Getheadshots_count()
Begin
with a as(
select P_id, Dev_id, head_shots_count,
row_number() over (partition by Dev_id order by  head_shots_count desc) as 
rnk, difficulty
from Level_Details)
select P_id, Dev_id, head_shots_count, rnk, difficulty
from a;
end//
DELIMITER ;
call Getheadshots_count();


