# ⚙️ Nightly ETL runbook

**Sequence**: PostgreSQL staging refresh → dimension loads → fact load → reconcile → log final status.

**Failure**: Stop dependent jobs, log ERROR / FAILED, preserve rejects and query output, remediate the source/job, rerun against an unchanged source snapshot.

**Change-cycle**: On fresh baseline only, apply the provided `citybike_changes_pg.sql` *once*, then rerun ETL and validate plan validity windows. Never reapply a cyclic plan-switch script as a regular retry.

**Monitoring**: Check `etl.run_log` run IDs, statuses, counts and timestamps; compare reject summaries per run and confirm fact key uniqueness.

**Production improvements**: atomic staging swap, transactionally safe audit writes, observability alerts, incremental extraction, access-control hardening and alerting.
