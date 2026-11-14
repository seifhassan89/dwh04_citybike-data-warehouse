# 05 — Complete Source-to-Target Field Mapping

**Source-backed design mapping, not a live database schema export.** Source PostgreSQL DDL, Talend .item queries and tMap expressions, SQL Server calendar helper and audit setup were inspected. All 4 source/staging tables, 5 dimensions, fact tMap 14 output fields and audit outputs are covered.

**Critical discrepancies observed in available Talend version:** member SCD2 uses `SYSDATETIME()` for changed plans; fact tMap member lookup is by member_id only; missing-bike lookup enforcement is not evident in the main Var.exception; reject `run_id` literal is `10`. These are review findings, not assumed fixed.

## stg.stg_stations (8 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| station_id | INT | ops.stations.station_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| station_name | VARCHAR(60) | ops.stations.station_name | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| district | VARCHAR(30) | ops.stations.district | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| latitude | NUMERIC(9,6) | ops.stations.latitude | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| longitude | NUMERIC(9,6) | ops.stations.longitude | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| dock_count | INT | ops.stations.dock_count | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| opened_on | DATE | ops.stations.opened_on | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| is_active | BIT | ops.stations.is_active | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion (boolean -> BIT) | JOB SQL CONFIRMED |

## stg.stg_bikes (6 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| bike_id | INT | ops.bikes.bike_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| bike_code | VARCHAR(12) | ops.bikes.bike_code | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| bike_type | VARCHAR(10) | ops.bikes.bike_type | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| purchase_date | DATE | ops.bikes.purchase_date | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| status_code | CHAR(1) | ops.bikes.status_code | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| battery_cycles | INT | ops.bikes.battery_cycles | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |

## stg.stg_members (8 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| member_id | INT | ops.members.member_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| full_name | VARCHAR(80) | ops.members.full_name | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| email | VARCHAR(100) | ops.members.email | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| birth_date | DATE | ops.members.birth_date | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| city | VARCHAR(40) | ops.members.city | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| membership_type | VARCHAR(10) | ops.members.membership_type | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| joined_on | DATE | ops.members.joined_on | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| updated_at | DATETIME2 | ops.members.updated_at | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |

## stg.stg_trips (12 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| trip_id | INT | ops.trips.trip_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| member_id | INT | ops.trips.member_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| bike_id | INT | ops.trips.bike_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| start_station_id | INT | ops.trips.start_station_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| end_station_id | INT | ops.trips.end_station_id | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| start_ts | DATETIME2 | ops.trips.start_ts | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| end_ts | DATETIME2 | ops.trips.end_ts | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| distance_km | NUMERIC(6,2) | ops.trips.distance_km | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| fee | NUMERIC(8,2) | ops.trips.fee | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| payment_method | VARCHAR(10) | ops.trips.payment_method | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| status | VARCHAR(10) | ops.trips.status | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |
| updated_at | DATETIME2 | ops.trips.updated_at | Full-refresh copy; PostgreSQL -> SQL Server, with SQL Server type conversion | JOB SQL CONFIRMED |

## stg.valid_bikes (6 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| bike_id | INT | stg.stg_bikes.bike_id | Validated bike branch; review tMap validation condition for per-record acceptance | JOB DDL CONFIRMED |
| bike_code | VARCHAR(12) | stg.stg_bikes.bike_code | Validated bike branch; review tMap validation condition for per-record acceptance | JOB DDL CONFIRMED |
| bike_type | VARCHAR(10) | stg.stg_bikes.bike_type | Validated bike branch; review tMap validation condition for per-record acceptance | JOB DDL CONFIRMED |
| purchase_date | DATE | stg.stg_bikes.purchase_date | Validated bike branch; review tMap validation condition for per-record acceptance | JOB DDL CONFIRMED |
| status_code | CHAR(1) | stg.stg_bikes.status_code | Validated bike branch; review tMap validation condition for per-record acceptance | JOB DDL CONFIRMED |
| battery_cycles | INT | stg.stg_bikes.battery_cycles | Validated bike branch; review tMap validation condition for per-record acceptance | JOB DDL CONFIRMED |

