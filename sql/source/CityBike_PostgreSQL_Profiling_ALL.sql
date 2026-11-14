-- CityBike SOURCE Data Profiling / Quality Register
-- Database: PostgreSQL citybike_src, schema: ops
-- READ-ONLY: SELECT statements only; not SQL Server syntax.
-- MEM01-MEM08: eight checks shown in the supplied Quality Register image.
-- Others extend earlier exploratory checklist for other source entities.
-- All actual results require running this against your PostgreSQL source.

-- =====================================================================
-- INV01 [Required] Source row counts
-- Row counts by source entity.
-- =====================================================================
SELECT 'stations' AS source_table, COUNT(*) AS row_count FROM ops.stations
UNION ALL SELECT 'bikes', COUNT(*) FROM ops.bikes
UNION ALL SELECT 'members', COUNT(*) FROM ops.members
UNION ALL SELECT 'trips', COUNT(*) FROM ops.trips;

-- =====================================================================
-- INV02 [Additional] Duplicate business keys across all sources
-- Primary-key duplication; normally zero due to source constraints.
-- =====================================================================
SELECT 'stations' AS source_table, station_id::text AS business_key, COUNT(*) AS occurrences FROM ops.stations GROUP BY station_id HAVING COUNT(*)>1
UNION ALL SELECT 'bikes',bike_id::text,COUNT(*) FROM ops.bikes GROUP BY bike_id HAVING COUNT(*)>1
UNION ALL SELECT 'members',member_id::text,COUNT(*) FROM ops.members GROUP BY member_id HAVING COUNT(*)>1
UNION ALL SELECT 'trips',trip_id::text,COUNT(*) FROM ops.trips GROUP BY trip_id HAVING COUNT(*)>1;

-- =====================================================================
-- MEM01 [Required] Duplicate emails ignoring case + leading/trailing spaces
-- Matches screenshot: trim boundaries and compare case-insensitively. Does not remove internal spaces.
-- =====================================================================
WITH normalized AS (
 SELECT member_id,email,LOWER(BTRIM(email)) AS email_key
 FROM ops.members WHERE NULLIF(BTRIM(email),'') IS NOT NULL
)
SELECT email_key,COUNT(*) AS registrations,MIN(member_id) AS member_to_keep,
 ARRAY_AGG(member_id ORDER BY member_id) AS member_ids
FROM normalized GROUP BY email_key HAVING COUNT(*)>1
ORDER BY registrations DESC,email_key;

-- =====================================================================
-- MEM02 [Additional] Missing or empty email
-- Missing and blank email records.
-- =====================================================================
SELECT COUNT(*) AS missing_email_count
FROM ops.members WHERE email IS NULL OR BTRIM(email)='';
SELECT member_id,full_name,email FROM ops.members
WHERE email IS NULL OR BTRIM(email)='' ORDER BY member_id;

-- =====================================================================
-- MEM03 [Additional] Invalid-looking email
-- Approximate format validation; not full RFC email validity.
-- =====================================================================
SELECT member_id,email FROM ops.members
WHERE email IS NOT NULL AND BTRIM(email)<>''
  AND BTRIM(email) !~* '^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$'
ORDER BY member_id;

-- =====================================================================
-- MEM04 [Additional] Missing birth_date
-- Records for which age cannot be derived.
-- =====================================================================
SELECT COUNT(*) AS missing_birth_date_count FROM ops.members WHERE birth_date IS NULL;
SELECT member_id,birth_date FROM ops.members WHERE birth_date IS NULL ORDER BY member_id;

-- =====================================================================
-- MEM05 [Additional] Impossible birth dates / negative age
-- Birth date in future using query execution date.
-- =====================================================================
SELECT member_id,birth_date,AGE(CURRENT_DATE,birth_date) AS age_interval
FROM ops.members WHERE birth_date>CURRENT_DATE ORDER BY member_id;

-- =====================================================================
-- MEM06 [Required] Age-band coverage as of 2025-01-01
-- Illustrative bands for profiling; verify production age-band boundaries against Talend mapping.
-- =====================================================================
WITH aged AS (
 SELECT member_id,birth_date,
 CASE WHEN birth_date IS NULL OR birth_date>DATE '2025-01-01' THEN 'Unknown/Invalid'
      WHEN DATE_PART('year',AGE(DATE '2025-01-01',birth_date))<18 THEN '<18'
      WHEN DATE_PART('year',AGE(DATE '2025-01-01',birth_date))<25 THEN '18-24'
      WHEN DATE_PART('year',AGE(DATE '2025-01-01',birth_date))<35 THEN '25-34'
      WHEN DATE_PART('year',AGE(DATE '2025-01-01',birth_date))<45 THEN '35-44'
      WHEN DATE_PART('year',AGE(DATE '2025-01-01',birth_date))<55 THEN '45-54'
      ELSE '55+' END AS profiling_age_band
 FROM ops.members
)
SELECT profiling_age_band,COUNT(*) AS members FROM aged
GROUP BY profiling_age_band ORDER BY profiling_age_band;

