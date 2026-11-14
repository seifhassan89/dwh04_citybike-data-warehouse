USE CityBikeDW;
GO
SET NOCOUNT ON;

-- SCD-01: Member dimension summary. Actual values only; no brief target.
SELECT
 COUNT(*) AS all_member_dimension_rows,
 COUNT(DISTINCT CASE WHEN member_key<>0 THEN member_id END) AS distinct_real_members,
 SUM(CASE WHEN member_key=0 THEN 1 ELSE 0 END) AS unknown_member_rows,
 SUM(CASE WHEN member_key<>0 AND valid_to IS NULL THEN 1 ELSE 0 END) AS current_versions,
 SUM(CASE WHEN member_key<>0 AND valid_to IS NOT NULL THEN 1 ELSE 0 END) AS historical_versions,
 COUNT(DISTINCT CASE WHEN member_key<>0 AND valid_to IS NOT NULL THEN member_id END) AS members_with_history
FROM dw.dim_members;
GO

-- SCD-02: Summary of SCD2 consistency defects (0 issues is PASS).
WITH issues AS (
 SELECT
  (SELECT COUNT(*) FROM (
    SELECT member_id FROM dw.dim_members
    WHERE member_key<>0 AND valid_to IS NULL
    GROUP BY member_id HAVING COUNT(*)<>1
  ) x) AS multiple_current_members,
  (SELECT COUNT(*) FROM dw.dim_members
    WHERE member_key<>0 AND (valid_from IS NULL OR (valid_to IS NOT NULL AND valid_to<=valid_from))
  ) AS invalid_period_rows,
  (SELECT COUNT(*) FROM dw.dim_members a
    JOIN dw.dim_members b
      ON a.member_id=b.member_id AND a.member_key<b.member_key
    WHERE a.member_key<>0 AND b.member_key<>0
      AND a.valid_from < COALESCE(b.valid_to,CONVERT(DATETIME2,'99991231',112))
      AND b.valid_from < COALESCE(a.valid_to,CONVERT(DATETIME2,'99991231',112))
  ) AS overlapping_version_pairs,
  (SELECT COUNT(*) FROM (
    SELECT member_id FROM dw.dim_members WHERE member_key<>0
    GROUP BY member_id HAVING SUM(CASE WHEN valid_to IS NULL THEN 1 ELSE 0 END)=0
  ) x) AS members_without_current_version
)
SELECT 'Multiple current versions' AS check_name,multiple_current_members AS issue_count,
 CASE WHEN multiple_current_members=0 THEN 'PASS' ELSE 'FAIL' END AS outcome FROM issues
UNION ALL SELECT 'Invalid effective windows',invalid_period_rows,
 CASE WHEN invalid_period_rows=0 THEN 'PASS' ELSE 'FAIL' END FROM issues
UNION ALL SELECT 'Overlapping effective windows',overlapping_version_pairs,
 CASE WHEN overlapping_version_pairs=0 THEN 'PASS' ELSE 'FAIL' END FROM issues
UNION ALL SELECT 'Members without current version',members_without_current_version,
 CASE WHEN members_without_current_version=0 THEN 'PASS' ELSE 'FAIL' END FROM issues;
GO

-- SCD-03: Sample members with historical versions (shows actual validity periods).
SELECT TOP (30)
 m.member_id,m.member_key,m.membership_type,m.valid_from,m.valid_to,
 CASE WHEN m.valid_to IS NULL THEN 'CURRENT' ELSE 'HISTORY' END AS version_status
FROM dw.dim_members m
WHERE m.member_key<>0
  AND EXISTS (
   SELECT 1 FROM dw.dim_members h
   WHERE h.member_id=m.member_id AND h.member_key<>0 AND h.valid_to IS NOT NULL
  )
ORDER BY m.member_id,m.valid_from,m.member_key;
GO

-- SCD-04: Fact-member temporal correctness summary.
-- For an accepted trip there must be exactly ONE matching SCD2 member version,
-- unless source member truly has no historical version (then member_key=0).
WITH checked AS (
 SELECT f.trip_id,f.member_key,t.member_id,
  (SELECT COUNT(*) FROM dw.dim_members m
   WHERE m.member_key<>0 AND m.member_id=t.member_id
     AND m.valid_from<=f.start_ts
     AND (m.valid_to IS NULL OR f.start_ts<m.valid_to)) AS matching_versions,
  (SELECT COUNT(*) FROM dw.dim_members m
   WHERE m.member_key=f.member_key
     AND m.member_id=t.member_id AND m.member_key<>0
     AND m.valid_from<=f.start_ts
     AND (m.valid_to IS NULL OR f.start_ts<m.valid_to)) AS stored_key_matches
 FROM dw.fact_trips f
 JOIN stg.stg_trips t ON t.trip_id=f.trip_id
)
SELECT
 COUNT(*) AS facts_matched_to_staging,
 SUM(CASE WHEN matching_versions>1 THEN 1 ELSE 0 END) AS ambiguous_history,
 SUM(CASE WHEN matching_versions=1 AND stored_key_matches<>1 THEN 1 ELSE 0 END) AS wrong_member_version,
 SUM(CASE WHEN matching_versions=0 AND member_key<>0 THEN 1 ELSE 0 END) AS missing_version_not_unknown,
 SUM(CASE WHEN matching_versions>0 AND member_key=0 THEN 1 ELSE 0 END) AS unknown_used_despite_valid_version,
 CASE WHEN
  SUM(CASE WHEN matching_versions>1 THEN 1 ELSE 0 END)=0
  AND SUM(CASE WHEN matching_versions=1 AND stored_key_matches<>1 THEN 1 ELSE 0 END)=0
  AND SUM(CASE WHEN matching_versions=0 AND member_key<>0 THEN 1 ELSE 0 END)=0
  THEN 'PASS' ELSE 'FAIL' END AS result
FROM checked;
GO

-- SCD-05: A few failing temporal member-key examples (empty result is good).
SELECT TOP (20) f.trip_id,t.member_id,f.start_ts,f.member_key AS stored_member_key,
 x.valid_matching_versions
FROM dw.fact_trips f
JOIN stg.stg_trips t ON t.trip_id=f.trip_id
CROSS APPLY (
 SELECT COUNT(*) AS valid_matching_versions
 FROM dw.dim_members m
 WHERE m.member_key<>0 AND m.member_id=t.member_id
   AND m.valid_from<=f.start_ts AND (m.valid_to IS NULL OR f.start_ts<m.valid_to)
) x
WHERE x.valid_matching_versions>1
 OR (x.valid_matching_versions=0 AND f.member_key<>0)
 OR (x.valid_matching_versions>0 AND NOT EXISTS (
  SELECT 1 FROM dw.dim_members d
  WHERE d.member_key=f.member_key AND d.member_id=t.member_id
    AND d.member_key<>0 AND d.valid_from<=f.start_ts
    AND (d.valid_to IS NULL OR f.start_ts<d.valid_to)))
ORDER BY f.trip_id;
GO
