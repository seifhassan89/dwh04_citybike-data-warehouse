# 04 — CityBike Data Catalog

**Status:** Derived from PostgreSQL source SQL, Talend job DDL, SQL Server helper and audit skeleton. Fact types below are Talend output-schema types until SQL Server `sys.columns` metadata is supplied.

## stg.stg_stations

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `station_id` | `INT` | NO / JOB SQL CONFIRMED | COPY: ops.stations.station_id |
| `station_name` | `VARCHAR(60)` | NO / JOB SQL CONFIRMED | COPY: ops.stations.station_name |
| `district` | `VARCHAR(30)` | NO / JOB SQL CONFIRMED | COPY: ops.stations.district |
| `latitude` | `NUMERIC(9,6)` | YES / JOB SQL CONFIRMED | COPY: ops.stations.latitude |
| `longitude` | `NUMERIC(9,6)` | YES / JOB SQL CONFIRMED | COPY: ops.stations.longitude |
| `dock_count` | `INT` | NO / JOB SQL CONFIRMED | COPY: ops.stations.dock_count |
| `opened_on` | `DATE` | NO / JOB SQL CONFIRMED | COPY: ops.stations.opened_on |
| `is_active` | `BIT` | NO / JOB SQL CONFIRMED | COPY: ops.stations.is_active |

## stg.stg_bikes

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `bike_id` | `INT` | NO / JOB SQL CONFIRMED | COPY: ops.bikes.bike_id |
| `bike_code` | `VARCHAR(12)` | NO / JOB SQL CONFIRMED | COPY: ops.bikes.bike_code |
| `bike_type` | `VARCHAR(10)` | NO / JOB SQL CONFIRMED | COPY: ops.bikes.bike_type |
| `purchase_date` | `DATE` | NO / JOB SQL CONFIRMED | COPY: ops.bikes.purchase_date |
| `status_code` | `CHAR(1)` | NO / JOB SQL CONFIRMED | COPY: ops.bikes.status_code |
| `battery_cycles` | `INT` | YES / JOB SQL CONFIRMED | COPY: ops.bikes.battery_cycles |

## stg.stg_members

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `member_id` | `INT` | NO / JOB SQL CONFIRMED | COPY: ops.members.member_id |
| `full_name` | `VARCHAR(80)` | NO / JOB SQL CONFIRMED | COPY: ops.members.full_name |
| `email` | `VARCHAR(100)` | YES / JOB SQL CONFIRMED | COPY: ops.members.email |
| `birth_date` | `DATE` | YES / JOB SQL CONFIRMED | COPY: ops.members.birth_date |
| `city` | `VARCHAR(40)` | YES / JOB SQL CONFIRMED | COPY: ops.members.city |
| `membership_type` | `VARCHAR(10)` | NO / JOB SQL CONFIRMED | COPY: ops.members.membership_type |
| `joined_on` | `DATE` | NO / JOB SQL CONFIRMED | COPY: ops.members.joined_on |
| `updated_at` | `DATETIME2` | NO / JOB SQL CONFIRMED | COPY: ops.members.updated_at |

## stg.stg_trips

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `trip_id` | `INT` | NO / JOB SQL CONFIRMED | COPY: ops.trips.trip_id |
| `member_id` | `INT` | YES / JOB SQL CONFIRMED | COPY: ops.trips.member_id |
| `bike_id` | `INT` | YES / JOB SQL CONFIRMED | COPY: ops.trips.bike_id |
| `start_station_id` | `INT` | YES / JOB SQL CONFIRMED | COPY: ops.trips.start_station_id |
| `end_station_id` | `INT` | YES / JOB SQL CONFIRMED | COPY: ops.trips.end_station_id |
| `start_ts` | `DATETIME2` | YES / JOB SQL CONFIRMED | COPY: ops.trips.start_ts |
| `end_ts` | `DATETIME2` | YES / JOB SQL CONFIRMED | COPY: ops.trips.end_ts |
| `distance_km` | `NUMERIC(6,2)` | YES / JOB SQL CONFIRMED | COPY: ops.trips.distance_km |
| `fee` | `NUMERIC(8,2)` | YES / JOB SQL CONFIRMED | COPY: ops.trips.fee |
| `payment_method` | `VARCHAR(10)` | YES / JOB SQL CONFIRMED | COPY: ops.trips.payment_method |
| `status` | `VARCHAR(10)` | YES / JOB SQL CONFIRMED | COPY: ops.trips.status |
| `updated_at` | `DATETIME2` | YES / JOB SQL CONFIRMED | COPY: ops.trips.updated_at |

