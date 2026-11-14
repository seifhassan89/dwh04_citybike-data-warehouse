# Evidence & verification — honest status

## What was independently verified from uploaded artifacts
- Found **6** actual Talend `.item` job designs.
- Decoded **6** actual `.screenshot` XML/Base64 exports to PNG.
- Created a sanitized Talend design archive with **26** items; scrubbed **253** saved connection/context values.
- Re-parsed all included XML and verified no filled context parameters and no literal values in recognized connection fields.
- Archived all SQL source/target scripts and the validation and analytics queries.

## What was NOT verified from the uploaded artifacts alone
- No live SQL Server or PostgreSQL session was available. A screenshot or SQL script does not prove a successful database run.
- The assignment brief states target values (e.g., initial 19,577 accepted trips; Q0 revenue 60,184.80; after-change 19,877 trips), not verified execution outputs.
- The sanitized Talend export was not compiled and may require restoring local context mappings.

## Publication notes
- No original unsanitized credential-bearing ZIP is included.
- This is a privacy-conscious export, **not a guarantee** that the application cannot contain other organization-specific configuration. Review once before making public.
- Original Talend `.screenshot` images show design canvas states, not runtime successful execution.
