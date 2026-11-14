-- =====================================================================
-- CityBike SOURCE database (PostgreSQL 12 or later)
--   createdb citybike_src
--   psql -d citybike_src -f citybike_source_pg.sql
-- Operational system of a bike-sharing company: schema "ops", 4 tables.
-- All data is fictional and deterministic. It is realistic: it contains
-- some mistakes, like any real operational system.
-- =====================================================================
DROP SCHEMA IF EXISTS ops CASCADE;
CREATE SCHEMA ops;
SET search_path = ops;

-- ---------- stations: the docking stations in the city (25 rows) ------
CREATE TABLE stations (
  station_id   integer      PRIMARY KEY,
  station_name varchar(60)  NOT NULL,
  district     varchar(30)  NOT NULL,
  latitude     numeric(9,6),
  longitude    numeric(9,6),
  dock_count   integer      NOT NULL,      -- number of bike slots at the station
  opened_on    date         NOT NULL,
  is_active    boolean      NOT NULL
);
INSERT INTO stations
SELECT g, 'Station ' || lpad(g::text, 2, '0') || ' ' || x.d, x.d,
       30.000000 + (g % 5) * 0.012 + g * 0.0004,
       31.200000 + (g / 5) * 0.010 + g * 0.0003,
       12 + (g % 4) * 6, date '2023-03-01' + g * 10, (g % 12) <> 0
FROM generate_series(1, 25) g
CROSS JOIN LATERAL (SELECT (ARRAY['Downtown','Riverside','University','Old Town','Harbor'])[1 + (g % 5)] AS d) x;

-- ---------- bikes: the fleet (120 rows) -------------------------------
CREATE TABLE bikes (
  bike_id        integer     PRIMARY KEY,
  bike_code      varchar(12) NOT NULL UNIQUE,   -- the label printed on the bike
  bike_type      varchar(10) NOT NULL,          -- classic or electric
  purchase_date  date        NOT NULL,
  status_code    char(1)     NOT NULL,          -- A = active, M = in maintenance, R = retired
  battery_cycles integer                        -- electric bikes only
);
INSERT INTO bikes
SELECT g, 'CB-' || lpad(g::text, 4, '0'), CASE WHEN g % 3 = 0 THEN 'electric' ELSE 'classic' END,
       date '2023-04-01' + g * 3,
       CASE WHEN g % 20 = 0 THEN 'R' WHEN g % 9 = 0 THEN 'M' ELSE 'A' END,
       CASE WHEN g % 3 = 0 THEN (g * 7) % 500 END
FROM generate_series(1, 120) g;

-- ---------- members: registered riders (500 rows + problems) ----------
CREATE TABLE members (
  member_id       integer      PRIMARY KEY,
  full_name       varchar(80)  NOT NULL,
  email           varchar(100),
  birth_date      date,
  city            varchar(40),
  membership_type varchar(10)  NOT NULL,   -- pay_go, monthly or annual
  joined_on       date         NOT NULL,
  updated_at      timestamp    NOT NULL
);
WITH b AS (
  SELECT g, (ARRAY['Ava','Omar','Lina','Noah','Sara','Yusuf','Mia','Adam','Nora','Ali'])[1 + (g % 10)] AS fn,
            (ARRAY['Hassan','Smith','Costa','Khan','Brown','Ali','Garcia','Nasser','Wilson','Mansour'])[1 + ((g / 10) % 10)] AS ln
  FROM generate_series(1, 500) g)
INSERT INTO members
SELECT g, fn || ' ' || ln, lower(fn) || '.' || lower(ln) || g || '@mail.test',
       date '1965-01-01' + (g * 97) % 14000,
       (ARRAY['Cairo','Giza','Alexandria','Mansoura','Tanta'])[1 + (g % 5)],
       CASE WHEN g % 10 < 5 THEN 'pay_go' WHEN g % 10 < 8 THEN 'monthly' ELSE 'annual' END,
       date '2024-01-01' + (g % 150), timestamp '2024-01-01' + (g % 150) * interval '1 day'
