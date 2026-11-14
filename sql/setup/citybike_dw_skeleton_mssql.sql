/* =====================================================================
   CityBike DATA WAREHOUSE: starting point (SQL Server 2017 or later)
   Run in SSMS or:  sqlcmd -S localhost -E -i citybike_dw_skeleton_mssql.sql
   It creates the empty database CityBikeDW with three schemas:
     stg  staging area   (you create the tables)
     dw   the warehouse  (you design and create the tables)
     etl  audit          (run log and reject table are given)
   ===================================================================== */
IF DB_ID(N'CityBikeDW') IS NULL CREATE DATABASE CityBikeDW;
GO
USE CityBikeDW;
GO
IF SCHEMA_ID(N'stg') IS NULL EXEC (N'CREATE SCHEMA stg');
IF SCHEMA_ID(N'dw')  IS NULL EXEC (N'CREATE SCHEMA dw');
IF SCHEMA_ID(N'etl') IS NULL EXEC (N'CREATE SCHEMA etl');
GO
DROP TABLE IF EXISTS etl.reject, etl.run_log;
GO
CREATE TABLE etl.run_log (
  run_id        INT IDENTITY(1,1) PRIMARY KEY,
  job_name      NVARCHAR(100) NOT NULL,
  started_at    DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
  finished_at   DATETIME2(0)  NULL,
  rows_read     INT NULL,
  rows_loaded   INT NULL,
  rows_rejected INT NULL,
  status        NVARCHAR(20)  NOT NULL DEFAULT N'RUNNING',
  message       NVARCHAR(4000) NULL);
CREATE TABLE etl.reject (
  reject_id     INT IDENTITY(1,1) PRIMARY KEY,
  run_id        INT NULL,
  source_table  NVARCHAR(100) NOT NULL,
  business_key  NVARCHAR(100) NULL,
  reject_reason NVARCHAR(200) NOT NULL,
  rejected_at   DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME());
GO
PRINT N'CityBikeDW skeleton is ready. Design and create your stg and dw tables.';
