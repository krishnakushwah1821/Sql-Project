use ipl;
-- 1st que
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ball_by_ball';

-- 2nd que
SELECT SUM(bb.Runs_Scored + IFNULL(er.Extra_Runs, 0)) AS Total_Runs_RCB_Season1
FROM ball_by_ball bb
JOIN matches m ON bb.Match_Id = m.Match_Id
JOIN team t ON bb.Team_Batting = t.Team_Id
LEFT JOIN extra_runs er ON bb.Match_Id = er.Match_Id 
AND bb.Over_Id = er.Over_Id 
AND bb.Ball_Id = er.Ball_Id
WHERE t.Team_Name = 'Royal Challengers Bangalore'
AND m.Season_Id = 1;




-- 3rd que
SELECT COUNT(*) AS Players_Above_25
FROM Player
WHERE TIMESTAMPDIFF(YEAR, DOB, '2014-04-16') > 25;

-- 4th que 
SELECT COUNT(*) AS RCB_Wins_2013
FROM Matches m
JOIN Team t ON m.Match_Winner = t.Team_Id
WHERE m.Season_Id = 6
AND t.Team_Name = 'Royal Challengers Bangalore'; 

-- 5th que
SELECT p.Player_Name, ROUND(AVG(b.Striker), 2) AS Average_Strike_Rate
FROM Ball_by_Ball b
JOIN Matches m ON b.Match_Id = m.Match_Id
JOIN Player p ON b.Striker = p.Player_Id
WHERE m.Season_Id >= (SELECT MAX(Season_Id) - 3 FROM Matches)  
GROUP BY p.Player_Name
ORDER BY Average_Strike_Rate DESC
LIMIT 10; 

-- 6th que 
SELECT p.Player_Name, 
ROUND(AVG(b.Runs_Scored), 2) AS Average_Runs
FROM Ball_by_Ball b
JOIN Player p ON b.Striker = p.Player_Id
GROUP BY p.Player_Name
ORDER BY Average_Runs DESC;

-- 7th que
SELECT p.Player_Name, COUNT(wt.Player_Out) AS Total_Wickets, 
COUNT(DISTINCT wt.Match_Id) AS Total_Matches, 
COUNT(wt.Player_Out) / COUNT(DISTINCT wt.Match_Id) AS Average_Wickets_Per_Match
FROM wicket_taken wt
JOIN player p ON wt.Player_Out = p.Player_Id
GROUP BY p.Player_Name
ORDER BY Average_Wickets_Per_Match DESC;

-- 8th que


-- 1. Get average runs scored by each player (Striker)
WITH player_avg_runs AS (
    SELECT Striker AS Player_Id, AVG(Runs_Scored) AS Avg_Runs
    FROM ball_by_ball
    GROUP BY Striker
),

-- 2. Compute overall average of average runs
overall_avg_runs AS (
    SELECT AVG(Avg_Runs) AS Overall_Avg_Runs
    FROM (
        SELECT Striker,AVG(Runs_Scored) AS Avg_Runs
        FROM ball_by_ball
        GROUP BY Striker
    ) AS temp
),

-- 3. Count wickets taken by each player (Fielders)
player_wickets AS (
    SELECT Fielders AS Player_Id,COUNT(*) AS Total_Wickets
    FROM wicket_taken
    WHERE Fielders IS NOT NULL
    GROUP BY Fielders
),

-- 4. Compute overall average of wickets taken
overall_avg_wickets AS (
    SELECT AVG(Total_Wickets) AS Overall_Wickets
    FROM (
        SELECT Fielders,COUNT(*) AS Total_Wickets
        FROM wicket_taken
        WHERE Fielders IS NOT NULL
        GROUP BY Fielders
    ) AS temp
)

-- 5. Final output with player names
SELECT par.Player_Id,p.Player_Name,par.Avg_Runs,pw.Total_Wickets
FROM player_avg_runs par
JOIN player_wickets pw ON par.Player_Id = pw.Player_Id
JOIN player p ON par.Player_Id = p.Player_Id,
overall_avg_runs oar,overall_avg_wickets oaw
WHERE par.Avg_Runs > oar.Overall_Avg_Runs
AND pw.Total_Wickets > oaw.Overall_Wickets;

-- 9th que 

SELECT v.Venue_Name,
SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) AS Wins,
SUM(CASE WHEN (m.Team_1 = rcb.Team_Id OR m.Team_2 = rcb.Team_Id)
AND m.Match_Winner != rcb.Team_Id
AND m.Match_Winner IS NOT NULL THEN 1 ELSE 0
END) AS Losses
FROM matches m
JOIN team rcb ON rcb.Team_Name = 'Royal Challengers Bangalore'
JOIN venue v ON m.Venue_Id = v.Venue_Id
WHERE m.Team_1 = rcb.Team_Id OR m.Team_2 = rcb.Team_Id
GROUP BY v.Venue_Name;