FROM b;
-- problem 1: 10 people registered twice (same e-mail, written in capitals)
INSERT INTO members
SELECT member_id + 490, full_name, upper(email), birth_date, city, membership_type, date '2024-03-01', timestamp '2024-03-01'
FROM members WHERE member_id BETWEEN 11 AND 20;
-- problem 2: 5 members without e-mail, 3 with an impossible birth date
UPDATE members SET email = NULL WHERE member_id BETWEEN 101 AND 105;
UPDATE members SET birth_date = date '2099-01-01' WHERE member_id BETWEEN 201 AND 203;

-- ---------- trips: every rental (20,000 rows + problems) --------------
CREATE TABLE trips (
  trip_id          bigint       PRIMARY KEY,
  member_id        integer      NOT NULL,   -- who rented (no foreign key in this old system)
  bike_id          integer      NOT NULL,
  start_station_id integer      NOT NULL,
  end_station_id   integer,                 -- empty while the bike is out, or if cancelled
  start_ts         timestamp    NOT NULL,
  end_ts           timestamp,
  distance_km      numeric(6,2),
  fee              numeric(8,2) NOT NULL,   -- what the member paid
  payment_method   varchar(10)  NOT NULL,   -- card, wallet or app
  status           varchar(10)  NOT NULL,   -- completed or cancelled
  updated_at       timestamp    NOT NULL
);
INSERT INTO trips
SELECT x.g, x.m, x.b, x.s1, CASE WHEN x.canc THEN NULL ELSE x.s2 END, x.st,
       CASE WHEN x.canc THEN NULL ELSE x.st + x.dur * interval '1 minute' END,
       CASE WHEN x.canc THEN NULL
            ELSE round((x.dur * (0.15 + (x.g % 7) * 0.02 + CASE WHEN x.b % 3 = 0 THEN 0.10 ELSE 0 END))::numeric, 2) END,
       CASE WHEN x.canc THEN 0
            WHEN x.m % 10 < 5 THEN round((1.0 + x.dur * 0.15)::numeric, 2)
            WHEN x.m % 10 < 8 THEN round((greatest(x.dur - 30, 0) * 0.10)::numeric, 2)
            ELSE 0 END,
       (ARRAY['card','wallet','app'])[1 + (x.g % 3)],
       CASE WHEN x.canc THEN 'cancelled' ELSE 'completed' END,
       CASE WHEN x.canc THEN x.st ELSE x.st + x.dur * interval '1 minute' END
FROM (SELECT g, 1 + ((g * 37) % 500) AS m, 1 + ((g * 53) % 120) AS b, 1 + floor(25 * power(((g * 7919) % 1000) / 1000.0, 2))::int AS s1, 1 + ((g * 17 + 3) % 25) AS s2,
             5 + ((g * 19) % 55) AS dur, (g % 100) IN (7, 57) AS canc,
             date '2024-06-01' + ((g * 7) % 365)
               + make_interval(hours => CASE WHEN g % 10 < 3 THEN 8 + (g % 2) WHEN g % 10 < 6 THEN 17 + (g % 3) ELSE (g * 13) % 24 END,
                               mins  => (g * 29) % 60) AS st
      FROM generate_series(1, 20000) g) x;
-- problem 3: bad trips
UPDATE trips SET end_ts = start_ts - interval '10 minutes' WHERE trip_id BETWEEN 1010 AND 1019;   -- 10 trips end before they start
UPDATE trips SET distance_km = NULL WHERE trip_id BETWEEN 2010 AND 2013;                          -- 4 without distance
UPDATE trips SET distance_km = 0    WHERE trip_id BETWEEN 2014 AND 2017;                          -- 4 with zero distance
UPDATE trips SET member_id = 9000 + (trip_id - 3009) WHERE trip_id BETWEEN 3010 AND 3021;         -- 12 trips of unknown members
UPDATE trips SET bike_id = 999 WHERE trip_id BETWEEN 4010 AND 4014;                               -- 5 trips on an unknown bike
UPDATE trips SET end_station_id = NULL WHERE trip_id BETWEEN 5010 AND 5015;                       -- 6 completed trips without end station

CREATE INDEX ix_trips_updated ON trips (updated_at);
CREATE INDEX ix_trips_member  ON trips (member_id);
ANALYZE;

SELECT 'stations' AS table_name, count(*) AS row_count FROM stations
UNION ALL SELECT 'bikes', count(*) FROM bikes
UNION ALL SELECT 'members', count(*) FROM members
UNION ALL SELECT 'trips', count(*) FROM trips;
