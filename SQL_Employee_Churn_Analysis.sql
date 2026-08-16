#Q1: Ty le Churn Tong

SELECT 
  ROUND(AVG(churn)*100,3) as churn_rate
 FROM `project-1-library-management.project_dataset.employee_churn`;

#Q2: Ty le Churn theo department

SELECT 
  department,
  ROUND(AVG(churn)*100,2) as churn_rate
 FROM `project-1-library-management.project_dataset.employee_churn`
 GROUP BY department
 ORDER BY churn_rate DESC
 ;

#Q3: Churn rate theo job role

SELECT 
  job_role,
  COUNT(employee_id) as number_of_employees,
  ROUND(AVG(churn)*100,2) as churn_rate
 FROM `project-1-library-management.project_dataset.employee_churn`
 GROUP BY job_role
 ORDER BY churn_rate DESC
 ;

 #Q4: Luong theo job role

SELECT 
  job_role,
  COUNT(employee_id) as number_of_employees,
  MAX(salary) as max_salary,
  ROUND(AVG(salary),2) as avg_salary,
  MIN(salary) as min_salary
 FROM `project-1-library-management.project_dataset.employee_churn`
 GROUP BY job_role
 ORDER BY avg_salary DESC
 ;

#Q5: Phan bo gioi tin + churn
SELECT 
  gender,
  COUNT(employee_id) as number_of_employees,
  ROUND(AVG(churn)*100,2) as churn_rate
 FROM `project-1-library-management.project_dataset.employee_churn`
 GROUP BY gender
 ORDER BY churn_rate DESC
 ;

 #Q6: Luong co correlate performance?
 ## luong TB giua cac nhom khong co chenh lech nhieu

SELECT 
  CASE 
    WHEN performance_rating >= 4 THEN 'Top Performers (4-5)'
    WHEN performance_rating <= 2 THEN 'Low Performers(1-2)'
    ELSE 'Avg Performers (3)' 
    END AS performer_catergory,
  COUNT(*) as number_employee,
  MAX(salary) as max_salary,
  ROUND(AVG(salary),2) as avg_salary,
  MIN(salary) as min_salary,
  ROUND(AVG(churn)*100,2) as churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY performer_catergory
ORDER BY avg_salary DESC
;

#Q7: Overtime anh huong churn rate khong?
SELECT 
  CASE 
    WHEN overtime_hours = 0 THEN '1. No OT'
    WHEN overtime_hours <= 10 THEN '2. OT 1-10h'
    WHEN overtime_hours <= 20 THEN '3. OT 10-20h'
    ELSE 'OT above 20h' 
    END AS overtime_catergory,
  COUNT(*) as number_of_employees,
  ROUND(AVG(churn)*100,2) as churn_rate,
  ROUND(AVG(satisfaction_level)*100,2) as avg_satisfaction_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY overtime_catergory
ORDER BY overtime_catergory
;

#Q8: Khoi luong cong viec (do bang average_monthly_hours_worked) x satisfaction --> xem ti le roi bo nhu the nao?
#Monthly hours -> co Min la 150, MAX la 299, Avg la 224
## So gio lam TB, 1 ngay 8 tieng, khoang 160-184 (20-23 ngay) --> Gia su lay moc 180 lam chuan
### duoi 180,180-220, 220-269, 260+

SELECT
  CASE 
    WHEN average_monthly_hours_worked <=180 THEN "1. Below 180h"
    WHEN average_monthly_hours_worked <=220 THEN "2.181-220h"
    WHEN average_monthly_hours_worked <=260 THEN "3. 221-260" 
    ELSE "4. Above 260h" 
    END AS avg_working_hours_category,
  CASE
    WHEN satisfaction_level <= 0.33 THEN "1. Low satisfaction"
    WHEN satisfaction_level <= 0.66 THEN "2. Avg satisfaction"
    ELSE "3. High satisfication" 
    END AS satisfication_category,
  COUNT(*) as number_of_employees,
  ROUND(AVG(churn)*100,2) as churn_rate 
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY avg_working_hours_category , satisfication_category
ORDER BY avg_working_hours_category , satisfication_category
;

#Q9: dept theo absenteeism
SELECT 
  department,
    COUNT(employee_id) as number_of_employees,
  ROUND(AVG(absenteeism),2) as avg_absenteeism,
  MAX(absenteeism) as max_absenteeism,
  ROUND(AVG(churn)*100,2) as churn_rate
 FROM `project-1-library-management.project_dataset.employee_churn`
 GROUP BY department
 ORDER BY avg_absenteeism DESC
 ;

#Q10: Manager feedback vs promotion co correlation cao ko?
##Chia feedback cua manager thanh low,mid,high -> so lan promotion trung binh
### Promtions chi ghi nhan co thang chuc hay khong? -> ko noi ve so lan -> chi co the tinh rate