## stg.valid_bikes

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `bike_id` | `INT` | NO / JOB DDL CONFIRMED | VALIDATED COPY: stg.stg_bikes.bike_id |
| `bike_code` | `VARCHAR(12)` | NO / JOB DDL CONFIRMED | VALIDATED COPY: stg.stg_bikes.bike_code |
| `bike_type` | `VARCHAR(10)` | NO / JOB DDL CONFIRMED | VALIDATED COPY: stg.stg_bikes.bike_type |
| `purchase_date` | `DATE` | NO / JOB DDL CONFIRMED | VALIDATED COPY: stg.stg_bikes.purchase_date |
| `status_code` | `CHAR(1)` | NO / JOB DDL CONFIRMED | VALIDATED COPY: stg.stg_bikes.status_code |
| `battery_cycles` | `INT` | YES / JOB DDL CONFIRMED | VALIDATED COPY: stg.stg_bikes.battery_cycles |

## dw.dim_stations

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `station_key` | `INT` | NO / TALEND DDL CONFIRMED | KEY: SQL Server IDENTITY / Unknown key = 0 |
| `station_id` | `INT` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.station_id |
| `station_name` | `VARCHAR(60)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.station_name |
| `district` | `VARCHAR(30)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.district |
| `latitude` | `NUMERIC(9,6)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.latitude |
| `longitude` | `NUMERIC(9,6)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.longitude |
| `dock_count` | `INT` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.dock_count |
| `opened_on` | `DATE` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_stations.opened_on |

## dw.dim_bikes

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `bike_key` | `INT` | NO / TALEND DDL CONFIRMED | KEY: SQL Server IDENTITY / Unknown key = 0 |
| `bike_id` | `INT` | NO / TALEND DDL CONFIRMED | KEY: stg.stg_bikes.bike_id |
| `bike_code` | `VARCHAR(12)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_bikes.bike_code |
| `bike_type` | `VARCHAR(10)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_bikes.bike_type |
| `purchase_date` | `DATE` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_bikes.purchase_date |
| `status_code` | `CHAR(1)` | NO / TALEND DDL CONFIRMED | SCD1: stg.stg_bikes.status_code |
| `battery_cycles` | `INT` | YES / TALEND DDL CONFIRMED | SCD1: stg.stg_bikes.battery_cycles |

## dw.dim_members

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `member_key` | `INT` | NO / TALEND DDL + JOB LOGIC CONFIRMED | KEY: SQL Server IDENTITY + Unknown key 0 |
| `member_id` | `INT` | NO / TALEND DDL + JOB LOGIC CONFIRMED | KEY: stg.stg_members.member_id |
| `full_name` | `VARCHAR(80)` | NO / TALEND DDL + JOB LOGIC CONFIRMED | SCD1: stg.stg_members.full_name |
| `email` | `VARCHAR(100)` | YES / TALEND DDL + JOB LOGIC CONFIRMED | CLEAN + SCD1: stg.stg_members.email |
| `birth_date` | `DATE` | YES / TALEND DDL + JOB LOGIC CONFIRMED | SCD1: stg.stg_members.birth_date |
| `age_band` | `VARCHAR(20)` | YES / TALEND DDL + JOB LOGIC CONFIRMED | DERIVED: stg.stg_members.birth_date |
| `city` | `VARCHAR(40)` | YES / TALEND DDL + JOB LOGIC CONFIRMED | SCD1: stg.stg_members.city |
| `membership_type` | `VARCHAR(10)` | NO / TALEND DDL + JOB LOGIC CONFIRMED | SCD2: stg.stg_members.membership_type |
| `joined_on` | `DATE` | NO / TALEND DDL + JOB LOGIC CONFIRMED | SCD1: stg.stg_members.joined_on |
| `updated_at` | `DATETIME2` | NO / TALEND DDL + JOB LOGIC CONFIRMED | SCD1: stg.stg_members.updated_at |
| `valid_from` | `DATETIME2` | NO / TALEND DDL + JOB LOGIC CONFIRMED | SCD2: joined_on for initial; change timestamp on plan switch |
| `valid_to` | `DATETIME2` | YES / TALEND DDL + JOB LOGIC CONFIRMED | SCD2: NULL current; change timestamp at closure |

