/* CityBike Phase 7 — Business questions from student brief (Q1–Q7)
   READ-ONLY. Run in SSMS on CityBikeDW after Phase 6 ETL.
   These queries return live results; this file does not invent numbers.
*/
USE CityBikeDW;
SET NOCOUNT ON;

-- Q0 baseline (brief expects initial load revenue 60,184.80 and 19,577 trips)
SELECT COUNT(*) AS trips, CAST(SUM(fee) AS DECIMAL(18,2)) AS revenue
FROM dw.fact_trips;

-- Q1: Trips and revenue by calendar month
SELECT d.year_num AS [year],d.month_num AS [month], COUNT(*) AS trips,
 CAST(SUM(f.fee) AS DECIMAL(18,2)) AS revenue
FROM dw.fact_trips f JOIN dw.dim_date d ON f.date_key=d.date_key
GROUP BY d.year_num,d.month_num ORDER BY d.year_num,d.month_num;

-- Q2: Average duration and distance per membership plan (historically accurate surrogate key)
SELECT m.membership_type,COUNT(*) AS trips,
 CAST(AVG(CAST(f.duration_minutes AS DECIMAL(18,3))) AS DECIMAL(18,2)) AS avg_duration_min,
 CAST(AVG(CAST(f.distance_km AS DECIMAL(18,3))) AS DECIMAL(18,2)) AS avg_distance_km
FROM dw.fact_trips f JOIN dw.dim_members m ON m.member_key=f.member_key
GROUP BY m.membership_type ORDER BY trips DESC;

-- Q3: Five busiest start stations (brief expects initial #1 Station 01 Riverside, 3911 trips)
SELECT TOP (5) s.station_name,s.district,COUNT(*) AS trips
FROM dw.fact_trips f JOIN dw.dim_stations s ON s.station_key=f.start_station_key
GROUP BY s.station_key,s.station_name,s.district
ORDER BY COUNT(*) DESC,s.station_name;

-- Q4: Percentage of trips on electric bikes
SELECT COUNT(*) AS total_trips,
 SUM(CASE WHEN b.bike_type='electric' THEN 1 ELSE 0 END) AS electric_trips,
 CAST(100.0*SUM(CASE WHEN b.bike_type='electric' THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,2)) AS electric_pct
FROM dw.fact_trips f JOIN dw.dim_bikes b ON b.bike_key=f.bike_key;

-- Q5: Start district generating most revenue
SELECT s.district, COUNT(*) AS trips,CAST(SUM(f.fee) AS DECIMAL(18,2)) AS revenue
FROM dw.fact_trips f JOIN dw.dim_stations s ON s.station_key=f.start_station_key
GROUP BY s.district ORDER BY revenue DESC;

-- Q6: Trips before/after first plan change for members whose plan changed
WITH change_date AS (
 SELECT member_id,MIN(valid_from) AS first_change_at
 FROM dw.dim_members WHERE member_key<>0 AND valid_to IS NULL
 AND EXISTS (SELECT 1 FROM dw.dim_members old
             WHERE old.member_id=dw.dim_members.member_id AND old.valid_to IS NOT NULL)
 GROUP BY member_id
)
SELECT c.member_id,
 SUM(CASE WHEN f.start_ts<c.first_change_at THEN 1 ELSE 0 END) AS trips_before,
 SUM(CASE WHEN f.start_ts>=c.first_change_at THEN 1 ELSE 0 END) AS trips_after
FROM change_date c
JOIN dw.dim_members m ON m.member_id=c.member_id AND m.member_key<>0
JOIN dw.fact_trips f ON f.member_key=m.member_key
GROUP BY c.member_id ORDER BY c.member_id;

-- Q7: Trips by period of day
SELECT h.day_part, COUNT(*) AS trips,CAST(SUM(f.fee) AS DECIMAL(18,2)) AS revenue
FROM dw.fact_trips f JOIN dw.dim_time_of_day h ON h.hour_key=f.hour_key
GROUP BY h.day_part ORDER BY trips DESC;
