-- Q1: Employee Directory with Departments
SELECT 
    e.first_name,
    e.last_name,
    e.title,
    e.salary,
    d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY d.name ASC, e.salary DESC;


-- Q2: Department Salary Analysis
SELECT 
    d.name AS department_name,
    SUM(e.salary) AS total_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.name
HAVING SUM(e.salary) > 150000;


-- Q3: Highest-Paid Employee per Department
WITH ranked_employees AS (
    SELECT 
        d.name AS department_name,
        e.first_name,
        e.last_name,
        e.salary,
        ROW_NUMBER() OVER (PARTITION BY d.department_id ORDER BY e.salary DESC) AS rn
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
)
SELECT department_name, first_name, last_name, salary
FROM ranked_employees
WHERE rn = 1;


-- Q4: Project Staffing Overview
SELECT 
    p.name AS project_name,
    COUNT(pa.employee_id) AS employee_count,
    COALESCE(SUM(pa.hours_allocated),0) AS total_hours
FROM projects p
LEFT JOIN project_assignments pa ON p.project_id = pa.project_id
GROUP BY p.name
ORDER BY p.name;


-- Q5: Above-Average Departments
WITH company_avg AS (SELECT AVG(salary) AS avg_salary FROM employees),
dept_avg AS (
    SELECT d.name AS department_name, AVG(e.salary) AS avg_salary
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    GROUP BY d.name
)
SELECT dept_avg.department_name, dept_avg.avg_salary
FROM dept_avg, company_avg
WHERE dept_avg.avg_salary > company_avg.avg_salary;


-- Q6: Running Salary Total
SELECT 
    d.name AS department_name,
    e.first_name,
    e.last_name,
    e.hire_date,
    e.salary,
    SUM(e.salary) OVER (PARTITION BY e.department_id ORDER BY e.hire_date) AS running_total
FROM employees e
JOIN departments d ON e.department_id = d.department_id;


-- Q7: Unassigned Employees
SELECT 
    e.first_name,
    e.last_name,
    d.name AS department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
LEFT JOIN project_assignments pa ON e.employee_id = pa.employee_id
WHERE pa.employee_id IS NULL;


-- Q8: Hiring Trends
SELECT 
    EXTRACT(YEAR FROM hire_date) AS hire_year,
    EXTRACT(MONTH FROM hire_date) AS hire_month,
    COUNT(*) AS hires
FROM employees
GROUP BY hire_year, hire_month
ORDER BY hire_year, hire_month;


-- Q9: Schema Design — Employee Certifications
-- CREATE TABLE certifications
CREATE TABLE IF NOT EXISTS certifications (
    certification_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    issuing_org VARCHAR(100),
    level VARCHAR(50)
);

-- CREATE TABLE employee_certifications
CREATE TABLE IF NOT EXISTS employee_certifications (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    certification_id INTEGER NOT NULL REFERENCES certifications(certification_id),
    certification_date DATE NOT NULL
);

-- INSERT sample certifications
INSERT INTO certifications (name, issuing_org, level) VALUES
('AWS Solutions Architect', 'Amazon', 'Advanced'),
('Scrum Master', 'Scrum Alliance', 'Intermediate'),
('Python Programming', 'Coursera', 'Beginner');

-- INSERT sample employee certifications (use existing employee_ids)
INSERT INTO employee_certifications (employee_id, certification_id, certification_date) VALUES
(1, 1, '2023-01-15'),
(2, 2, '2023-02-20'),
(3, 3, '2023-03-10'),
(1, 2, '2023-04-05'),
(4, 1, '2023-05-12');

-- Query to list employees with their certifications
SELECT 
    e.first_name,
    e.last_name,
    c.name AS certification_name,
    c.issuing_org,
    ec.certification_date
FROM employee_certifications ec
JOIN employees e ON ec.employee_id = e.employee_id
JOIN certifications c ON ec.certification_id = c.certification_id;

