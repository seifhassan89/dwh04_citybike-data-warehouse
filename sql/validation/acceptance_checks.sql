/* CityBike DW — Phase 6 & Phase 7 acceptance checks
   Source: student/01_mini_project_brief.md
   READ-ONLY SQL. Execute in SSMS on CityBikeDW.
   Set @AfterChange=0 before citybike_changes_pg.sql; set =1 after change ETL.
   Checks report PASS/FAIL; they do NOT repair data.
*/
USE CityBikeDW;
SET NOCOUNT ON;
DECLARE @AfterChange BIT = 1; -- CHANGE TO 0 FOR INITIAL LOAD
DECLARE @ExpectedStn INT = CASE WHEN @AfterChange=1 THEN 28 ELSE 25 END;
DECLARE @ExpectedMemStg INT = CASE WHEN @AfterChange=1 THEN 515 ELSE 510 END;
DECLARE @ExpectedTripsStg INT = CASE WHEN @AfterChange=1 THEN 20300 ELSE 20000 END;
DECLARE @ExpectedFact INT = CASE WHEN @AfterChange=1 THEN 19877 ELSE 19577 END;
DECLARE @ExpectedMembers INT = CASE WHEN @AfterChange=1 THEN 546 ELSE 501 END; -- after: 505 real current + 40 history + 1 unknown
DECLARE @ExpectedCurrent INT = CASE WHEN @AfterChange=1 THEN 505 ELSE 500 END;
DECLARE @ExpectedHist INT = CASE WHEN @AfterChange=1 THEN 40 ELSE 0 END;

SELECT 'stg.stg_stations' AS check_name, COUNT(*) AS actual_count,@ExpectedStn AS expected_count,
 CASE WHEN COUNT(*)=@ExpectedStn THEN 'PASS' ELSE 'FAIL' END AS result FROM stg.stg_stations
UNION ALL SELECT 'stg.stg_bikes',COUNT(*),120,CASE WHEN COUNT(*)=120 THEN 'PASS' ELSE 'FAIL' END FROM stg.stg_bikes
UNION ALL SELECT 'stg.stg_members',COUNT(*),@ExpectedMemStg,CASE WHEN COUNT(*)=@ExpectedMemStg THEN 'PASS' ELSE 'FAIL' END FROM stg.stg_members
UNION ALL SELECT 'stg.stg_trips',COUNT(*),@ExpectedTripsStg,CASE WHEN COUNT(*)=@ExpectedTripsStg THEN 'PASS' ELSE 'FAIL' END FROM stg.stg_trips
UNION ALL SELECT 'dw.dim_stations',COUNT(*),@ExpectedStn+1,CASE WHEN COUNT(*)=@ExpectedStn+1 THEN 'PASS' ELSE 'FAIL' END FROM dw.dim_stations
UNION ALL SELECT 'dw.dim_bikes',COUNT(*),121,CASE WHEN COUNT(*)=121 THEN 'PASS' ELSE 'FAIL' END FROM dw.dim_bikes
UNION ALL SELECT 'dw.dim_members',COUNT(*),@ExpectedMembers,CASE WHEN COUNT(*)=@ExpectedMembers THEN 'PASS' ELSE 'FAIL' END FROM dw.dim_members
UNION ALL SELECT 'dw.fact_trips',COUNT(*),@ExpectedFact,CASE WHEN COUNT(*)=@ExpectedFact THEN 'PASS' ELSE 'FAIL' END FROM dw.fact_trips;

SELECT 'member_current_real' AS check_name,
 SUM(CASE WHEN member_key<>0 AND valid_to IS NULL THEN 1 ELSE 0 END) AS actual_count,
 @ExpectedCurrent AS expected_count,
 CASE WHEN SUM(CASE WHEN member_key<>0 AND valid_to IS NULL THEN 1 ELSE 0 END)=@ExpectedCurrent THEN 'PASS' ELSE 'FAIL' END AS result
FROM dw.dim_members
UNION ALL
SELECT 'member_history_real',
 SUM(CASE WHEN member_key<>0 AND valid_to IS NOT NULL THEN 1 ELSE 0 END),@ExpectedHist,
 CASE WHEN SUM(CASE WHEN member_key<>0 AND valid_to IS NOT NULL THEN 1 ELSE 0 END)=@ExpectedHist THEN 'PASS' ELSE 'FAIL' END
FROM dw.dim_members;

SELECT 'UNKNOWN_member' AS check_name,COUNT(*) AS actual_count,1 AS expected_count,
 CASE WHEN COUNT(*)=1 THEN 'PASS' ELSE 'FAIL' END AS result FROM dw.dim_members WHERE member_key=0
UNION ALL SELECT 'UNKNOWN_bike',COUNT(*),1,CASE WHEN COUNT(*)=1 THEN 'PASS' ELSE 'FAIL' END FROM dw.dim_bikes WHERE bike_key=0
UNION ALL SELECT 'UNKNOWN_station',COUNT(*),1,CASE WHEN COUNT(*)=1 THEN 'PASS' ELSE 'FAIL' END FROM dw.dim_stations WHERE station_key=0;

