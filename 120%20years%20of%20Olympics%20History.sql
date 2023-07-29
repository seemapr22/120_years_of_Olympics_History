-- 120 years of Olympics History --


-- To write and understand SQL queries, first thing is to understand the dataset. 
-- After understanding the dataset, it becomes much simpler to write SQL Queries to retrieve any information from that data.

-- Here, I have tried to write SQL Queries on a real dataset. I have downloaded the 120 years of Olympics History dataset from Kaggle. 
-- This way instead of using cooked up data, I have used real data to write my SQL Queries. 
-- By understanding these queries, we can easily retrieve the information from other types of problems also.



--1. total olympics games that have been held till 2016-- 

SELECT COUNT(DISTINCT games) AS total_olympic_games
FROM OLYMPICS_HISTORY;

--2. total no of nations who participated in each olympics game-- 
    
WITH all_countries AS 
	(SELECT games, nr.region
	FROM OLYMPICS_HISTORY oh
	JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc = oh.noc
	GROUP BY games, nr.region)
SELECT games, COUNT(1) AS total_countries
FROM all_countries
GROUP BY games
ORDER BY games;

--3. year in which highest and lowest no of countries participated--

with all_countries as
    (select games, nr.region
    from olympics_history oh
    join olympics_history_noc_regions nr ON nr.noc=oh.noc
    group by games, nr.region),
    
    tot_countries as
    (select games, count(1) as total_countries
    from all_countries
    group by games)

SELECT 
    MAX(games) || ' - ' || MAX(total_countries) AS highest_countries,
    MIN(games) || ' - ' || MIN(total_countries) AS lowest_countries
FROM tot_countries;
 
--4. Sport which was played in all summer olympics--

SELECT SPORT, COUNT(SPORT) FROM (SELECT SPORT, YEAR,
COUNT(*) FROM OLYMPICS_HISTORY GROUP BY SPORT, YEAR)
GROUP BY SPORT
HAVING COUNT(SPORT)=(SELECT COUNT(*) FROM (SELECT
DISTINCT YEAR FROM OLYMPICS_HISTORY WHERE SEASON= 'Summer')); 

--5. sports which were played in all summer olympics--

with t1 as
          	(select count(distinct games) as total_games
          	from olympics_history where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from olympics_history where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;

--6. Sports that were just played only once in the olympics-- 

with t1 as
	(select distinct games, sport
    from olympics_history),
t2 as
    (select sport, count(1) as no_of_games
    from t1
    group by sport)
select t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.sport;

--7. total no of sports played in each olympic games--

WITH t1 AS
	(SELECT DISTINCT games, sport
	FROM OLYMPICS_HISTORY 
	ORDER BY games)
SELECT games, COUNT(*) AS no_of_games
FROM t1
GROUP BY games
ORDER BY games;

--8. oldest athletes to win a gold medal--

with temp as
            (select name, sex, cast(case when age = 'NA' then '0' else age end as int) as age,
            team, games, city, sport, event, medal
            from olympics_history),
        ranking as
            (select *, rank() over(order by age desc) as rnk
            from temp
            where medal='Gold')
    select *
    from ranking
    where rnk = 1;
    
--9. Ratio of male and female athletes who participated in all olympic games--

WITH t1 AS (
    SELECT sex, count(1) AS cnt
    FROM olympics_history
    GROUP BY sex
	),
	t2 AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY cnt) AS rn
    FROM t1
	),
	min_cnt AS (
	SELECT cnt FROM t2 WHERE rn = 1
	),
	max_cnt AS (
    SELECT cnt FROM t2 WHERE rn = 2
	)
SELECT CONCAT('1 : ', ROUND(CAST(max_cnt.cnt AS DECIMAL(18, 2)) / CAST(min_cnt.cnt AS DECIMAL(18, 2)), 2)) AS ratio
FROM min_cnt, max_cnt;

--10. top 5 athletes who have won the most gold medals--

 with t1 as (
            select name, team, count(1) as total_gold_medals
            from olympics_history
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc
            ),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;

--11. top 5 athletes who have won the most medals (gold/silver/bronze)--
    
