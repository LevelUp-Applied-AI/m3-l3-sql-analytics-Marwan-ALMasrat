-- ============================================================
-- Tier 1 — Complex Analytics Queries
-- ============================================================

-- 1. At-Risk Projects
-- Projects where total allocated hours > 80% of project budget
SELECT 
    p.project_id,
    p.name                            AS project_name,
    SUM(pa.hours_allocated)           AS total_allocated_hours,
    p.budget                          AS project_budget,
    ROUND(SUM(pa.hours_allocated) / p.budget * 100, 2) AS pct_used
FROM projects p
JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.project_id, p.name, p.budget
HAVING SUM(pa.hours_allocated) > 0.8 * p.budget;


-- 2. Cross-Department Collaboration
-- Projects that have employees from MORE than one department
-- (since projects table has no dept_id, we detect cross-dept via assignments)
SELECT
    p.project_id,
    p.name                            AS project_name,
    e.first_name,
    e.last_name,
    d.name                            AS employee_department,
    COUNT(DISTINCT e2.department_id) 
        OVER (PARTITION BY pa.project_id) AS num_departments_on_project
FROM project_assignments pa
JOIN employees e  ON pa.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
JOIN projects p   ON pa.project_id = p.project_id
JOIN project_assignments pa2 ON pa2.project_id = pa.project_id
JOIN employees e2 ON pa2.employee_id = e2.employee_id
WHERE (
    SELECT COUNT(DISTINCT e3.department_id)
    FROM project_assignments pa3
    JOIN employees e3 ON pa3.employee_id = e3.employee_id
    WHERE pa3.project_id = p.project_id
) > 1
ORDER BY p.project_id, d.name;