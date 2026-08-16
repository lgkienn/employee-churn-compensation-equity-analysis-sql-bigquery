# 👥 Employee Churn & Workforce Equity Analysis | SQL, BigQuery

**Tools Used:** SQL, Google BigQuery

---

## 📑 Table of Contents

[📌 Background & Overview](https://claude.ai/chat/c1e15faf-9cd7-42fb-bd43-24bbf7f96058#-background--overview) 
[📂 Dataset Description & Data Structure](https://claude.ai/chat/c1e15faf-9cd7-42fb-bd43-24bbf7f96058#-dataset-description--data-structure)
[⚒️ Main Process](https://claude.ai/chat/c1e15faf-9cd7-42fb-bd43-24bbf7f96058#%EF%B8%8F-main-process)
[🔎 Final Conclusion & Recommendations](https://claude.ai/chat/c1e15faf-9cd7-42fb-bd43-24bbf7f96058#-final-conclusion--recommendations)

---

## 📌 Background & Overview

### 📖 Business context

**Xóm HR** is a mid-sized technology company with roughly **10,000 employees**. Leadership wants to understand why people are leaving. The available data is a **point-in-time snapshot** covering demographics, job role, performance metrics, work-life indicators, and a binary flag for whether each employee has already left.

This project is delivered from the position of a **People Analytics Analyst**, using **SQL** on **Google BigQuery** to answer 15 ad-hoc requests from three stakeholder groups:

|Stakeholder|What they asked for|Where it is answered|
|---|---|---|
|**Head of People**|Which factors does churn actually correlate with? What interventions should we fund — flex time, raises, promotion paths?|Q1–Q3, Q5, Q7, Q8, Q12, Q14|
|**Compensation team**|Is pay fair across role and tenure?|Q4, Q6, Q11, Q15|
|**Engineering managers**|Which teams are at risk of losing key talent?|Q9, Q10, Q13|

### 🎯 What this analysis set out to do

- ✔️ **Establish the baseline** churn rate and check whether it varies by department, role, or gender.
- ✔️ **Test common HR assumptions** — does overtime drive churn? Does low pay? Does poor performance?
- ✔️ **Audit compensation equity** — is pay linked to performance, and who is substantially underpaid versus their peers?
- ✔️ **Build a composite risk score** to rank employees by attrition risk.
- ✔️ **Evaluate whether the existing data is sufficient** to support a predictive retention model.

### 🧭 A note on methodology

The overall churn rate is **20.28%**, and I used that as the reference line for every segment.

Something became clear early on: most segments land within about one percentage point of that baseline. Across 10,000 employees, a gap that small doesn't give me anything to act on — so instead of presenting every ranking as a finding, I report **how wide the spread actually is**, and say plainly when a difference is too small to build a recommendation on.

The alternative would have been to write "Marketing has the highest churn" and let a reader assume that means something. It doesn't — Marketing is 0.54pp above the lowest department. Saying so is more useful than a ranked list that implies a hotspot that isn't there.

### 👤 Who is this project for?

- ✔️ **HR Analytics & People Ops teams**
- ✔️ **Data Analysts & Business Analysts**
- ✔️ **Compensation & Benefits teams**
- ✔️ **Business Intelligence teams**

---

## 📂 Dataset Description & Data Structure

**📌 Data Source:** [Xóm Dataset — `employees_churn`](https://dataset.xomdata.com/datasets/schema/employees_churn)

**📌 Data Size:** 10,000 employee records · 1 table (`employees_churn.employee_info`) · 22 columns

**📌 Working table:** `project-1-library-management.project_dataset.employee_churn` (loaded into BigQuery)

**📌 Schema** — the 15 columns used in this analysis:

|Column|Type|Description|
|---|---|---|
|`employee_id`|STRING|Unique employee identifier — **masked in this report**|
|`department`|STRING|HR, IT, Sales, Marketing|
|`job_role`|STRING|Developer, Analyst, Manager, Sales|
|`gender`|STRING|Female, Male, Other|
|`salary`|INTEGER|Annual salary (30,010 – 149,993)|
|`tenure`|INTEGER|Years with the company (0 – 14)|
|`performance_rating`|INTEGER|Rating from 1 to 5|
|`manager_feedback_score`|INTEGER|Manager feedback from 0 to 10|
|`satisfaction_level`|FLOAT|Self-reported satisfaction, 0.0 – 1.0|
|`average_monthly_hours_worked`|INTEGER|Monthly hours (150 – 299)|
|`overtime_hours`|INTEGER|Overtime hours|
|`absenteeism`|INTEGER|Days absent (0 – 19)|
|`distance_from_home`|INTEGER|Commute distance|
|`promotions`|INTEGER|Promotion flag (0 / 1)|
|`churn`|INTEGER|Target variable — 1 = left, 0 = stayed|

### 🔒 Privacy handling

Two of these queries return **named lists of individuals** — employees flagged as underpaid (Q11, Q15) and employees ranked as highest attrition risk (Q13). Publishing those identifiers would expose specific people as flight risks or as underpaid, which is exactly the kind of disclosure a people-analytics report has to avoid.

Accordingly:

- **All `employee_id` values in this report are masked** and replaced with surrogate labels (`EMP-001`, `EMP-002`, …). The queries themselves are unmodified and return real IDs when run.
- Individual-level output is shown only as a **top-10 sample** to demonstrate query structure; the full result sets are summarised in aggregate.
- Individual-level lists of this kind belong in a **restricted HR system with access controls**, not in a shared report. Aggregate findings are what should circulate.

**📌 How to access the data:**

1. Register for credentials at [Xóm Dataset](https://dataset.xomdata.com/account).
2. Query directly via SSMS / DBeaver, or export and load into **BigQuery**.
3. For BigQuery: open the **BigQuery Console**, select your project, and upload the source table.

---

## ⚒️ Main Process

### Theme 1 — Establishing the baseline

#### 🔍 Q1. What is the overall churn rate?

The starting point for every other comparison. Every segment below is judged against this number.

**🚀 Query**

```sql
SELECT
  ROUND(AVG(churn)*100,3) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`;
```

**💡 Result**

|churn_rate|
|---|
|20.28|

Roughly **one in five employees has left**. This is high in absolute terms and becomes the reference line for the rest of the analysis.

---

#### 🔍 Q2. Does churn differ by department?

Testing whether attrition is concentrated in any part of the organisation — the usual first question from stakeholders, and the usual basis for allocating retention budget.

**🚀 Query**

```sql
SELECT
  department,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY department
ORDER BY churn_rate DESC;
```

**💡 Result**

|department|churn_rate|
|---|---|
|Marketing|20.75|
|HR|20.25|
|IT|20.23|
|Sales|20.21|

The full spread from highest to lowest is **0.54 percentage points**. Every department sits within half a point of the 20.28% company baseline.

Marketing ranks first, but ranking first out of four near-identical numbers doesn't make it a hotspot. **Churn here is not a departmental problem.**

---

#### 🔍 Q3. Does churn differ by job role?

Repeating the test one level down, in case attrition is concentrated by function rather than by department.

**🚀 Query**

```sql
SELECT
  job_role,
  COUNT(employee_id) AS number_of_employees,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY job_role
ORDER BY churn_rate DESC;
```

**💡 Result**

|job_role|number_of_employees|churn_rate|
|---|---|---|
|Developer|4,008|20.63|
|Manager|2,022|20.47|
|Analyst|2,989|20.11|
|Sales|981|18.96|

Spread is **1.67 percentage points** — wider than the departmental cut, but still narrow. Sales sits lowest at 18.96%, though it is also by far the smallest group (981 employees, under 10% of the workforce), so a handful of individuals moves that number more than it moves the others.

Same conclusion as Q2: no role stands out as a churn risk.

---

#### 🔍 Q5. Does churn differ by gender?

A standard equity check, and the first cut where one group clearly separates from the rest.

**🚀 Query**

```sql
SELECT
  gender,
  COUNT(employee_id) AS number_of_employees,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY gender
ORDER BY churn_rate DESC;
```

**💡 Result**

|gender|number_of_employees|churn_rate|
|---|---|---|
|Female|4,826|20.99|
|Male|4,973|19.91|
|Other|201|12.44|

Female and Male differ by **1.08pp** — the same narrow range seen everywhere else.

**Other** is different: 12.44%, nearly 8 points below baseline. But the group is only **201 employees**, around 2% of the workforce. At that size, roughly 16 people leaving instead of 25 produces the entire gap. I've flagged it as something worth looking into rather than treating it as a finding — the group is too small for me to be confident the pattern is real.

---

### Theme 2 — Testing the workload hypothesis

#### 🔍 Q7. Does overtime drive churn?

The most common assumption in retention conversations: people burn out on overtime and leave.

**🚀 Query**

```sql
SELECT
  CASE
    WHEN overtime_hours = 0 THEN '1. No OT'
    WHEN overtime_hours <= 10 THEN '2. OT 1-10h'
    WHEN overtime_hours <= 20 THEN '3. OT 10-20h'
    ELSE 'OT above 20h'
    END AS overtime_catergory,
  COUNT(*) AS number_of_employees,
  ROUND(AVG(churn)*100,2) AS churn_rate,
  ROUND(AVG(satisfaction_level)*100,2) AS avg_satisfaction_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY overtime_catergory
ORDER BY overtime_catergory;
```

**💡 Result**

|overtime_catergory|number_of_employees|churn_rate|avg_satisfaction_rate|
|---|---|---|---|
|1. No OT|216|25.00|49.06|
|2. OT 1-10h|2,068|19.63|49.58|
|3. OT 10-20h|2,019|20.60|50.26|
|OT above 20h|5,697|20.22|49.21|

The three groups that actually work overtime sit at **19.63%, 20.60% and 20.22%** — a spread of one point, all at baseline. Working 20+ overtime hours produces no more churn than working 1–10.

Satisfaction tells the same story: flat at **49–50%** across all four bands, including the heaviest overtime group.

The "No OT" group shows 25.00%, the highest figure in the table — but it holds only **216 employees**, about 2% of the workforce, so I'd want a larger sample before reading much into it. It is interesting that the _lowest_ workload group churns highest, and Q8 follows that thread.

**The overtime hypothesis is not supported by this data.**

**The overtime hypothesis is not supported.**

---

#### 🔍 Q8. Do workload and satisfaction interact to drive churn?

A two-dimensional cut, splitting monthly hours into four bands against three satisfaction levels. Thresholds were set from the data: monthly hours run 150–299 with a mean of 224, and a standard 8-hour day over 20–23 working days gives 160–184 hours, so 180 was used as the "normal load" boundary.

**🚀 Query**

```sql
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
  COUNT(*) AS number_of_employees,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY avg_working_hours_category , satisfication_category
ORDER BY avg_working_hours_category , satisfication_category;
```

**💡 Result**

|avg_working_hours_category|satisfication_category|number_of_employees|churn_rate|
|---|---|---|---|
|1. Below 180h|1. Low satisfaction|728|21.84|
|1. Below 180h|2. Avg satisfaction|689|20.03|
|1. Below 180h|3. High satisfaction|697|22.09|
|2. 181-220h|1. Low satisfaction|896|22.10|
|2. 181-220h|2. Avg satisfaction|876|22.15|
|2. 181-220h|3. High satisfaction|860|20.70|
|3. 221-260h|1. Low satisfaction|871|21.70|
|3. 221-260h|2. Avg satisfaction|891|18.29|
|3. 221-260h|3. High satisfaction|844|20.38|
|4. Above 260h|1. Low satisfaction|904|17.70|
|4. Above 260h|2. Avg satisfaction|875|18.06|
|4. Above 260h|3. High satisfaction|869|18.99|

Collapsing to the working-hours margin:

|Hours band|Employees|Churn rate|
|---|---|---|
|≤180h|2,114|21.33|
|181–220h|2,632|21.66|
|221–260h|2,606|20.11|
|>260h|2,648|**18.24**|

This is the **widest and most consistent pattern I found** — a **3.09pp** drop from the lowest hours band to the highest, and unlike every other cut in this project it moves in one direction the whole way down. Each band holds 2,000+ employees, so the trend isn't resting on a small group.

It also runs **opposite to what I expected**. Going in, I assumed heavy hours would predict burnout and exits.

By contrast, the satisfaction margin is flat: Low 20.77%, Avg 19.60%, High 20.46%.

**This is the clearest behavioural pattern in the dataset: employees working the most hours are the least likely to leave, and satisfaction barely moves churn at all.**

---

### Theme 3 — Compensation and performance

#### 🔍 Q4. How does salary vary by job role?

Establishing the pay structure before auditing it for equity.

**🚀 Query**

```sql
SELECT
  job_role,
  COUNT(employee_id) AS number_of_employees,
  MAX(salary) AS max_salary,
  ROUND(AVG(salary),2) AS avg_salary,
  MIN(salary) AS min_salary
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY job_role
ORDER BY avg_salary DESC;
```

**💡 Result**

|job_role|number_of_employees|max_salary|avg_salary|min_salary|
|---|---|---|---|---|
|Sales|981|149,749|90,861.99|30,122|
|Analyst|2,989|149,993|89,814.91|30,107|
|Manager|2,022|149,955|89,709.39|30,010|
|Developer|4,008|149,930|89,506.68|30,029|

Average salaries differ by **1.5%** across all four roles, and every role spans essentially the full 30k–150k range. **There is no salary band structure by role** — a Manager and a Developer are paid from the same distribution.

---

#### 🔍 Q6. Is salary correlated with performance?

Testing whether the pay system rewards performance — a compensation-design question independent of churn.

**🚀 Query**

```sql
SELECT
  CASE
    WHEN performance_rating >= 4 THEN 'Top Performers (4-5)'
    WHEN performance_rating <= 2 THEN 'Low Performers(1-2)'
    ELSE 'Avg Performers (3)'
    END AS performer_catergory,
  COUNT(*) AS number_employee,
  MAX(salary) AS max_salary,
  ROUND(AVG(salary),2) AS avg_salary,
  MIN(salary) AS min_salary,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY performer_catergory
ORDER BY avg_salary DESC;
```

**💡 Result**

|performer_catergory|number_employee|max_salary|avg_salary|min_salary|churn_rate|
|---|---|---|---|---|---|
|Low Performers (1-2)|3,935|149,993|89,948.78|30,029|19.87|
|Top Performers (4-5)|4,092|149,926|89,846.49|30,010|20.11|
|Avg Performers (3)|1,973|149,912|89,268.74|30,040|21.44|

**Low performers earn slightly more on average than top performers** — $89,949 against $89,846. The gap is tiny, and that is exactly the point: if pay rewarded performance, top performers would be clearly ahead. They aren't. Average salary varies by **0.76%** across the three groups, so **pay and performance are effectively unrelated here**.

Churn is flat too (19.87% / 20.11% / 21.44%). The company isn't losing its best people faster than anyone else — but it isn't paying them more either.

---

#### 🔍 Q11 & Q15. Who is underpaid relative to their peers?

A two-threshold salary equity audit. **Q11** flags employees more than 25% below their role average; **Q15** widens the net to 10% using a window function. Q11 is a strict subset of Q15 — the two thresholds give a severe tier and a watch tier.

**🚀 Query — Q11 (25% threshold, CTE approach)**

```sql
WITH role_salary AS (
  SELECT
    job_role,
    ROUND(AVG(salary),2) AS avg_role_salary
  FROM `project-1-library-management.project_dataset.employee_churn`
  GROUP BY job_role
)

SELECT
  e.employee_id,
  e.job_role,
  e.department,
  e.salary,
  r.avg_role_salary,
  ROUND(SAFE_DIVIDE((e.salary-r.avg_role_salary),r.avg_role_salary)*100,2) AS gap_pct,
  e.performance_rating,
  e.churn
FROM `project-1-library-management.project_dataset.employee_churn` e
JOIN role_salary r
  ON e.job_role = r.job_role
WHERE e.salary <= avg_role_salary*0.75
ORDER BY gap_pct, employee_id;
```

**💡 Result — Q11** (3,090 rows, top 10 shown)

|employee_id|job_role|department|salary|avg_role_salary|gap_pct|performance_rating|churn|
|---|---|---|---|---|---|---|---|
|EMP-001|Sales|HR|30,122|90,861.99|-66.85|4|0|
|EMP-002|Sales|Sales|30,203|90,861.99|-66.76|3|1|
|EMP-003|Sales|Marketing|30,212|90,861.99|-66.75|2|0|
|EMP-004|Sales|IT|30,281|90,861.99|-66.67|5|0|
|EMP-005|Sales|IT|30,310|90,861.99|-66.64|1|0|
|EMP-006|Sales|IT|30,310|90,861.99|-66.64|1|0|
|EMP-007|Sales|Sales|30,371|90,861.99|-66.57|2|0|
|EMP-008|Manager|Sales|30,010|89,709.39|-66.55|4|0|
|EMP-009|Analyst|Sales|30,107|89,814.91|-66.48|2|0|
|EMP-010|Developer|HR|30,029|89,506.68|-66.45|1|0|

**🚀 Query — Q15 (10% threshold, window function approach)**

```sql
WITH peer_dataset AS (
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
  ROUND(peer_avg_salary,2) AS peer_avg_salary,
  ROUND(SAFE_DIVIDE((salary - peer_avg_salary), peer_avg_salary)*100,2) AS gap_pct,
  performance_rating,
  churn
FROM peer_dataset
WHERE salary < peer_avg_salary*0.90
ORDER BY gap_pct, employee_id;
```

**💡 Result — Q15** (4,233 rows, summary)

|Threshold|Employees flagged|% of workforce|Mean gap|Churn rate|
|---|---|---|---|---|
|Q11 — more than 25% below role average|3,090|30.9%|-45.88%|**19.35%**|
|Q15 — more than 10% below role average|4,233|42.3%|-38.29%|**20.32%**|
|— Company baseline|10,000|100%|—|20.28%|

**Being underpaid does not appear to increase churn in this dataset.** The severely underpaid group (Q11) actually churns _below_ the company baseline. Note also that top performers appear in the most underpaid rows (EMP-004 has a rating of 5 and earns 66.67% below the role average), which reinforces the Q6 finding that pay is disconnected from performance.

---

#### 🔍 Q10. Does manager feedback predict promotion?

Checking whether the performance review process actually feeds into personnel decisions. `promotions` is a binary flag rather than a count, so this is measured as a promotion _rate_.

**🚀 Query**

```sql
SELECT
  CASE
    WHEN manager_feedback_score <=4 THEN "1. Low (0-4)"
    WHEN manager_feedback_score <=7 THEN "2. Mid (5-7)"
    ELSE "3. High (8-10)"
  END AS feedback_category,
  COUNT(employee_id) AS number_of_employees,
  ROUND(AVG(promotions)*100,2) AS avg_promotions_rate,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY feedback_category
ORDER BY feedback_category;
```

**💡 Result**

|feedback_category|number_of_employees|avg_promotions_rate|churn_rate|
|---|---|---|---|
|1. Low (0-4)|3,276|10.16|20.05|
|2. Mid (5-7)|3,304|9.69|20.55|
|3. High (8-10)|3,420|10.44|20.23|

Employees rated 8–10 by their manager are promoted at **10.44%**; those rated 0–4 at **10.16%**. A **0.28 percentage point** difference — and the middle group is actually the _lowest_ of the three, so there is no upward trend at all.

Churn is equally flat across the three bands (20.05% / 20.55% / 20.23%).

**The manager feedback process has no observable influence on who gets promoted.**

---

### Theme 4 — Tenure, absence and composite risk

#### 🔍 Q9. Does absenteeism vary by department?

Checking absence as a potential leading indicator of disengagement.

**🚀 Query**

```sql
SELECT
  department,
  COUNT(employee_id) AS number_of_employees,
  ROUND(AVG(absenteeism),2) AS avg_absenteeism,
  MAX(absenteeism) AS max_absenteeism,
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn`
GROUP BY department
ORDER BY avg_absenteeism DESC;
```

**💡 Result**

|department|number_of_employees|avg_absenteeism|max_absenteeism|churn_rate|
|---|---|---|---|---|
|Sales|3,038|9.50|19|20.21|
|IT|3,974|9.45|19|20.23|
|HR|2,000|9.45|19|20.25|
|Marketing|988|9.44|19|20.75|

Average absenteeism varies by **0.06 days** across departments, with an identical maximum of 19. Absence is uniformly distributed and carries no departmental signal.

---

#### 🔍 Q12. How does churn vary across tenure deciles?

Splitting the workforce into ten equal tenure groups to look for a churn curve — typically expected to spike early (onboarding failure) and late (career ceiling).

**🚀 Query**

```sql
WITH tenure_decile AS (
  SELECT
    employee_id,
    tenure,
    churn,
    NTILE(10) OVER (ORDER BY tenure, employee_id) AS tenure_decile
  FROM `project-1-library-management.project_dataset.employee_churn` e
)

SELECT
  t.tenure_decile,
  MIN(e.tenure) AS min_tenture,
  MAX(e.tenure) AS max_tenture,
  COUNT(e.employee_id) AS number_of_employee,
  SUM(e.churn) AS total_churned,
  ROUND(AVG(e.churn)*100,2) AS churn_rate
FROM `project-1-library-management.project_dataset.employee_churn` e
JOIN tenure_decile t
  ON e.employee_id = t.employee_id
GROUP BY t.tenure_decile
ORDER BY t.tenure_decile;
```

**💡 Result**

|tenure_decile|min_tenture|max_tenture|number_of_employee|total_churned|churn_rate|
|---|---|---|---|---|---|
|1|0|1|1,000|184|18.40|
|2|1|2|1,000|188|18.80|
|3|3|4|1,000|218|21.80|
|4|4|5|1,000|182|18.20|
|5|6|7|1,000|220|22.00|
|6|7|8|1,000|226|22.60|
|7|8|10|1,000|199|19.90|
|8|10|11|1,000|213|21.30|
|9|11|13|1,000|201|20.10|
|10|13|14|1,000|197|19.70|

I expected a curve here — a spike in the earliest deciles (onboarding failure) and another at the top end (career ceiling). Neither appears.

The values oscillate between **18.2% and 22.6%** with no direction: decile 4 sits at 18.20%, decile 6 at 22.60%, decile 10 back down at 19.70%. Each decile holds exactly 1,000 employees, so the groups are equally sized and the jumping around isn't a sample-size artefact — it just doesn't trend.

**No early-tenure cliff, no late-tenure ceiling.**

---

#### 🔍 Q14. Does churn vary by hire-year cohort?

**⚠️ Methodological note:** the dataset contains no hire date, so hire year is derived as `2026 - tenure`. This makes the cohort a **linear transform of tenure** — Q14 and Q12 describe the same underlying variable cut two different ways. It is included for completeness and for the year-over-year view, not as an independent finding.

**🚀 Query**

```sql
WITH cohorts AS (
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
  ROUND(AVG(churn)*100,2) AS churn_rate
FROM cohorts
GROUP BY hire_year
ORDER BY hire_year;
```

**💡 Result**

|hire_year|tenure_years|employees|total_churned|churn_rate|
|---|---|---|---|---|
|2012|14|654|131|20.03|
|2013|13|654|120|18.35|
|2014|12|675|142|21.04|
|2015|11|641|137|21.37|
|2016|10|644|139|21.58|
|2017|9|668|128|19.16|
|2018|8|692|157|22.69|
|2019|7|665|149|22.41|
|2020|6|707|153|21.64|
|2021|5|679|127|18.70|
|2022|4|686|142|20.70|
|2023|3|635|131|20.63|
|2024|2|690|131|18.99|
|2025|1|650|117|18.00|
|2026|0|660|124|18.79|

Hiring volume is near-constant at ~660 per year, and churn oscillates between 18.0% and 22.7% with no trend. **No cohort stands out.**

---

#### 🔍 Q13. Composite attrition risk score

Rather than testing factors one at a time, this builds a **composite risk score** by ranking employees into quintiles on each of four continuous risk factors and adding a binary promotion penalty.

Each `NTILE(5)` is oriented so that **5 = highest risk**: high overtime, _low_ satisfaction (hence `ORDER BY satisfaction_level DESC`), high absenteeism, and long commute. Employees never promoted score 5; those promoted score 1. The score therefore ranges from **5 (lowest risk) to 25 (highest risk)**.

**🚀 Query**

```sql
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
LIMIT 100;
```

**💡 Result** (100 rows, top 10 shown)

|employee_id|department|job_role|risk_score|overtime_hours|satisfaction_level|absenteeism|distance_from_home|promotions|churn|
|---|---|---|---|---|---|---|---|---|---|
|EMP-011|Sales|Manager|25|49|0.10|16|49|0|0|
|EMP-012|IT|Developer|25|45|0.06|16|45|0|1|
|EMP-013|IT|Developer|25|42|0.16|17|43|0|0|
|EMP-014|HR|Analyst|25|44|0.14|16|46|0|1|
|EMP-015|Sales|Analyst|25|44|0.01|18|48|0|0|
|EMP-016|Sales|Developer|25|40|0.14|19|40|0|1|
|EMP-017|HR|Sales|25|44|0.17|19|43|0|0|
|EMP-018|Sales|Manager|25|47|0.05|17|49|0|0|
|EMP-019|Sales|Analyst|25|40|0.12|17|45|0|0|
|EMP-020|Marketing|Analyst|25|46|0.16|19|47|0|0|

**Validation of the score:**

|Group|Employees|Churn rate|
|---|---|---|
|Top 100 by risk score|100|22.00|
|Company baseline|10,000|20.28|

The 100 employees the model ranks as _most_ at risk churn at **22.0%**, against a **20.28%** baseline — a lift of just **1.7pp**.

That is the honest verdict on the score: **it barely separates leavers from stayers.** 78 of the top 100 flagged employees had not left. If you sorted 100 employees at random you would expect around 20 leavers; this model finds 22.

The construction is sound — the components are correctly oriented and the score behaves as designed. The problem is upstream: the five input variables don't carry enough signal about who leaves. Q7 and Q12 already showed that overtime and tenure barely move churn, so a score built mostly from those factors was never going to separate the groups cleanly.

Departmental composition of the top-100 risk group (IT 45, HR 24, Sales 23, Marketing 8) reflects the commute and overtime distributions, not a genuine concentration of risk.

---

## 🔎 Final Conclusion & Recommendations

### 📌 Insights

1. **Attrition is systemic, not localised.** Churn sits at 20.28% and stays within roughly a point of that across every department (0.54pp spread), job role (1.67pp), tenure decile and hire-year cohort. There is no hotspot to target — which means retention budget allocated by department has nothing in this data to justify it.
    
2. **The overtime hypothesis doesn't hold, and the reverse may be true.** Monthly hours is the only variable that produced a consistent trend: employees working over 260h/month churn at **18.24%**, versus **21.33%** for those under 180h — and it declines steadily in between. My reading is that low-hours employees may already be disengaged and on their way out, which would make **low** utilisation the warning sign rather than high. That is an interpretation, not something the data proves; testing it would need project allocation data this snapshot doesn't contain.
    
3. **Satisfaction score has no predictive value.** Churn across low, average and high satisfaction bands is 20.77%, 19.60% and 20.46% respectively. Whatever the satisfaction survey is measuring, it is not capturing intent to leave.
    
4. **Pay is disconnected from performance.** Low performers average $89,949 and top performers $89,846 — top performers earn marginally _less_. Salary ranges are also identical across all four job roles (30k–150k), indicating there is no functioning salary band structure.
    
5. **Underpayment is widespread but is not driving exits.** 30.9% of employees earn more than 25% below their role average (mean gap -45.9%), and 42.3% are more than 10% below. Yet the severely underpaid group churns at 19.35% — _below_ baseline. Underpayment is a live equity and legal-exposure problem, but it is not the churn mechanism.
    
6. **The performance review process is not connected to promotion.** Employees rated 8–10 by their manager are promoted at 10.44%; those rated 0–4 at 10.16%. A 0.28pp difference across 10,000 employees means manager feedback is effectively ignored in promotion decisions.
    
7. **The available variables cannot support a predictive retention model.** The composite risk score — combining overtime, satisfaction, absenteeism, commute distance and promotion history — lifts churn from 20.28% to only 22.0% in its top 100. Most of the employees it flags as highest-risk had not left. This is the practical bottom line: the data currently collected does not explain who leaves.
    

### 📌 Recommendations

#### For the Head of People — proposed interventions

1. **Investigate the low-hours group, not the overtime group.** This inverts the standard assumption and is the one finding the data actually supports. Cross-reference employees under 180h/month with recent project allocation and manager one-to-ones to determine whether low utilisation reflects disengagement, under-assignment, or exclusion from work.
    
2. **Stop allocating retention budget by department.** No department, role, tenure band or hire cohort shows elevated churn. Interventions should be designed company-wide or targeted on individual behavioural signals, not on org-chart segments.
    
3. **On the three interventions under consideration — flex time, raises, promotion paths — the data supports none of them as a churn remedy.** Overtime shows no effect on churn, underpaid employees churn _below_ baseline, and promotion status barely moves it. This does not mean the interventions are worthless; the pay and promotion problems below are real. It means they should be justified as **fairness and retention-of-key-talent measures**, not sold to the board as churn fixes on evidence this data does not provide.
    
4. **Review the satisfaction survey instrument.** Satisfaction averages 49–50% across every workload band and shows no relationship to churn. A metric this flat is either poorly designed or not being answered honestly, and should be re-examined before it informs further decisions.
    

#### For the Compensation team — is pay fair by role and tenure?

5. **The answer is no, on both counts, and the problem is structural.** All four job roles draw from an identical 30k–150k salary range with average salaries within 1.5% of each other, so there is **no functioning salary band structure**. Pay is also uncorrelated with performance — low performers average marginally _more_ than top performers.
    
6. **Audit and remediate the underpaid population.** 30.9% of employees sit more than 25% below their role average. Start remediation with those 3,090, prioritising performance ratings of 4–5 — this is the group where the fairness gap and the risk of losing key talent overlap. Note that this is a **fairness and legal-exposure issue, not a churn issue**: the severely underpaid group churns at 19.35%, below baseline.
    
7. **Connect manager feedback to promotion decisions, or stop collecting it.** A review process that produces a 0.28pp difference in promotion rate is consuming manager time without informing any decision. Either make feedback a formal input to promotion, or replace it with something that is.
    

#### For Engineering managers — which teams are at risk?

8. **No team stands out as more at risk than any other.** Churn falls within a 0.54pp band across all four departments and a 1.67pp band across all four job roles. Ranking teams by attrition risk isn't supportable from this data — any such ranking would mostly reflect random variation.
    
9. **The individual risk score is not yet fit for deployment.** It should not drive staffing or retention decisions about named engineers: 78 of the 100 employees it flags as highest-risk had not left. Acting on it would mean approaching mostly the wrong people, and would damage trust with everyone it flags.
    

#### Cross-cutting prerequisite

10. **Fix the data before attempting prediction.** The current variables explain almost nothing about who leaves. Before investing in a churn model, instrument the process to capture: **exit interview reasons**, **time since last salary increase**, **internal mobility and role changes**, **manager change history**, and **timestamped engagement survey responses**. A model built on the present dataset would not outperform the base rate.

### ⚠️ Limitations

- **This is a practice dataset from Xóm Dataset**, and several patterns suggest the data is generated rather than observed: churn sits near 20% in almost every segment, all four job roles span an identical salary range, and average absenteeism differs by only 0.06 days across departments. Findings should be read as an analytical exercise, not as evidence about a real workforce.
- **No formal significance testing was performed.** Conclusions about which differences are large enough to act on are based on comparing the size of each gap against the 20.28% baseline and the number of employees in each group. Confirming the hours-worked pattern in Q8 would call for a proper hypothesis test.
- **`churn` has no timestamp**, so all analysis is cross-sectional. Attrition cannot be attributed to any point in time and no survival analysis is possible.
- **No hire date field**, so the Q14 cohort analysis is derived from tenure and is not an independent view.
- **`promotions` is a binary flag**, not a count, so promotion frequency and velocity cannot be analysed.