WITH t1 AS 
	(SELECT name, team, count(*) AS total_medals
	FROM OLYMPICS_HISTORY 
	WHERE medal <> 'NA'
	GROUP BY name, team
	ORDER BY total_medals DESC),
t2 AS 
	(SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rnk
	FROM t1)
SELECT name, team, total_medals
FROM t2
WHERE rnk <=5; 

--12. top 5 most successful countries in olympics (Success is defined by no of medals won)--

WITH t1 AS 
	(SELECT nr.region, COUNT(*) AS total_medals
	FROM OLYMPICS_HISTORY oh
	JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
	WHERE oh.medal <> 'NA'
	GROUP BY nr.region
	ORDER BY total_medals DESC),
t2 AS 
	(SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rnk
	FROM t1)
SELECT *
FROM t2
WHERE rnk<=5;

--13. total gold, silver and bronze medals won by each country--

SELECT country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN total_medals END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN total_medals END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN total_medals END), 0) AS bronze
FROM (
    SELECT 
        nr.region as country, medal,
        COUNT(1) as total_medals
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE medal <> 'NA'
    GROUP BY nr.region, medal
) AS MedalCounts
GROUP BY country
ORDER BY gold DESC, silver DESC, bronze DESC;

--14. total gold, silver and bronze medals won by each country corresponding to each olympic games--

SELECT games, country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN total_medals END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN total_medals END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN total_medals END), 0) AS bronze
FROM (
    SELECT 
        games,
        nr.region as country,
        medal,
        COUNT(1) as total_medals
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE medal <> 'NA'
    GROUP BY games, nr.region, medal
) AS MedalCounts
GROUP BY games, country
ORDER BY games; 

--15. country that won the most gold, most silver and most bronze medals in each olympic games--

WITH MedalCounts AS (
    SELECT 
        games,
        nr.region AS country,
        medal,
        COUNT(1) AS total_medals
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE medal <> 'NA'
    GROUP BY games, nr.region, medal
)
SELECT DISTINCT
    games,
    MAX(country_gold) || ' - ' || MAX(gold) AS Max_Gold,
    MAX(country_silver) || ' - ' || MAX(silver) AS Max_Silver,
    MAX(country_bronze) || ' - ' || MAX(bronze) AS Max_Bronze
FROM (
    SELECT
        games,
        country,
        CASE WHEN medal = 'Gold' THEN total_medals END AS gold,
        CASE WHEN medal = 'Silver' THEN total_medals END AS silver,
        CASE WHEN medal = 'Bronze' THEN total_medals END AS bronze,
        FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY CASE WHEN medal = 'Gold' THEN total_medals END DESC) AS country_gold,
        FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY CASE WHEN medal = 'Silver' THEN total_medals END DESC) AS country_silver,
        FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY CASE WHEN medal = 'Bronze' THEN total_medals END DESC) AS country_bronze
    FROM MedalCounts
) AS MedalCountsRanked
GROUP BY games;

--16. countries those have never won gold medal but have won silver/bronze medals--

SELECT region,
       COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold_medal,
       COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver_medal,
       COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze_medal
FROM OLYMPICS_HISTORY oh
JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc = oh.noc
GROUP BY region
HAVING COUNT(CASE WHEN medal = 'Gold' THEN medal END) = 0
ORDER BY Silver_medal DESC;

--17. Sport/event in which India has won highest medals--
    
WITH t1 AS (
	SELECT sport, COUNT(*) AS total_medals
	FROM OLYMPICS_HISTORY 
	WHERE medal <> 'NA'
	AND team = 'India'
	GROUP BY sport
	ORDER BY total_medals DESC
	),
	t2 AS (
		SELECT *, RANK() OVER (ORDER BY total_medals DESC) AS rnk
		FROM t1
		)
SELECT sport, total_medals
FROM t2
WHERE rnk = 1;

--18. all olympic games where India won medal for Hockey--

SELECT games, team, sport, count(*) AS total_medals
FROM OLYMPICS_HISTORY 
WHERE medal <> 'NA'
AND team = 'India' AND sport = 'Hockey'
GROUP BY team, sport, games
ORDER BY total_medals DESC;
      






















	
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 





























