USE CityBikeDW;
GO
SET NOCOUNT ON;

-- LOG-01: Most recent execution records. Screenshot this result.
SELECT TOP (30)
 run_id,job_name,status,started_at,finished_at,
 rows_read,rows_loaded,rows_rejected,message
FROM etl.run_log
ORDER BY run_id DESC;
GO

-- LOG-02: Execution summary by status and job.
SELECT job_name,status,
 COUNT(*) AS recorded_runs,
 MIN(started_at) AS first_started,
 MAX(started_at) AS last_started,
 SUM(COALESCE(rows_read,0)) AS total_rows_read,
 SUM(COALESCE(rows_loaded,0)) AS total_rows_loaded,
 SUM(COALESCE(rows_rejected,0)) AS total_rows_rejected
FROM etl.run_log
GROUP BY job_name,status
ORDER BY job_name,status;
GO

-- LOG-03: Rejections per recorded run ID (if run_id was set correctly).
SELECT r.run_id,r.job_name,r.status,r.rows_rejected AS runlog_rejected,
 COUNT(e.reject_id) AS linked_reject_rows
FROM etl.run_log r
LEFT JOIN etl.reject e ON e.run_id=r.run_id
GROUP BY r.run_id,r.job_name,r.status,r.rows_rejected
ORDER BY r.run_id DESC;
GO

-- LOG-04: Audit integrity: rejected rows with no matching run log.
SELECT COUNT(*) AS rejected_rows_without_valid_run
FROM etl.reject e
LEFT JOIN etl.run_log r ON r.run_id=e.run_id
WHERE e.run_id IS NULL OR r.run_id IS NULL;
GO

-- LOG-05: Status and timestamp consistency. These are potential issues.
SELECT
 COUNT(*) AS log_entries,
 SUM(CASE WHEN status='RUNNING' THEN 1 ELSE 0 END) AS still_running,
 SUM(CASE WHEN status IN ('SUCCESS','SUCCEEDED','COMPLETED') THEN 1 ELSE 0 END) AS success_like,
 SUM(CASE WHEN status IN ('FAIL','FAILED','FAILURE','ERROR') THEN 1 ELSE 0 END) AS failure_like,
 SUM(CASE WHEN status IN ('SUCCESS','SUCCEEDED','COMPLETED','FAIL','FAILED','FAILURE','ERROR')
            AND finished_at IS NULL THEN 1 ELSE 0 END) AS terminal_without_finished_at,
 SUM(CASE WHEN finished_at IS NOT NULL AND finished_at<started_at THEN 1 ELSE 0 END) AS invalid_time_order
FROM etl.run_log;
GO
