-- ============================================================
-- Tier 3 — Salary History & Migration
-- ============================================================

-- 1. Create salary_history table
CREATE TABLE IF NOT EXISTS salary_history (
    history_id      SERIAL PRIMARY KEY,
    employee_id     INTEGER NOT NULL REFERENCES employees(employee_id),
    old_salary      NUMERIC(10,2),
    new_salary      NUMERIC(10,2) NOT NULL,
    change_date     DATE NOT NULL,
    change_reason   VARCHAR(200) DEFAULT 'Initial record'
);


-- 2. Migration: seed from existing employees (one record each)
INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, change_reason)
SELECT 
    employee_id,
    NULL,
    salary,
    hire_date,
    'Initial salary on hire'
FROM employees;


-- 3. Simulate historical raises (2-3 records per employee)
INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, change_reason)
SELECT 
    employee_id,
    salary,
    ROUND(salary * 1.07, 2),
    hire_date + INTERVAL '1 year',
    'Annual raise Year 1'
FROM employees;

INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, change_reason)
SELECT 
    employee_id,
    ROUND(salary * 1.07, 2),
    ROUND(salary * 1.07 * 1.05, 2),
    hire_date + INTERVAL '2 years',
    'Annual raise Year 2'
FROM employees;


-- 4. Salary growth rate by department
SELECT
    d.name                              AS department_name,
    EXTRACT(YEAR FROM sh.change_date)   AS year,
    ROUND(AVG(sh.new_salary), 2)        AS avg_salary,
    ROUND(AVG(sh.new_salary) - LAG(ROUND(AVG(sh.new_salary), 2)) 
        OVER (PARTITION BY d.name ORDER BY EXTRACT(YEAR FROM sh.change_date)), 2
    )                                   AS salary_growth
FROM salary_history sh
JOIN employees e  ON sh.employee_id = e.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name, EXTRACT(YEAR FROM sh.change_date)
ORDER BY d.name, year;


-- 5. Employees due for salary review (no raise in 12+ months)
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    d.name                          AS department,
    e.salary,
    MAX(sh.change_date)             AS last_change_date,
    CURRENT_DATE - MAX(sh.change_date) AS days_since_last_change
FROM employees e
JOIN departments d       ON e.department_id = d.department_id
JOIN salary_history sh   ON e.employee_id = sh.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, d.name, e.salary
HAVING MAX(sh.change_date) < CURRENT_DATE - INTERVAL '12 months'
ORDER BY days_since_last_change DESC;