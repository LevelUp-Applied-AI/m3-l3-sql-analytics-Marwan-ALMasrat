-- ============================================================
-- Tier 2 — Views and PL/pgSQL Function
-- ============================================================

-- Standard View: Department Summary
CREATE OR REPLACE VIEW department_summary AS
SELECT
    d.department_id,
    d.name                          AS department_name,
    d.location,
    COUNT(e.employee_id)            AS employee_count,
    ROUND(AVG(e.salary), 2)         AS avg_salary,
    SUM(e.salary)                   AS total_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.name, d.location;


-- Standard View: Project Status
CREATE OR REPLACE VIEW project_status AS
SELECT
    p.project_id,
    p.name                          AS project_name,
    p.start_date,
    p.end_date,
    p.budget,
    COUNT(pa.employee_id)           AS assigned_employees,
    COALESCE(SUM(pa.hours_allocated), 0) AS total_hours,
    CASE
        WHEN p.end_date IS NULL               THEN 'Ongoing'
        WHEN p.end_date < CURRENT_DATE        THEN 'Completed'
        ELSE 'Active'
    END                             AS status
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.start_date, p.end_date, p.budget;


-- Materialized View: Department Summary (cached)
CREATE MATERIALIZED VIEW department_summary_mat AS
SELECT
    d.department_id,
    d.name                          AS department_name,
    COUNT(e.employee_id)            AS employee_count,
    ROUND(AVG(e.salary), 2)         AS avg_salary,
    SUM(e.salary)                   AS total_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.name;

-- To refresh materialized view:
-- REFRESH MATERIALIZED VIEW department_summary_mat;


-- PL/pgSQL Function: Department Report as JSON
CREATE OR REPLACE FUNCTION get_department_report(dept_name VARCHAR)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'department',       d.name,
        'employee_count',   COUNT(DISTINCT e.employee_id),
        'total_salary',     COALESCE(SUM(e.salary), 0),
        'active_projects',  COUNT(DISTINCT CASE 
                                WHEN p.end_date IS NULL OR p.end_date >= CURRENT_DATE 
                                THEN pa.project_id END)
    )
    INTO result
    FROM departments d
    LEFT JOIN employees e         ON d.department_id = e.department_id
    LEFT JOIN project_assignments pa ON e.employee_id = pa.employee_id
    LEFT JOIN projects p          ON pa.project_id = p.project_id
    WHERE LOWER(d.name) = LOWER(dept_name)
    GROUP BY d.name;

    IF result IS NULL THEN
        RAISE EXCEPTION 'Department "%" not found', dept_name;
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