SELECT 
  CASE 
    WHEN manager_feedback_score <=4 THEN "1. Low (0-4)"
    WHEN manager_feedback_score <=7 THEN "2. Mid (5-7)"
    ELSE "3. High (8-10)" 
  END AS feedback_category,
  COUNT(employee_id) as number_of_employees,
  ROUND(AVG(promotions)*100,2) as avg_promotions_rate,
  ROUND(AVG(churn)*100,2) as churn_rate
 FROM `project-1-library-management.project_dataset.employee_churn`
 GROUP BY feedback_category
 ORDER BY feedback_category
;

#Q11: Danh sach underpaid employee (<25%) cho tung role
## B1: Can so Avg cua role do
### B2: loc ra cac id -> Avg cua role do < 25% so  vsavg_role_salary
WITH role_salary AS (
  SELECT
  job_role,
  ROUND(AVG(salary),2) as avg_role_salary
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY job_role
)

SELECT
  e.employee_id,
  e.job_role,
  e.department,
  e.salary,
  r.avg_role_salary,
  ROUND(SAFE_DIVIDE((e.salary-r.avg_role_salary),r.avg_role_salary)*100,2) as gap_pct,
  e.performance_rating,
  e.churn
FROM `project-1-library-management.project_dataset.employee_churn` e
JOIN role_salary r
  ON e.job_role = r.job_role
WHERE e.salary <= avg_role_salary*0.75 ## Thap hon 25% so voi TB -> <=75
ORDER BY gap_pct, employee_id
;

#Q12: Tenture Decile vs Churn
WITH tenure_decile AS (
  SELECT 
  employee_id,
  tenure,
  churn,
  NTILE(10) OVER (ORDER BY tenure, employee_id) as tenure_decile
FROM `project-1-library-management.project_dataset.employee_churn` e
)

SELECT
  t.tenure_decile,
  MIN(e.tenure) as min_tenture,
  MAX(e.tenure) as max_tenture,
  COUNT(e.employee_id) as number_of_employee,
  SUM(e.churn) as total_churned,
  ROUND(AVG(e.churn)*100,2) as churn_rate
FROM `project-1-library-management.project_dataset.employee_churn` e
JOIN tenure_decile t
  ON e.employee_id = t.employee_id
GROUP BY t.tenure_decile
ORDER BY t.tenure_decile
;
#Q13: Risk Score composite
## đo lường risk bằng gì? Risk = distance_from_home, absenteeism, satisfaction_level, OT 

WITH risk_dataset AS (
  SELECT
    employee_id,
    department,
    job_role,
    overtime_hours,
    satisfaction_level,
    absenteeism,
    distance_from_home,
    promotions,
    churn,
    NTILE(5) OVER (ORDER BY overtime_hours, employee_id) AS overtime_score,
    NTILE(5) OVER (ORDER BY satisfaction_level DESC, employee_id) AS satisfaction_score,
    NTILE(5) OVER (ORDER BY absenteeism, employee_id) AS absenteeism_score,
    NTILE(5) OVER (ORDER BY distance_from_home, employee_id) AS distance_score,
    CASE WHEN promotions = 0 THEN 5 ELSE 1 END AS promotion_score
FROM `project-1-library-management.project_dataset.employee_churn` 
)

SELECT 
  employee_id,
  department,
  job_role,
  overtime_score + satisfaction_score + absenteeism_score + distance_score + promotion_score AS risk_score,
  overtime_hours,
  satisfaction_level,
  absenteeism,
  distance_from_home,
  promotions,
  churn
FROM risk_dataset r
ORDER BY risk_score DESC, employee_id
LIMIT 100
;
#Q14: Cohort by hire year
### dataset khong co thoi gian lam viec -> se dung tenure --> de tinh thoi gian hire year
### Gia dinh la 2026, dung phep tru de tinh hire year
WITH cohorts AS 
(
  SELECT
    e.employee_id,
    e.tenure,
    e.churn,
    2026 - e.tenure AS hire_year
  FROM `project-1-library-management.project_dataset.employee_churn` e
)

SELECT
  hire_year,
  MIN(tenure) AS tenure_years,
  COUNT(*) AS employees,
  SUM(churn) AS total_churned,
  ROUND(AVG(churn)*100,2) as churn_rate
FROM cohorts
GROUP BY hire_year
ORDER BY hire_year
;

#Q15: Peer Gap Salary --> Flag employee gap dưới 10%
WITH peer_dataset AS 
(
  SELECT
    e.employee_id,
    e.job_role,
    e.department,
    e.salary,
    e.performance_rating,
    e.churn,
    AVG(e.salary) OVER (PARTITION BY e.job_role) AS peer_avg_salary
FROM `project-1-library-management.project_dataset.employee_churn` e
)

SELECT
  employee_id,
  job_role,
  department,
  salary,
  ROUND(peer_avg_salary,2) as peer_avg_salary,
  ROUND(SAFE_DIVIDE((salary - peer_avg_salary), peer_avg_salary)*100,2) as gap_pct,
  performance_rating,
  churn
FROM peer_dataset
WHERE salary < peer_avg_salary*0.90
ORDER BY gap_pct, employee_id;