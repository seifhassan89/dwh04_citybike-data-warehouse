USE CityBikeDW;
GO
SET NOCOUNT ON;

-- DQ-01: Source staging to warehouse counts. No guessed expected targets.
SELECT 'stg.stg_stations' AS table_name,COUNT(*) AS actual_rows FROM stg.stg_stations
UNION ALL SELECT 'stg.stg_bikes',COUNT(*) FROM stg.stg_bikes
UNION ALL SELECT 'stg.stg_members',COUNT(*) FROM stg.stg_members
UNION ALL SELECT 'stg.stg_trips',COUNT(*) FROM stg.stg_trips
UNION ALL SELECT 'dw.fact_trips',COUNT(*) FROM dw.fact_trips;
GO

-- DQ-02: Uniqueness and unknown surrogate key presence.
SELECT 'Duplicate fact trip_id' AS check_name,
 (SELECT COUNT(*) FROM (SELECT trip_id FROM dw.fact_trips GROUP BY trip_id HAVING COUNT(*)>1) q) AS issue_count
UNION ALL SELECT 'Duplicate member surrogate key',
 (SELECT COUNT(*) FROM (SELECT member_key FROM dw.dim_members GROUP BY member_key HAVING COUNT(*)>1) q)
UNION ALL SELECT 'Unknown member 0 missing',
 (SELECT CASE WHEN EXISTS(SELECT 1 FROM dw.dim_members WHERE member_key=0) THEN 0 ELSE 1 END)
UNION ALL SELECT 'Unknown station 0 missing',
 (SELECT CASE WHEN EXISTS(SELECT 1 FROM dw.dim_stations WHERE station_key=0) THEN 0 ELSE 1 END)
UNION ALL SELECT 'Unknown bike 0 missing',
 (SELECT CASE WHEN EXISTS(SELECT 1 FROM dw.dim_bikes WHERE bike_key=0) THEN 0 ELSE 1 END);
GO

-- DQ-03: Orphan dimension keys; all ideally 0.
SELECT 'member_key' AS foreign_key_name,COUNT(*) AS orphan_facts
FROM dw.fact_trips f LEFT JOIN dw.dim_members d ON f.member_key=d.member_key
WHERE d.member_key IS NULL
UNION ALL SELECT 'bike_key',COUNT(*) FROM dw.fact_trips f LEFT JOIN dw.dim_bikes d ON f.bike_key=d.bike_key
WHERE d.bike_key IS NULL
UNION ALL SELECT 'start_station_key',COUNT(*) FROM dw.fact_trips f LEFT JOIN dw.dim_stations d ON f.start_station_key=d.station_key
WHERE d.station_key IS NULL
UNION ALL SELECT 'end_station_key',COUNT(*) FROM dw.fact_trips f LEFT JOIN dw.dim_stations d ON f.end_station_key=d.station_key
WHERE d.station_key IS NULL
UNION ALL SELECT 'date_key',COUNT(*) FROM dw.fact_trips f LEFT JOIN dw.dim_date d ON f.date_key=d.date_key
WHERE d.date_key IS NULL
UNION ALL SELECT 'hour_key',COUNT(*) FROM dw.fact_trips f LEFT JOIN dw.dim_time_of_day d ON f.hour_key=d.hour_key
WHERE d.hour_key IS NULL;
GO

-- DQ-04: Distinct invalid fact rows; no double-counting overlapping conditions.
SELECT
 COUNT(*) AS fact_rows,
 SUM(CASE WHEN t.trip_id IS NULL THEN 1 ELSE 0 END) AS fact_without_source_stage_trip,
 SUM(CASE WHEN t.trip_id IS NOT NULL AND
   (t.status<>'completed' OR t.status IS NULL) THEN 1 ELSE 0 END) AS noncompleted_loaded,
 SUM(CASE WHEN f.distance_km IS NULL OR f.distance_km<=0 THEN 1 ELSE 0 END) AS bad_distance,
 SUM(CASE WHEN f.duration_minutes IS NULL OR f.duration_minutes<0 THEN 1 ELSE 0 END) AS bad_duration,
 SUM(CASE WHEN t.trip_id IS NOT NULL AND b.bike_id IS NULL THEN 1 ELSE 0 END) AS source_bike_missing_but_loaded,
 SUM(CASE WHEN t.trip_id IS NULL OR t.status IS NULL OR t.status<>'completed'
    OR f.distance_km IS NULL OR f.distance_km<=0
    OR f.duration_minutes IS NULL OR f.duration_minutes<0
    OR b.bike_id IS NULL THEN 1 ELSE 0 END) AS any_issue_distinct_fact_rows
FROM dw.fact_trips f
LEFT JOIN stg.stg_trips t ON f.trip_id=t.trip_id
LEFT JOIN stg.stg_bikes b ON t.bike_id=b.bike_id;
GO

-- DQ-05: Rejected rows grouped by reason. Interpretation depends on re-runs.
SELECT source_table,reject_reason,COUNT(*) AS recorded_rejections
FROM etl.reject
GROUP BY source_table,reject_reason
ORDER BY source_table,reject_reason;
GO

-- DQ-06: Unknown lookups and actual warehouse total revenue.
SELECT COUNT(*) AS fact_rows,
 CAST(SUM(fee) AS DECIMAL(18,2)) AS total_revenue,
 SUM(CASE WHEN member_key=0 THEN 1 ELSE 0 END) AS unknown_member_facts,
 SUM(CASE WHEN end_station_key=0 THEN 1 ELSE 0 END) AS unknown_end_station_facts
FROM dw.fact_trips;
GO

-- DQ-07: Stage-source quality breakdown by distinct trip (diagnostic).
SELECT
 COUNT(*) AS stage_trip_rows,
 SUM(CASE WHEN status='cancelled' THEN 1 ELSE 0 END) AS cancelled,
 SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END) AS completed,
 SUM(CASE WHEN status='completed' AND
    (end_ts IS NULL OR start_ts IS NULL OR end_ts<start_ts) THEN 1 ELSE 0 END) AS invalid_time,
 SUM(CASE WHEN status='completed' AND (distance_km IS NULL OR distance_km<=0) THEN 1 ELSE 0 END) AS invalid_distance,
 SUM(CASE WHEN status='completed' AND b.bike_id IS NULL THEN 1 ELSE 0 END) AS unknown_bike,
 SUM(CASE WHEN status='completed' AND
    (end_ts IS NULL OR start_ts IS NULL OR end_ts<start_ts OR
     distance_km IS NULL OR distance_km<=0 OR b.bike_id IS NULL)
    THEN 1 ELSE 0 END) AS distinct_invalid_completed
FROM stg.stg_trips t
LEFT JOIN stg.stg_bikes b ON b.bike_id=t.bike_id;
GO