--1. total olympics games that have been held till 2016-- 

SELECT COUNT(DISTINCT games) AS total_olympic_games
FROM OLYMPICS_HISTORY;

--2. total no of nations who participated in each olympics game-- 
    
WITH all_countries AS 
	(SELECT games, nr.region
	FROM OLYMPICS_HISTORY oh
	JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc = oh.noc
	GROUP BY games, nr.region)
SELECT games, COUNT(1) AS total_countries
FROM all_countries
GROUP BY games
ORDER BY games;

--3. year in which highest and lowest no of countries participated--

with all_countries as
    (select games, nr.region
    from olympics_history oh
    join olympics_history_noc_regions nr ON nr.noc=oh.noc
    group by games, nr.region),
    
    tot_countries as
    (select games, count(1) as total_countries
    from all_countries
    group by games)

SELECT 
    MAX(games) || ' - ' || MAX(total_countries) AS highest_countries,
    MIN(games) || ' - ' || MIN(total_countries) AS lowest_countries
FROM tot_countries;
 
--4. Sport which was played in all summer olympics--

SELECT SPORT, COUNT(SPORT) FROM (SELECT SPORT, YEAR,
COUNT(*) FROM OLYMPICS_HISTORY GROUP BY SPORT, YEAR)
GROUP BY SPORT
HAVING COUNT(SPORT)=(SELECT COUNT(*) FROM (SELECT
DISTINCT YEAR FROM OLYMPICS_HISTORY WHERE SEASON= 'Summer')); 

--5. sports which were played in all summer olympics--

with t1 as
          	(select count(distinct games) as total_games
          	from olympics_history where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from olympics_history where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select *
      from t3
      join t1 on t1.total_games = t3.no_of_games;

--6. Sports that were just played only once in the olympics-- 

with t1 as
	(select distinct games, sport
    from olympics_history),
t2 as
    (select sport, count(1) as no_of_games
    from t1
    group by sport)
select t2.*, t1.games
from t2
join t1 on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.sport;

--7. total no of sports played in each olympic games--

WITH t1 AS
	(SELECT DISTINCT games, sport
	FROM OLYMPICS_HISTORY 
	ORDER BY games)
SELECT games, COUNT(*) AS no_of_games
FROM t1
GROUP BY games
ORDER BY games;

--8. oldest athletes to win a gold medal--

with temp as
            (select name, sex, cast(case when age = 'NA' then '0' else age end as int) as age,
            team, games, city, sport, event, medal
            from olympics_history),
        ranking as
            (select *, rank() over(order by age desc) as rnk
            from temp
            where medal='Gold')
    select *
    from ranking
    where rnk = 1;
    
--9. Ratio of male and female athletes who participated in all olympic games--

WITH t1 AS (
    SELECT sex, count(1) AS cnt
    FROM olympics_history
    GROUP BY sex
	),
	t2 AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY cnt) AS rn
    FROM t1
	),
	min_cnt AS (
	SELECT cnt FROM t2 WHERE rn = 1
	),
	max_cnt AS (
    SELECT cnt FROM t2 WHERE rn = 2
	)
SELECT CONCAT('1 : ', ROUND(CAST(max_cnt.cnt AS DECIMAL(18, 2)) / CAST(min_cnt.cnt AS DECIMAL(18, 2)), 2)) AS ratio
FROM min_cnt, max_cnt;

--10. top 5 athletes who have won the most gold medals--

 with t1 as (
            select name, team, count(1) as total_gold_medals
            from olympics_history
            where medal = 'Gold'
            group by name, team
            order by total_gold_medals desc
            ),
        t2 as
            (select *, dense_rank() over (order by total_gold_medals desc) as rnk
            from t1)
    select name, team, total_gold_medals
    from t2
    where rnk <= 5;

--11. top 5 athletes who have won the most medals (gold/silver/bronze)--
    
WITH t1 AS 
	(SELECT name, team, count(*) AS total_medals
	FROM OLYMPICS_HISTORY 
	WHERE medal <> 'NA'
	GROUP BY name, team
	ORDER BY total_medals DESC),
