# 📊 Business outcomes & presentation notes

The brief supplies seven reporting questions and two illustrative reference outputs: Q0 total revenue **60,184.80** on **19,577** trips, and Q3 busiest station **Station 01 Riverside (3,911 trips)** on the initial load. All other business metrics require executing the SQL queries; no values are invented.

**Tell the story**: operational pain → source quality → batch architecture → star schema → quality gates → historical SCD2 → SQL questions → lessons.

**Interview talking point**: why correct trip-to-member effective-dated joins matter more than simply creating duplicate dimension versions.