-- 10th que
SELECT bs.Bowling_skill, COUNT(*) AS Total_Wickets
FROM wicket_taken wt
JOIN ball_by_ball bb 
ON wt.Match_Id = bb.Match_Id 
AND wt.Over_Id = bb.Over_Id 
AND wt.Ball_Id = bb.Ball_Id
JOIN bowling_style bs 
ON bb.Bowler = bs.Bowling_Id
GROUP BY bs.Bowling_skill
ORDER BY Total_Wickets DESC;

-- 11th que

WITH rcb_stats AS (
    SELECT s.Season_Year, SUM(bb.Runs_Scored) AS Runs,
	COUNT(wt.Player_Out) AS Wickets
    FROM matches m
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN player_match pm ON m.Match_Id = pm.Match_Id
    JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id AND bb.Team_Batting = pm.Team_Id
    LEFT JOIN wicket_taken wt 
	ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id
    JOIN team t ON pm.Team_Id = t.Team_Id
    WHERE t.Team_Name = 'Royal Challengers Bangalore'
    GROUP BY s.Season_Year
),
compare AS (
    SELECT curr.Season_Year,curr.Runs,curr.Wickets,prev.Runs AS Prev_Runs,
	prev.Wickets AS Prev_Wickets,
	CASE 
	WHEN curr.Runs > prev.Runs AND curr.Wickets > prev.Wickets 
	THEN 'Improved' 
	ELSE 'Not Improved' 
	END AS Performance
    FROM rcb_stats curr
    JOIN rcb_stats prev ON curr.Season_Year = prev.Season_Year + 1
)
SELECT * FROM compare;

-- 12th que 
SELECT p.Player_Name, 
SUM(bb.runs_Scored) AS Total_Runs
FROM ball_by_ball bb
JOIN player p ON bb.Striker = p.Player_Id
JOIN matches m ON bb.Match_Id = m.Match_Id
JOIN team t ON t.Team_Id = bb.Team_Batting
WHERE t.Team_Name = 'Royal Challengers Bangalore'
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC
LIMIT 5;

-- 13th que
SELECT 'Male' AS Gender, v.Venue_Name,
AVG(wt_count.Total_Wickets) AS Avg_Wickets,
RANK() OVER (PARTITION BY v.Venue_Name ORDER BY AVG(wt_count.Total_Wickets) DESC) AS Gender_Rank
FROM (
SELECT bb.Bowler, m.Venue_Id,
COUNT(*) AS Total_Wickets
FROM wicket_taken wt
JOIN ball_by_ball bb 
ON wt.Match_Id = bb.Match_Id 
AND wt.Over_Id = bb.Over_Id 
AND wt.Ball_Id = bb.Ball_Id
JOIN matches m ON wt.Match_Id = m.Match_Id
GROUP BY bb.Bowler, m.Venue_Id
) AS wt_count
JOIN venue v ON wt_count.Venue_Id = v.Venue_Id
GROUP BY v.Venue_Name
ORDER BY v.Venue_Name, Avg_Wickets DESC;

-- Subjective ques
-- 1st que

SELECT t1.Team_Name AS Toss_Winner,
t2.Team_Name AS Match_Winner,v.Venue_Name,
CASE WHEN m.Toss_Winner = m.Match_Winner THEN 'Toss Winner Won'
ELSE 'Toss Winner Lost'
END AS Toss_Result
FROM matches m
JOIN team t1 ON m.Toss_Winner = t1.Team_Id
JOIN team t2 ON m.Match_Winner = t2.Team_Id
JOIN venue v ON m.Venue_Id = v.Venue_Id;

-- 2nd que

SELECT p.Player_Name, 
SUM(bb.Runs_Scored) AS Total_Runs
FROM ball_by_ball bb
JOIN player p ON bb.Striker = p.Player_Id
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC
LIMIT 10;

-- 4th que 
WITH batting_stats AS (
SELECT
Striker AS Player_Id,
SUM(Runs_Scored) AS Total_Runs
FROM ball_by_ball
GROUP BY Striker
),
bowling_stats AS (
SELECT
b.Bowler AS Player_Id,
COUNT(*) AS Total_Wickets
FROM wicket_taken w
JOIN ball_by_ball b 
ON w.Match_Id = b.Match_Id 
AND w.Over_Id = b.Over_Id 
AND w.Ball_Id = b.Ball_Id
GROUP BY b.Bowler
HAVING COUNT(*) > 30
)
SELECT p.Player_Name, bat.Total_Runs,
bowl.Total_Wickets
FROM batting_stats bat
JOIN bowling_stats bowl ON bat.Player_Id = bowl.Player_Id
JOIN player p ON p.Player_Id = bat.Player_Id
ORDER BY Total_Runs DESC, Total_Wickets DESC
limit 10;

-- 5th que

