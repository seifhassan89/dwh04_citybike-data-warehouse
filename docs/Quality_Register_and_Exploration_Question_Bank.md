# CityBike — Quality Register and Data Exploration Question Bank

**Source:** PostgreSQL `citybike_src.ops`; SQL file: `CityBike_PostgreSQL_Profiling_ALL.sql` (read-only).

**Coverage:** Eight member checks from the screenshot have matching executable queries `MEM01`–`MEM08`. The rest extend profiling across trips, bikes, stations and inventory. These extras are not asserted to exist in the original Quality Register spreadsheet.

| ID | Category | Question / check | Scope | SQL purpose |
|---|---|---|---|---|
| `INV01` | Inventory | Source row counts | Required | Row counts by source entity. |
| `INV02` | Inventory | Duplicate business keys across all sources | Additional | Primary-key duplication; normally zero due to source constraints. |
| `MEM01` | Members | Duplicate emails ignoring case + leading/trailing spaces | Required | Matches screenshot: trim boundaries and compare case-insensitively. Does not remove internal spaces. |
| `MEM02` | Members | Missing or empty email | Additional | Missing and blank email records. |
| `MEM03` | Members | Invalid-looking email | Additional | Approximate format validation; not full RFC email validity. |
| `MEM04` | Members | Missing birth_date | Additional | Records for which age cannot be derived. |
| `MEM05` | Members | Impossible birth dates / negative age | Additional | Birth date in future using query execution date. |
| `MEM06` | Members | Age-band coverage as of 2025-01-01 | Required | Illustrative bands for profiling; verify production age-band boundaries against Talend mapping. |
| `MEM07` | Members | Missing or unrecognized membership plan | Additional | Checks project-defined plan domain. |
| `MEM08` | Members | Duplicate member business keys | Additional | Source PK should prevent duplication. |
| `MEM09` | Members | Normalized email collision detail and winner | Required | Explicitly shows which member wins. |
| `MEM10` | Members | Null/blank full name or city | Additional | Optional extended data-quality check. |
| `MEM11` | Members | Members by plan and city | Additional | Profile plan distribution. |
| `MEM12` | Members | Join date and update timestamp ordering | Additional | Chronology of member records. |
| `TRP01` | Trips | Trips grouped by status | Required | Completed/cancelled count. |
| `TRP02` | Trips | Missing/unrecognized trip status | Additional | Unexpected status domain. |
| `TRP03` | Trips | Completed trips with missing timestamps | Required | Missing start/end timestamp. |
| `TRP04` | Trips | End time before start time | Required | Invalid duration chronology. |
| `TRP05` | Trips | Zero-duration completed trips | Additional | Zero-length trip; treatment depends on business rules. |
| `TRP06` | Trips | Missing, zero or negative distance | Required | Reject candidate by distance. |
| `TRP07` | Trips | Missing or negative fee | Additional | Fee anomalies; zero may be valid with annual plan. |
| `TRP08` | Trips | Unknown bike references | Required | Missing bike is a rejected completed trip under documented rules. |
| `TRP09` | Trips | Unknown member references | Required | Eligible missing members map to Unknown member 0. |
| `TRP10` | Trips | Missing/unknown end station references | Required | Eligible missing destination maps to Unknown 0. |
| `TRP11` | Trips | Unknown start station references | Additional | Start station integrity check. |
| `TRP12` | Trips | Missing/unknown payment method | Additional | Payment method domain check. |
| `TRP13` | Trips | Cancelled trips with inconsistent completion fields | Additional | Cancelled trip shape. |
| `TRP14` | Trips | Completed trips by month | Additional | Temporal distribution. |
| `TRP15` | Trips | Distinct member / bike / station utilization | Additional | Source utilization. |
| `TRP16` | Trips | Potential duplicate trip business keys | Additional | PK should prevent duplicates. |
| `TRP17` | Trips | Overlapping trip validity reasons (not double-counted) | Required | Counts unique invalid trips without adding overlapping issues. Not a guarantee matching final Talend logic. |
| `TRP18` | Trips | Candidate trip eligibility details | Required | One primary reason per row, with priority documented. |
| `BIK01` | Bikes | Bike type distribution | Required | Classic vs electric. |
| `BIK02` | Bikes | Unknown bike type / status | Additional | Domain constraints beyond source PK. |
| `BIK03` | Bikes | Electric battery cycles and classic-bike anomalies | Additional | Fleet metadata consistency. |
| `BIK04` | Bikes | Duplicate bike code | Additional | Code uniqueness beyond numeric key. |
| `STA01` | Stations | Station distribution by district/activity | Additional | Station distribution and capacity. |
| `STA02` | Stations | Invalid stations: location/dock count/name | Additional | Basic station domain check. |
| `STA03` | Stations | Duplicate station names ignoring case/spaces | Additional | Potential naming collisions, not duplicate business keys. |
| `META01` | Audit | Trip source updated_at chronology | Additional | Source update timestamps may not align with trip finalization. |

## Important distinctions

- Source profiling (PostgreSQL) differs from Q1–Q7 warehouse analytics (SQL Server).
- `MEM01` uses `LOWER(BTRIM(email))`, matching case-insensitive and *leading/trailing* space checks, not internal-space removal.
- `MEM06` contains suggested age buckets as of `2025-01-01`. Compare the bucket boundaries to the Talend job before stating policy equivalence.
- `TRP17` counts *distinct* invalid trips across overlapping conditions to avoid double counting.
- The project owner has custom cases; do not equate target brief numbers with actual database results.
- A query is evidence of a check definition, not of a verified outcome. Save results after execution.