## dw.dim_stations (8 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| station_key | INT | SQL Server IDENTITY / Unknown key = 0 | Generate surrogate key | TALEND DDL CONFIRMED |
| station_id | INT | stg.stg_stations.station_id | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |
| station_name | VARCHAR(60) | stg.stg_stations.station_name | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |
| district | VARCHAR(30) | stg.stg_stations.district | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |
| latitude | NUMERIC(9,6) | stg.stg_stations.latitude | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |
| longitude | NUMERIC(9,6) | stg.stg_stations.longitude | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |
| dock_count | INT | stg.stg_stations.dock_count | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |
| opened_on | DATE | stg.stg_stations.opened_on | MERGE Type 1 on station_id; reject missing name/district, invalid coordinates/docks | TALEND DDL CONFIRMED |

## dw.dim_bikes (7 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| bike_key | INT | SQL Server IDENTITY / Unknown key = 0 | Generate surrogate key | TALEND DDL CONFIRMED |
| bike_id | INT | stg.stg_bikes.bike_id | MERGE Type 1 on bike_id; bike quality rules in tMap | TALEND DDL CONFIRMED |
| bike_code | VARCHAR(12) | stg.stg_bikes.bike_code | MERGE Type 1 on bike_id; bike quality rules in tMap | TALEND DDL CONFIRMED |
| bike_type | VARCHAR(10) | stg.stg_bikes.bike_type | MERGE Type 1 on bike_id; bike quality rules in tMap | TALEND DDL CONFIRMED |
| purchase_date | DATE | stg.stg_bikes.purchase_date | MERGE Type 1 on bike_id; bike quality rules in tMap | TALEND DDL CONFIRMED |
| status_code | CHAR(1) | stg.stg_bikes.status_code | MERGE Type 1 on bike_id; bike quality rules in tMap | TALEND DDL CONFIRMED |
| battery_cycles | INT | stg.stg_bikes.battery_cycles | MERGE Type 1 on bike_id; bike quality rules in tMap | TALEND DDL CONFIRMED |

## dw.dim_members (12 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| member_key | INT | SQL Server IDENTITY + Unknown key 0 | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| member_id | INT | stg.stg_members.member_id | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| full_name | VARCHAR(80) | stg.stg_members.full_name | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| email | VARCHAR(100) | stg.stg_members.email | Derived / normalization: LOWER(REPLACE(LTRIM(RTRIM(email)), space, empty)); ROW_NUMBER by normalized email, retain lowest member_id; missing emails rejected in observed job SQL | TALEND DDL + JOB LOGIC CONFIRMED |
| birth_date | DATE | stg.stg_members.birth_date | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| age_band | VARCHAR(20) | stg.stg_members.birth_date | Derived / normalization: Age relative to 2025-01-01 in supplied Talend SQL, future or NULL birthdate => Unknown | TALEND DDL + JOB LOGIC CONFIRMED |
| city | VARCHAR(40) | stg.stg_members.city | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| membership_type | VARCHAR(10) | stg.stg_members.membership_type | New version only when membership_type changes; Type 1 update other profile attributes | TALEND DDL + JOB LOGIC CONFIRMED |
| joined_on | DATE | stg.stg_members.joined_on | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| updated_at | DATETIME2 | stg.stg_members.updated_at | Type 1 update for existing member versions, insert for new member | TALEND DDL + JOB LOGIC CONFIRMED |
| valid_from | DATETIME2 | joined_on for initial; change timestamp on plan switch | New version only when membership_type changes; Type 1 update other profile attributes | TALEND DDL + JOB LOGIC CONFIRMED |
| valid_to | DATETIME2 | NULL current; change timestamp at closure | New version only when membership_type changes; Type 1 update other profile attributes | TALEND DDL + JOB LOGIC CONFIRMED |

## dw.dim_date (9 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| date_key | INT | DATE -> YYYYMMDD | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| full_date | DATE | source calendar days | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| year_num | SMALLINT | YEAR(full_date) | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| quarter_num | TINYINT | DATEPART(QUARTER) | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| month_num | TINYINT | MONTH(full_date) | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| month_name | NVARCHAR(20) | DATENAME(MONTH) | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| day_num | TINYINT | DAY(full_date) | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| weekday_name | NVARCHAR(20) | DATENAME(WEEKDAY) | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |
| is_weekend | BIT | calendar day classification | Calendar helper generation (2024-01-01 to 2025-12-31) | HELPER SQL CONFIRMED |

