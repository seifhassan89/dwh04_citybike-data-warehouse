# Talend Studio 8 — Sanitized Job Designs

`CityBike_Talend_Sanitized_Job_Designs.zip` is derived from the user's actual original Talend Job Designs export, **not generated example ETL**.

To reduce public credential exposure, literal connection fields and every saved context value were cleared. The exported job logic, component structure and native Talend screenshots remain. **No claim is made that this sanitized export has been imported, compiled, or executed.**

To run it, import into Talend Studio 8, set PostgreSQL/MSSQL connections and context variables locally, review dependencies and run the jobs. Talend metadata fields outside recognized connection settings should be reviewed again before publishing to a public repo.

Screenshots in `assets/talend-screenshots/` were extracted exactly from the original `.screenshot` payloads; they show *job designs*, not execution success. The original screenshot for the master shows error badges, so it must not be represented as a passing run.