t2 AS 
	(SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rnk
	FROM t1)
SELECT name, team, total_medals
FROM t2
WHERE rnk <=5; 

--12. top 5 most successful countries in olympics (Success is defined by no of medals won)--

WITH t1 AS 
	(SELECT nr.region, COUNT(*) AS total_medals
	FROM OLYMPICS_HISTORY oh
	JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
	WHERE oh.medal <> 'NA'
	GROUP BY nr.region
	ORDER BY total_medals DESC),
t2 AS 
	(SELECT *, DENSE_RANK() OVER (ORDER BY total_medals DESC) AS rnk
	FROM t1)
SELECT *
FROM t2
WHERE rnk<=5;

--13. total gold, silver and bronze medals won by each country--

SELECT country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN total_medals END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN total_medals END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN total_medals END), 0) AS bronze
FROM (
    SELECT 
        nr.region as country, medal,
        COUNT(1) as total_medals
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE medal <> 'NA'
    GROUP BY nr.region, medal
) AS MedalCounts
GROUP BY country
ORDER BY gold DESC, silver DESC, bronze DESC;

--14. total gold, silver and bronze medals won by each country corresponding to each olympic games--

SELECT games, country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN total_medals END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN total_medals END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN total_medals END), 0) AS bronze
FROM (
    SELECT 
        games,
        nr.region as country,
        medal,
        COUNT(1) as total_medals
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE medal <> 'NA'
    GROUP BY games, nr.region, medal
) AS MedalCounts
GROUP BY games, country
ORDER BY games; 

--15. country that won the most gold, most silver and most bronze medals in each olympic games--

WITH MedalCounts AS (
    SELECT 
        games,
        nr.region AS country,
        medal,
        COUNT(1) AS total_medals
    FROM olympics_history oh
    JOIN olympics_history_noc_regions nr ON nr.noc = oh.noc
    WHERE medal <> 'NA'
    GROUP BY games, nr.region, medal
)
SELECT DISTINCT
    games,
    MAX(country_gold) || ' - ' || MAX(gold) AS Max_Gold,
    MAX(country_silver) || ' - ' || MAX(silver) AS Max_Silver,
    MAX(country_bronze) || ' - ' || MAX(bronze) AS Max_Bronze
FROM (
    SELECT
        games,
        country,
        CASE WHEN medal = 'Gold' THEN total_medals END AS gold,
        CASE WHEN medal = 'Silver' THEN total_medals END AS silver,
        CASE WHEN medal = 'Bronze' THEN total_medals END AS bronze,
        FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY CASE WHEN medal = 'Gold' THEN total_medals END DESC) AS country_gold,
        FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY CASE WHEN medal = 'Silver' THEN total_medals END DESC) AS country_silver,
        FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY CASE WHEN medal = 'Bronze' THEN total_medals END DESC) AS country_bronze
    FROM MedalCounts
) AS MedalCountsRanked
GROUP BY games;

--16. countries those have never won gold medal but have won silver/bronze medals--

SELECT region,
       COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold_medal,
       COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver_medal,
       COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze_medal
FROM OLYMPICS_HISTORY oh
JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc = oh.noc
GROUP BY region
HAVING COUNT(CASE WHEN medal = 'Gold' THEN medal END) = 0
ORDER BY Silver_medal DESC;

--17. Sport/event in which India has won highest medals--
    
WITH t1 AS (
	SELECT sport, COUNT(*) AS total_medals
	FROM OLYMPICS_HISTORY 
	WHERE medal <> 'NA'
	AND team = 'India'
	GROUP BY sport
	ORDER BY total_medals DESC
	),
	t2 AS (
		SELECT *, RANK() OVER (ORDER BY total_medals DESC) AS rnk
		FROM t1
		)
SELECT sport, total_medals
FROM t2
WHERE rnk = 1;

--18. all olympic games where India won medal for Hockey--

SELECT games, team, sport, count(*) AS total_medals
FROM OLYMPICS_HISTORY 
WHERE medal <> 'NA'
AND team = 'India' AND sport = 'Hockey'
GROUP BY team, sport, games
ORDER BY total_medals DESC;
    	
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 





