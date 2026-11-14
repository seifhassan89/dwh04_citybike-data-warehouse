# 🎯 Requirements traceability — R1–R13

| Requirement | Proof / area to inspect | Status in this handover |
|---|---|---|
| R1 staging all sources | Talend loads, count reconciliation | Code/export described; runtime evidence absent |
| R2 trip-grain star schema | Fact DDL / star-schema diagram | Documented |
| R3 surrogate keys | Dimension DDL | Documented conceptually |
| R4 Unknown 0 records | Dimension init + FK checks | Runtime evidence absent |
| R5 SCD1 and SCD2 | Member merge SQL and change cycle | Documented; runtime evidence absent |
| R6 invalid trips, fallbacks | Fact and reject handling | Documented; runtime evidence absent |
| R7 normalized email / age band | Member logic and profiling | Documented; runtime evidence absent |
| R8 date/hour links | Date/hour helpers and fact joins | Documented |
| R9 rejects / run logs | `etl.reject`, `etl.run_log` | Documented; runtime evidence absent |
| R10 rerun idempotence | Before/after snapshot checks | User previously reports success; no raw output archived here |
| R11 contexts | Local Talend connection contexts | Public export deliberately excluded |
| R12 historical trip attribution | Member SCD2 lookup | Documented; runtime evidence absent |
| R13 scheduling / failures | Master job / scheduler description | Documented; scheduler proof absent |
