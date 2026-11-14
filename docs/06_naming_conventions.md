# 06 — Naming Conventions (CityBike)

## Databases and schemas
- PostgreSQL database `citybike_src`, operational schema `ops`: `ops.stations`, `ops.bikes`, `ops.members`, `ops.trips`.
- SQL Server database `CityBikeDW`: `stg` = complete raw snapshots, `dw` = analytical dimensions/fact, `etl` = audit and run tracking.
- This implementation does **not** use Bronze/Silver/Gold and should not be renamed to mirror another project.

## Objects
- Staging: `stg.stg_<plural-entity>` (e.g. `stg.stg_trips`); validated intermediate: `stg.valid_bikes`.
- Dimensions: `dw.dim_<plural-entity>`, fact: `dw.fact_trips`; helper dimensions `dw.dim_date` and `dw.dim_time_of_day`.
- Business keys: `<entity>_id`; dimension surrogate keys: `<entity>_key`; events: `trip_id`.
- ETL audit: `etl.run_log` and `etl.reject`; `run_id` must be the current run identifier, never a hard-coded constant.
- SCD Type 2: `valid_from`, `valid_to`, `membership_type`; model temporal boundaries explicitly.
- Talend jobs: `j_citybike_master`, `j_load_stg_trips`, `j_load_dim_stations`, `j_load_dim_bikes`, `j_load_dim_members`, `j_load_fact_trips`.
- SQL variables / aliases: readable lower_case or existing project names, avoid reserved words.

## Data types and validation
- Use SQL Server `DATETIME2` for date-time timestamps; `TIMESTAMP` in SQL Server means `rowversion`.
- Use NUMERIC/DECIMAL for monetary and measured values (fee / distance).
- `source_id` and `surrogate_key` must not be conflated; a member can have multiple SCD2 rows.
- Actual project casing and plural naming are canonical. Rules are documentation, not a migration instruction.

## Evidence
Rules are based on the actual source, Talend DDL and published project paths.