-- All following diagnostic queries should return ZERO rows, unless explicitly described.
-- A member should have at most one current version.
SELECT 'multiple_current_member_versions' AS issue,CAST(member_id AS NVARCHAR(100)) AS reference,COUNT(*) AS occurrences
FROM dw.dim_members WHERE valid_to IS NULL AND member_key<>0
GROUP BY member_id HAVING COUNT(*)>1;

-- No invalid or overlapping intervals, including overlapping historical versions.
SELECT 'bad_scd_interval' AS issue,CAST(member_id AS NVARCHAR(100)) AS reference, member_key,valid_from,valid_to
FROM dw.dim_members WHERE member_key<>0 AND valid_to IS NOT NULL AND valid_to<=valid_from;

SELECT 'overlapping_member_versions' AS issue,CAST(a.member_id AS NVARCHAR(100)) AS reference,a.member_key AS first_key,b.member_key AS second_key
FROM dw.dim_members a JOIN dw.dim_members b ON a.member_id=b.member_id AND a.member_key<b.member_key
WHERE a.member_key<>0 AND b.member_key<>0
 AND a.valid_from < COALESCE(b.valid_to,CONVERT(datetime2,'99991231'))
 AND b.valid_from < COALESCE(a.valid_to,CONVERT(datetime2,'99991231'));

-- Every non-unknown fact FK must resolve to a dimension record.
SELECT 'orphan_member_key' AS issue,CAST(f.trip_id AS NVARCHAR(100)) AS reference FROM dw.fact_trips f
LEFT JOIN dw.dim_members m ON m.member_key=f.member_key WHERE m.member_key IS NULL
UNION ALL SELECT 'orphan_bike_key',CAST(f.trip_id AS NVARCHAR(100)) FROM dw.fact_trips f
LEFT JOIN dw.dim_bikes b ON b.bike_key=f.bike_key WHERE b.bike_key IS NULL
UNION ALL SELECT 'orphan_start_station_key',CAST(f.trip_id AS NVARCHAR(100)) FROM dw.fact_trips f
LEFT JOIN dw.dim_stations s ON s.station_key=f.start_station_key WHERE s.station_key IS NULL
UNION ALL SELECT 'orphan_end_station_key',CAST(f.trip_id AS NVARCHAR(100)) FROM dw.fact_trips f
LEFT JOIN dw.dim_stations s ON s.station_key=f.end_station_key WHERE s.station_key IS NULL
UNION ALL SELECT 'orphan_date_key',CAST(f.trip_id AS NVARCHAR(100)) FROM dw.fact_trips f
LEFT JOIN dw.dim_date d ON d.date_key=f.date_key WHERE d.date_key IS NULL
UNION ALL SELECT 'orphan_hour_key',CAST(f.trip_id AS NVARCHAR(100)) FROM dw.fact_trips f
LEFT JOIN dw.dim_time_of_day h ON h.hour_key=f.hour_key WHERE h.hour_key IS NULL;

-- If a trip has an existing member at start_ts, stored member_key must match historical version.
SELECT f.trip_id,t.member_id,f.start_ts,f.member_key AS stored_key,m.member_key AS expected_key
FROM dw.fact_trips f JOIN stg.stg_trips t ON t.trip_id=f.trip_id
CROSS APPLY (SELECT TOP 1 d.member_key FROM dw.dim_members d
 WHERE d.member_id=t.member_id AND d.member_key<>0 AND d.valid_from<=f.start_ts
 AND (d.valid_to IS NULL OR f.start_ts<d.valid_to)
 ORDER BY d.valid_from DESC,d.member_key DESC) m
WHERE f.member_key<>m.member_key;

-- Trips whose source member doesn't match any historical version must use key 0.
SELECT f.trip_id,t.member_id,f.member_key
FROM dw.fact_trips f JOIN stg.stg_trips t ON t.trip_id=f.trip_id
WHERE NOT EXISTS(SELECT 1 FROM dw.dim_members m WHERE m.member_id=t.member_id AND m.member_key<>0
 AND m.valid_from<=f.start_ts AND (m.valid_to IS NULL OR f.start_ts<m.valid_to)) AND f.member_key<>0;

-- Valid completed trips cannot be cancelled, and should not have invalid distance or duration.
SELECT f.trip_id,t.status,f.distance_km,f.duration_minutes
FROM dw.fact_trips f JOIN stg.stg_trips t ON t.trip_id=f.trip_id
WHERE t.status<>'completed' OR f.distance_km IS NULL OR f.distance_km<=0 OR f.duration_minutes<0;

-- Key post-change business checks
SELECT COUNT(*) AS total_fact_trips,CAST(SUM(fee) AS DECIMAL(18,2)) AS total_revenue,
 SUM(CASE WHEN member_key=0 THEN 1 ELSE 0 END) AS unknown_member_trips,
 SUM(CASE WHEN end_station_key=0 THEN 1 ELSE 0 END) AS unknown_end_station_trips
FROM dw.fact_trips;
-- At initial load: 19,577 trips; 60,184.80 revenue; unknown member 12; unknown end station 6.

SELECT source_table,reject_reason,COUNT(*) AS rows_rejected
FROM etl.reject GROUP BY source_table,reject_reason ORDER BY source_table,reject_reason;
SELECT TOP (20) run_id,job_name,status,started_at,finished_at,rows_read,rows_loaded,rows_rejected,message
FROM etl.run_log ORDER BY run_id DESC;
