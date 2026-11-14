/* OPTIONAL HELPER: calendar and hour-of-day tables, ready to use.
   Run in CityBikeDW. You may use them as they are, or design your own. */
USE CityBikeDW;
GO
DROP TABLE IF EXISTS dw.dim_date;
DROP TABLE IF EXISTS dw.dim_time_of_day;
GO
CREATE TABLE dw.dim_date (
  date_key INT PRIMARY KEY,                 -- 20250131
  full_date DATE NOT NULL, year_num SMALLINT NOT NULL, quarter_num TINYINT NOT NULL, month_num TINYINT NOT NULL,
  month_name NVARCHAR(20) NOT NULL, day_num TINYINT NOT NULL, weekday_name NVARCHAR(20) NOT NULL, is_weekend BIT NOT NULL);
WITH d AS (SELECT CAST('2024-01-01' AS DATE) AS dt UNION ALL SELECT DATEADD(DAY, 1, dt) FROM d WHERE dt < '2025-12-31')
INSERT INTO dw.dim_date
SELECT YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt), dt, YEAR(dt), DATEPART(QUARTER, dt), MONTH(dt), DATENAME(MONTH, dt), DAY(dt),
       DATENAME(WEEKDAY, dt), CASE WHEN DATEDIFF(DAY, '19000107', dt) % 7 IN (0, 6) THEN 1 ELSE 0 END
FROM d OPTION (MAXRECURSION 0);

CREATE TABLE dw.dim_time_of_day (
  hour_key TINYINT PRIMARY KEY, hour_label NVARCHAR(5) NOT NULL,
  day_part NVARCHAR(10) NOT NULL);          -- Night 0-5, Morning 6-11, Afternoon 12-17, Evening 18-23
WITH h AS (SELECT 0 AS i UNION ALL SELECT i + 1 FROM h WHERE i < 23)
INSERT INTO dw.dim_time_of_day
SELECT i, RIGHT(N'0' + CAST(i AS NVARCHAR(2)), 2) + N':00',
       CASE WHEN i < 6 THEN N'Night' WHEN i < 12 THEN N'Morning' WHEN i < 18 THEN N'Afternoon' ELSE N'Evening' END
FROM h;
GO
SELECT (SELECT COUNT(*) FROM dw.dim_date) AS dim_date_rows, (SELECT COUNT(*) FROM dw.dim_time_of_day) AS dim_time_rows;   -- 731 and 24
GO