## dw.dim_date

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `date_key` | `INT` | NO / HELPER SQL CONFIRMED | KEY: DATE -> YYYYMMDD |
| `full_date` | `DATE` | NO / HELPER SQL CONFIRMED | KEY: source calendar days |
| `year_num` | `SMALLINT` | NO / HELPER SQL CONFIRMED | DERIVED: YEAR(full_date) |
| `quarter_num` | `TINYINT` | NO / HELPER SQL CONFIRMED | DERIVED: DATEPART(QUARTER) |
| `month_num` | `TINYINT` | NO / HELPER SQL CONFIRMED | DERIVED: MONTH(full_date) |
| `month_name` | `NVARCHAR(20)` | NO / HELPER SQL CONFIRMED | DERIVED: DATENAME(MONTH) |
| `day_num` | `TINYINT` | NO / HELPER SQL CONFIRMED | DERIVED: DAY(full_date) |
| `weekday_name` | `NVARCHAR(20)` | NO / HELPER SQL CONFIRMED | DERIVED: DATENAME(WEEKDAY) |
| `is_weekend` | `BIT` | NO / HELPER SQL CONFIRMED | DERIVED: calendar day classification |

## dw.dim_time_of_day

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `hour_key` | `TINYINT` | NO / HELPER SQL CONFIRMED | KEY: 0–23 |
| `hour_label` | `NVARCHAR(5)` | NO / HELPER SQL CONFIRMED | DERIVED: HH:00 |
| `day_part` | `NVARCHAR(10)` | NO / HELPER SQL CONFIRMED | DERIVED: Night/Morning/Afternoon/Evening |

## dw.fact_trips

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `trip_id` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | KEY: stg.stg_trips.trip_id |
| `member_key` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | LOOKUP: dw.dim_members.member_key |
| `bike_key` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | LOOKUP: dw.dim_bikes.bike_key |
| `start_station_key` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | LOOKUP: dw.dim_stations.station_key |
| `end_station_key` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | LOOKUP: dw.dim_stations.station_key |
| `date_key` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | LOOKUP: dw.dim_date.date_key |
| `hour_key` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | LOOKUP: dw.dim_time_of_day.hour_key |
| `start_ts` | `id_Date` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | COPY: stg.stg_trips.start_ts |
| `end_ts` | `id_Date` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | COPY: stg.stg_trips.end_ts |
| `distance_km` | `id_BigDecimal(6,2)` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | VALIDATION: stg.stg_trips.distance_km |
| `duration_minutes` | `id_BigDecimal(10,2)` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | DERIVED: stg.stg_trips.end_ts - start_ts |
| `fee` | `id_BigDecimal(8,2)` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | VALIDATION: stg.stg_trips.fee |
| `payment_method` | `id_String(10)` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | COPY: stg.stg_trips.payment_method |
| `trip_count` | `id_Integer` | NO / TALEND tMap OUTPUT CONFIRMED; SQL SERVER DDL UNAVAILABLE | DERIVED: constant 1 |

## etl.reject

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `business_key` | `id_Integer` | Not confirmed / TALEND tMap OUTPUT CONFIRMED | AUDIT: stg.stg_trips.trip_id |
| `source_table` | `id_String` | Not confirmed / TALEND tMap OUTPUT CONFIRMED | AUDIT: constant fact_trips |
| `run_id` | `id_Integer` | Not confirmed / TALEND tMap OUTPUT CONFIRMED | AUDIT ISSUE: literal 10 in observed tMap |
| `rejected_at` | `id_Date` | Not confirmed / TALEND tMap OUTPUT CONFIRMED | AUDIT: TalendDate.getCurrentDate() |
| `reject_reason` | `id_String` | Not confirmed / TALEND tMap OUTPUT CONFIRMED | AUDIT: Var.exception |
| `reject_id` | `INT` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: IDENTITY |
| `run_id` | `INT` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: current run reference |
| `source_table` | `NVARCHAR(100)` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: job name / table |
| `business_key` | `NVARCHAR(100)` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: source key |
| `reject_reason` | `NVARCHAR(200)` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: invalid reason |
| `rejected_at` | `DATETIME2` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: SYSDATETIME default |

## etl.run_log

| Column | Type | Nullable / evidence | Business meaning |
|---|---|---|---|
| `run_id` | `INT` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `job_name` | `NVARCHAR(100)` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `started_at` | `DATETIME2` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `finished_at` | `DATETIME2` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `rows_read` | `INT` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `rows_loaded` | `INT` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `rows_rejected` | `INT` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `status` | `NVARCHAR(20)` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |
| `message` | `NVARCHAR(4000)` | Not confirmed / SETUP DDL CONFIRMED | AUDIT: Talend job / system / counters |

