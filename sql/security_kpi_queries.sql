-- Security & Operations KPI Dashboard
-- SQL queries used for KPI analysis
-- Database: SQLite

-- 1. Total number of open critical findings
SELECT
    COUNT(*) AS open_critical_findings
FROM findings
WHERE criticality = 'Critical'
  AND status = 'Open';


-- 2. Open incidents by department
SELECT
    d.department_name,
    COUNT(*) AS open_incidents
FROM incidents i
JOIN departments d
    ON i.department_id = d.department_id
WHERE i.status = 'Open'
GROUP BY d.department_name
ORDER BY open_incidents DESC, d.department_name;


-- 3. Average resolution time for closed incidents by department
SELECT
    d.department_name,
    ROUND(AVG(i.resolution_days), 2) AS avg_resolution_days
FROM incidents i
JOIN departments d
    ON i.department_id = d.department_id
WHERE i.status = 'Closed'
GROUP BY d.department_name
ORDER BY avg_resolution_days DESC;


-- 4. Training completion rate by department
SELECT
    d.department_name,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN t.training_completed = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        1
    ) AS training_completion_rate_pct
FROM training t
JOIN departments d
    ON t.department_id = d.department_id
GROUP BY d.department_name
ORDER BY training_completion_rate_pct ASC;


-- 5. Phishing fail rate by department
-- Calculated in relation to employees who completed training
SELECT
    d.department_name,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN t.phishing_test_result = 'Failed' THEN 1
                ELSE 0
            END
        ) / NULLIF(
            SUM(
                CASE
                    WHEN t.training_completed = 'Yes' THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        1
    ) AS phishing_fail_rate_pct
FROM training t
JOIN departments d
    ON t.department_id = d.department_id
GROUP BY d.department_name
ORDER BY phishing_fail_rate_pct DESC;


-- 6. Consolidated department KPI overview
SELECT
    d.department_name,
    COALESCE(f.open_critical_findings, 0) AS open_critical_findings,
    COALESCE(i.open_incidents, 0) AS open_incidents,
    COALESCE(r.avg_resolution_days, 0) AS avg_resolution_days,
    COALESCE(t.training_completion_rate_pct, 0) AS training_completion_rate_pct
FROM departments d
LEFT JOIN (
    SELECT
        department_id,
        COUNT(*) AS open_critical_findings
    FROM findings
    WHERE criticality = 'Critical'
      AND status = 'Open'
    GROUP BY department_id
) f
    ON d.department_id = f.department_id
LEFT JOIN (
    SELECT
        department_id,
        COUNT(*) AS open_incidents
    FROM incidents
    WHERE status = 'Open'
    GROUP BY department_id
) i
    ON d.department_id = i.department_id
LEFT JOIN (
    SELECT
        department_id,
        ROUND(AVG(resolution_days), 2) AS avg_resolution_days
    FROM incidents
    WHERE status = 'Closed'
    GROUP BY department_id
) r
    ON d.department_id = r.department_id
LEFT JOIN (
    SELECT
        department_id,
        ROUND(
            100.0 * SUM(
                CASE
                    WHEN training_completed = 'Yes' THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            1
        ) AS training_completion_rate_pct
    FROM training
    GROUP BY department_id
) t
    ON d.department_id = t.department_id
ORDER BY
    open_critical_findings DESC,
    open_incidents DESC,
    avg_resolution_days DESC,
    training_completion_rate_pct ASC;