-- =====================================================================
-- MEM07 [Additional] Missing or unrecognized membership plan
-- Checks project-defined plan domain.
-- =====================================================================
SELECT member_id,membership_type FROM ops.members
WHERE membership_type IS NULL OR BTRIM(membership_type)=''
 OR membership_type NOT IN ('pay_go','monthly','annual')
ORDER BY member_id;

-- =====================================================================
-- MEM08 [Additional] Duplicate member business keys
-- Source PK should prevent duplication.
-- =====================================================================
SELECT member_id,COUNT(*) AS records
FROM ops.members GROUP BY member_id HAVING COUNT(*)>1 ORDER BY records DESC,member_id;

-- =====================================================================
-- MEM09 [Required] Normalized email collision detail and winner
-- Explicitly shows which member wins.
-- =====================================================================
WITH ranked AS (
 SELECT member_id,email,LOWER(BTRIM(email)) AS norm_email,
 ROW_NUMBER() OVER (PARTITION BY LOWER(BTRIM(email)) ORDER BY member_id) AS keep_rank
 FROM ops.members WHERE NULLIF(BTRIM(email),'') IS NOT NULL
)
SELECT member_id,email,norm_email,keep_rank,
 CASE WHEN keep_rank=1 THEN 'KEEP' ELSE 'DUPLICATE' END AS outcome
FROM ranked WHERE norm_email IN (
 SELECT norm_email FROM ranked GROUP BY norm_email HAVING COUNT(*)>1
) ORDER BY norm_email,keep_rank;

-- =====================================================================
-- MEM10 [Additional] Null/blank full name or city
-- Optional extended data-quality check.
-- =====================================================================
SELECT member_id,full_name,city FROM ops.members
WHERE full_name IS NULL OR BTRIM(full_name)='' OR city IS NULL OR BTRIM(city)=''
ORDER BY member_id;

-- =====================================================================
-- MEM11 [Additional] Members by plan and city
-- Profile plan distribution.
-- =====================================================================
SELECT membership_type,city,COUNT(*) AS members FROM ops.members
GROUP BY membership_type,city ORDER BY membership_type,city;

-- =====================================================================
-- MEM12 [Additional] Join date and update timestamp ordering
-- Chronology of member records.
-- =====================================================================
SELECT member_id,joined_on,updated_at FROM ops.members
WHERE updated_at::date<joined_on ORDER BY member_id;

-- =====================================================================
-- TRP01 [Required] Trips grouped by status
-- Completed/cancelled count.
-- =====================================================================
SELECT status,COUNT(*) AS trips FROM ops.trips GROUP BY status ORDER BY status;

-- =====================================================================
-- TRP02 [Additional] Missing/unrecognized trip status
-- Unexpected status domain.
-- =====================================================================
SELECT trip_id,status FROM ops.trips
WHERE status IS NULL OR BTRIM(status)='' OR status NOT IN ('completed','cancelled')
ORDER BY trip_id;

-- =====================================================================
-- TRP03 [Required] Completed trips with missing timestamps
-- Missing start/end timestamp.
-- =====================================================================
SELECT trip_id,start_ts,end_ts FROM ops.trips
WHERE status='completed' AND (start_ts IS NULL OR end_ts IS NULL)
ORDER BY trip_id;

-- =====================================================================
-- TRP04 [Required] End time before start time
-- Invalid duration chronology.
-- =====================================================================
SELECT trip_id,start_ts,end_ts FROM ops.trips
WHERE status='completed' AND end_ts<start_ts ORDER BY trip_id;

-- =====================================================================
-- TRP05 [Additional] Zero-duration completed trips
-- Zero-length trip; treatment depends on business rules.
-- =====================================================================
SELECT trip_id,start_ts,end_ts FROM ops.trips
WHERE status='completed' AND end_ts=start_ts ORDER BY trip_id;

-- =====================================================================
-- TRP06 [Required] Missing, zero or negative distance
-- Reject candidate by distance.
-- =====================================================================
SELECT trip_id,distance_km FROM ops.trips
WHERE status='completed' AND (distance_km IS NULL OR distance_km<=0)
ORDER BY trip_id;