## dw.dim_time_of_day (3 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| hour_key | TINYINT | 0–23 | Hour helper generation | HELPER SQL CONFIRMED |
| hour_label | NVARCHAR(5) | HH:00 | Hour helper generation | HELPER SQL CONFIRMED |
| day_part | NVARCHAR(10) | Night/Morning/Afternoon/Evening | Hour helper generation | HELPER SQL CONFIRMED |

## dw.fact_trips (14 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| trip_id | id_Integer | stg.stg_trips.trip_id | Direct trip business key | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| member_key | id_Integer | dw.dim_members.member_key | Lookup member_id; observed Talend matches member_id only (no effective-date lookup shown); missing-lookup fallback must be verified | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| bike_key | id_Integer | dw.dim_bikes.bike_key | Lookup bike_id; missing bike should be rejected (not enforced in visible Var.exception) | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| start_station_key | id_Integer | dw.dim_stations.station_key | Lookup start_station_id | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| end_station_key | id_Integer | dw.dim_stations.station_key | Lookup end_station_id; required Unknown 0 fallback not visible in expression | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| date_key | id_Integer | dw.dim_date.date_key | Lookup date of start_ts | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| hour_key | id_Integer | dw.dim_time_of_day.hour_key | Lookup hour(start_ts) | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| start_ts | id_Date | stg.stg_trips.start_ts | Pass through | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| end_ts | id_Date | stg.stg_trips.end_ts | Pass through | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| distance_km | id_BigDecimal(6,2) | stg.stg_trips.distance_km | Validates non-null and >0 in Var.exception | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| duration_minutes | id_BigDecimal(10,2) | stg.stg_trips.end_ts - start_ts | Milliseconds /60000 rounded HALF_UP to 2 decimal places | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| fee | id_BigDecimal(8,2) | stg.stg_trips.fee | Validates non-null and >=0 in Var.exception | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| payment_method | id_String(10) | stg.stg_trips.payment_method | Pass through | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |
| trip_count | id_Integer | constant 1 | Constant per valid trip | TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE |

## etl.reject (11 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| business_key | id_Integer | stg.stg_trips.trip_id | Rejected trip id | TALEND tMap OUTPUT CONFIRMED |
| source_table | id_String | constant fact_trips | Source label | TALEND tMap OUTPUT CONFIRMED |
| run_id | id_Integer | literal 10 in observed tMap | Hard-coded in captured version; requires fix | TALEND tMap OUTPUT CONFIRMED |
| rejected_at | id_Date | TalendDate.getCurrentDate() | Current datetime | TALEND tMap OUTPUT CONFIRMED |
| reject_reason | id_String | Var.exception | Reject reason from validation order | TALEND tMap OUTPUT CONFIRMED |
| reject_id | INT | IDENTITY | Persist audit metadata | SETUP DDL CONFIRMED |
| run_id | INT | current run reference | Persist audit metadata | SETUP DDL CONFIRMED |
| source_table | NVARCHAR(100) | job name / table | Persist audit metadata | SETUP DDL CONFIRMED |
| business_key | NVARCHAR(100) | source key | Persist audit metadata | SETUP DDL CONFIRMED |
| reject_reason | NVARCHAR(200) | invalid reason | Persist audit metadata | SETUP DDL CONFIRMED |
| rejected_at | DATETIME2 | SYSDATETIME default | Persist audit metadata | SETUP DDL CONFIRMED |

## etl.run_log (9 mappings)

| Column | Type | Source | Rule | Evidence |
|---|---|---|---|---|
| run_id | INT | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| job_name | NVARCHAR(100) | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| started_at | DATETIME2 | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| finished_at | DATETIME2 | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| rows_read | INT | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| rows_loaded | INT | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| rows_rejected | INT | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| status | NVARCHAR(20) | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |
| message | NVARCHAR(4000) | Talend job / system / counters | Record job status and counts | SETUP DDL CONFIRMED |

## Validation scope

The deployed SQL Server physical column metadata is not available for `dw.fact_trips`; its target types are the Talend `valid` output schema and must be reconciled against `sys.columns` on the live database. Member Type 2 correctness requires time-window tests. The user reported custom data cases and an observed current baseline of 19,582 fact trips; source benchmark counts must not be substituted for that actual result.