-- Step 1: Get RCB's Team_Id
SELECT Team_Id FROM team WHERE Team_Name = 'Royal Challengers Bangalore';
-- Step 2: Main query
WITH rcb_matches AS (
SELECT Match_Id, Match_Winner
FROM matches
WHERE Team_1 = 3 OR Team_2 = 3
),
rcb_players_in_matches AS (
SELECT pm.Match_Id, pm.Player_Id
FROM player_match pm
WHERE pm.Team_Id = 3
),
player_win_stats AS (
SELECT p.Player_Name,
COUNT(DISTINCT pm.Match_Id) AS Matches_Played,
SUM(CASE WHEN m.Match_Winner = 3 THEN 1 ELSE 0 END) AS Matches_Won
FROM rcb_players_in_matches pm
JOIN rcb_matches m ON pm.Match_Id = m.Match_Id
JOIN player p ON pm.Player_Id = p.Player_Id
GROUP BY p.Player_Name
)
SELECT 
Player_Name,Matches_Played,Matches_Won,
ROUND((Matches_Won / Matches_Played) * 100, 2) AS Win_Percentage
FROM player_win_stats
ORDER BY Win_Percentage DESC, Matches_Played DESC
LIMIT 10;


-- 7th que 

SELECT v.Venue_Name,
ROUND(AVG(team_scores.Total_Runs), 2) AS Avg_Total_Runs
FROM (
SELECT Match_Id,
SUM(Runs_Scored) AS Total_Runs
FROM ball_by_ball
GROUP BY Match_Id
) AS team_scores
JOIN matches m ON team_scores.Match_Id = m.Match_Id
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY v.Venue_Name
ORDER BY Avg_Total_Runs DESC;

-- 8th que
-- Step 1: Find RCB's home venue(s)
SELECT Venue_Id, Venue_Name 
FROM venue 
WHERE City_Id IN (
SELECT City_Id 
FROM venue 
WHERE Venue_Name LIKE '%M Chinnaswamy Stadium%'  -- typical home ground of RCB
);
-- Step 2: Calculate home and away performance for RCB
SELECT v.Venue_Name,
COUNT(CASE WHEN m.Match_Winner = RCB.Team_Id THEN 1 END) AS Wins,
COUNT(CASE WHEN m.Match_Winner != RCB.Team_Id AND (m.Team_1 = RCB.Team_Id OR m.Team_2 = RCB.Team_Id) THEN 1 END) AS Losses,
COUNT(*) AS Total_Matches,
ROUND((COUNT(CASE WHEN m.Match_Winner = RCB.Team_Id THEN 1 END) / COUNT(*)) * 100, 2) AS Win_Percentage
FROM matches m
JOIN venue v ON m.Venue_Id = v.Venue_Id
JOIN team RCB ON RCB.Team_Name = 'Royal Challengers Bangalore'
WHERE m.Team_1 = RCB.Team_Id OR m.Team_2 = RCB.Team_Id
GROUP BY v.Venue_Name
ORDER BY Win_Percentage DESC;

-- 9th que
SELECT s.Season_Year,
SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) AS Wins,
SUM(CASE WHEN m.Match_Winner != rcb.Team_Id AND (m.Team_1 = rcb.Team_Id OR m.Team_2 = rcb.Team_Id) THEN 1 ELSE 0 END) AS Losses,
COUNT(*) AS Total_Matches
FROM matches m
JOIN season s ON m.Season_Id = s.Season_Id
JOIN team rcb ON rcb.Team_Name = 'Royal Challengers Bangalore'
WHERE m.Team_1 = rcb.Team_Id OR m.Team_2 = rcb.Team_Id
GROUP BY s.Season_Year
ORDER BY s.Season_Year;

-- 11th que

SELECT m.Match_Id,
CASE 
WHEN t1.Team_Name = 'Delhi_Capitals' THEN 'Delhi_Daredevils'
ELSE t1.Team_Name
END AS Team_1,
CASE 
WHEN t2.Team_Name = 'Delhi_Capitals' THEN 'Delhi_Daredevils'
ELSE t2.Team_Name
END AS Team_2,
m.Match_Date,
m.Season_Id,
m.Venue_Id,
CASE 
WHEN tw.Team_Name = 'Delhi_Capitals' THEN 'Delhi_Daredevils'
ELSE tw.Team_Name
END AS Toss_Winner,
m.Toss_Decide,m.Win_Type,m.Win_Margin,m.Outcome_type,
CASE 
WHEN mw.Team_Name = 'Delhi_Capitals' THEN 'Delhi_Daredevils'
ELSE mw.Team_Name
END AS Match_Winner,
m.Man_of_the_Match
FROM matches m
JOIN team t1 ON m.Team_1 = t1.Team_Id
JOIN team t2 ON m.Team_2 = t2.Team_Id
JOIN team tw ON m.Toss_Winner = tw.Team_Id
JOIN team mw ON m.Match_Winner = mw.Team_Id;