-- =====================================================================
-- TRP07 [Additional] Missing or negative fee
-- Fee anomalies; zero may be valid with annual plan.
-- =====================================================================
SELECT trip_id,fee FROM ops.trips
WHERE status='completed' AND (fee IS NULL OR fee<0)
ORDER BY trip_id;

-- =====================================================================
-- TRP08 [Required] Unknown bike references
-- Missing bike is a rejected completed trip under documented rules.
-- =====================================================================
SELECT t.trip_id,t.bike_id FROM ops.trips t LEFT JOIN ops.bikes b ON b.bike_id=t.bike_id
WHERE t.status='completed' AND b.bike_id IS NULL ORDER BY t.trip_id;

-- =====================================================================
-- TRP09 [Required] Unknown member references
-- Eligible missing members map to Unknown member 0.
-- =====================================================================
SELECT t.trip_id,t.member_id FROM ops.trips t LEFT JOIN ops.members m ON m.member_id=t.member_id
WHERE t.status='completed' AND m.member_id IS NULL ORDER BY t.trip_id;

-- =====================================================================
-- TRP10 [Required] Missing/unknown end station references
-- Eligible missing destination maps to Unknown 0.
-- =====================================================================
SELECT t.trip_id,t.end_station_id
FROM ops.trips t LEFT JOIN ops.stations s ON s.station_id=t.end_station_id
WHERE t.status='completed' AND (t.end_station_id IS NULL OR s.station_id IS NULL)
ORDER BY t.trip_id;

-- =====================================================================
-- TRP11 [Additional] Unknown start station references
-- Start station integrity check.
-- =====================================================================
SELECT t.trip_id,t.start_station_id FROM ops.trips t LEFT JOIN ops.stations s ON s.station_id=t.start_station_id
WHERE t.status='completed' AND s.station_id IS NULL ORDER BY t.trip_id;

-- =====================================================================
-- TRP12 [Additional] Missing/unknown payment method
-- Payment method domain check.
-- =====================================================================
SELECT trip_id,payment_method FROM ops.trips
WHERE payment_method IS NULL OR BTRIM(payment_method)='' OR payment_method NOT IN ('card','wallet','app')
ORDER BY trip_id;

-- =====================================================================
-- TRP13 [Additional] Cancelled trips with inconsistent completion fields
-- Cancelled trip shape.
-- =====================================================================
SELECT trip_id,status,end_ts,distance_km,fee FROM ops.trips
WHERE status='cancelled' AND (end_ts IS NOT NULL OR distance_km IS NOT NULL OR fee<>0)
ORDER BY trip_id;

-- =====================================================================
-- TRP14 [Additional] Completed trips by month
-- Temporal distribution.
-- =====================================================================
SELECT DATE_TRUNC('month',start_ts)::date AS start_month,COUNT(*) AS completed_trips
FROM ops.trips WHERE status='completed' GROUP BY 1 ORDER BY 1;

-- =====================================================================
-- TRP15 [Additional] Distinct member / bike / station utilization
-- Source utilization.
-- =====================================================================
SELECT COUNT(DISTINCT member_id) AS distinct_riders,
 COUNT(DISTINCT bike_id) AS distinct_bikes,
 COUNT(DISTINCT start_station_id) AS distinct_start_stations
FROM ops.trips WHERE status='completed';

-- =====================================================================
-- TRP16 [Additional] Potential duplicate trip business keys
-- PK should prevent duplicates.
-- =====================================================================
SELECT trip_id,COUNT(*) AS rows_found
FROM ops.trips GROUP BY trip_id HAVING COUNT(*)>1 ORDER BY trip_id;

-- =====================================================================
-- TRP17 [Required] Overlapping trip validity reasons (not double-counted)
-- Counts unique invalid trips without adding overlapping issues. Not a guarantee matching final Talend logic.
-- =====================================================================
WITH flags AS (
 SELECT t.trip_id,
 (t.status='completed') AS completed,
 (t.end_ts IS NULL OR t.start_ts IS NULL OR t.end_ts<t.start_ts) AS bad_time,
 (t.distance_km IS NULL OR t.distance_km<=0) AS bad_distance,
 (b.bike_id IS NULL) AS bad_bike
 FROM ops.trips t LEFT JOIN ops.bikes b ON b.bike_id=t.bike_id
)
SELECT COUNT(*) FILTER (WHERE completed) AS completed_count,
 COUNT(*) FILTER (WHERE completed AND bad_time) AS bad_time_count,
 COUNT(*) FILTER (WHERE completed AND bad_distance) AS bad_distance_count,
 COUNT(*) FILTER (WHERE completed AND bad_bike) AS bad_bike_count,
 COUNT(*) FILTER (WHERE completed AND (bad_time OR bad_distance OR bad_bike)) AS distinct_invalid_completed,
 COUNT(*) FILTER (WHERE completed AND NOT (bad_time OR bad_distance OR bad_bike)) AS eligible_completed
