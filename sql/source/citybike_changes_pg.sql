-- Run AFTER your first complete load, then run your Talend jobs again.
-- It simulates one month of life: plan changes, new members, new trips.
SET search_path = ops;
-- 40 members change their plan on 1 June 2025 (history must be kept!)
UPDATE members SET membership_type = CASE membership_type WHEN 'pay_go' THEN 'monthly' WHEN 'monthly' THEN 'annual' ELSE 'pay_go' END,
       updated_at = timestamp '2025-06-01'
WHERE member_id BETWEEN 1 AND 40;
-- 5 members move to another city (only a correction, no history needed)
UPDATE members SET city = 'Port Said', updated_at = timestamp '2025-06-01' WHERE member_id BETWEEN 50 AND 54;
-- 5 new members
INSERT INTO members
SELECT 510 + g, 'New Rider ' || g, 'new.rider' || g || '@mail.test', date '1995-05-05', 'Cairo', 'monthly', date '2025-06-01', timestamp '2025-06-01'
FROM generate_series(1, 5) g;
-- 3 new stations
INSERT INTO stations
SELECT 25 + g, 'Station ' || (25 + g) || ' Harbor', 'Harbor', 30.1, 31.3, 18, date '2025-06-01', true FROM generate_series(1, 3) g;
-- 300 new trips in June 2025 (members 1..60, so some trips belong to members whose plan changed)
INSERT INTO trips
SELECT 20000 + g, 1 + (g % 60), 1 + ((g * 53) % 120), 1 + ((g * 11) % 25), 1 + ((g * 17 + 3) % 25),
       timestamp '2025-06-02 08:00' + (g % 28) * interval '1 day' + (g % 10) * interval '1 hour',
       timestamp '2025-06-02 08:00' + (g % 28) * interval '1 day' + (g % 10) * interval '1 hour' + (10 + g % 40) * interval '1 minute',
       round((2 + (g % 9) * 0.7)::numeric, 2), round((1 + (g % 6) * 0.5)::numeric, 2), 'app', 'completed',
       timestamp '2025-06-03'
FROM generate_series(1, 300) g;
SELECT count(*) AS trips_now FROM trips;