FROM flags;

-- =====================================================================
-- TRP18 [Required] Candidate trip eligibility details
-- One primary reason per row, with priority documented.
-- =====================================================================
SELECT t.trip_id,t.status,t.start_ts,t.end_ts,t.distance_km,t.bike_id,
 CASE WHEN t.status<>'completed' THEN 'EXCLUDED_STATUS'
      WHEN t.start_ts IS NULL OR t.end_ts IS NULL OR t.end_ts<t.start_ts THEN 'INVALID_TIME'
      WHEN t.distance_km IS NULL OR t.distance_km<=0 THEN 'INVALID_DISTANCE'
      WHEN b.bike_id IS NULL THEN 'UNKNOWN_BIKE'
      ELSE 'ELIGIBLE_BY_SOURCE_RULES' END AS primary_reason
FROM ops.trips t LEFT JOIN ops.bikes b ON b.bike_id=t.bike_id
WHERE t.status IS DISTINCT FROM 'completed'
   OR t.start_ts IS NULL OR t.end_ts IS NULL OR t.end_ts<t.start_ts
   OR t.distance_km IS NULL OR t.distance_km<=0 OR b.bike_id IS NULL
ORDER BY t.trip_id;

-- =====================================================================
-- BIK01 [Required] Bike type distribution
-- Classic vs electric.
-- =====================================================================
SELECT bike_type,COUNT(*) AS bikes FROM ops.bikes GROUP BY bike_type ORDER BY bike_type;

-- =====================================================================
-- BIK02 [Additional] Unknown bike type / status
-- Domain constraints beyond source PK.
-- =====================================================================
SELECT bike_id,bike_type,status_code FROM ops.bikes
WHERE bike_type IS NULL OR bike_type NOT IN ('classic','electric')
 OR status_code IS NULL OR status_code NOT IN ('A','M','R')
ORDER BY bike_id;

-- =====================================================================
-- BIK03 [Additional] Electric battery cycles and classic-bike anomalies
-- Fleet metadata consistency.
-- =====================================================================
SELECT bike_id,bike_type,battery_cycles FROM ops.bikes
WHERE battery_cycles<0 OR (bike_type='classic' AND battery_cycles IS NOT NULL)
ORDER BY bike_id;

-- =====================================================================
-- BIK04 [Additional] Duplicate bike code
-- Code uniqueness beyond numeric key.
-- =====================================================================
SELECT LOWER(BTRIM(bike_code)) AS normalized_bike_code,COUNT(*) AS occurrences
FROM ops.bikes GROUP BY 1 HAVING COUNT(*)>1 ORDER BY occurrences DESC;

-- =====================================================================
-- STA01 [Additional] Station distribution by district/activity
-- Station distribution and capacity.
-- =====================================================================
SELECT district,is_active,COUNT(*) AS stations,
 SUM(dock_count) AS total_docks
FROM ops.stations GROUP BY district,is_active ORDER BY district,is_active;

-- =====================================================================
-- STA02 [Additional] Invalid stations: location/dock count/name
-- Basic station domain check.
-- =====================================================================
SELECT station_id,station_name,dock_count,latitude,longitude FROM ops.stations
WHERE dock_count<=0 OR station_name IS NULL OR BTRIM(station_name)=''
 OR latitude NOT BETWEEN -90 AND 90 OR longitude NOT BETWEEN -180 AND 180
ORDER BY station_id;

-- =====================================================================
-- STA03 [Additional] Duplicate station names ignoring case/spaces
-- Potential naming collisions, not duplicate business keys.
-- =====================================================================
SELECT LOWER(BTRIM(station_name)) AS normalized_name,COUNT(*) AS occurrences
FROM ops.stations GROUP BY 1 HAVING COUNT(*)>1 ORDER BY occurrences DESC;

-- =====================================================================
-- META01 [Additional] Trip source updated_at chronology
-- Source update timestamps may not align with trip finalization.
-- =====================================================================
SELECT trip_id,start_ts,end_ts,updated_at FROM ops.trips
WHERE updated_at<start_ts OR (end_ts IS NOT NULL AND updated_at<end_ts)
ORDER BY trip_id;

