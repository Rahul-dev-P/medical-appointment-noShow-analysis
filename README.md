# Healthcare Appointment No-Show Analytics Dashboard

---

## Project Overview
This project analyzes 110,521 medical appointments to identify the factors contributing to patient no-shows. Using SQL for data preparation and Power BI for interactive visualization, the dashboard highlights appointment trends, patient demographics, lead time effects, geographic patterns, and a custom risk-tier framework to support operational decision-making.

---

## Objectives

- Analyze appointment attendance patterns
- Identify key drivers of patient no-shows
- Develop a patient risk-tier framework
- Build an interactive Power BI dashboard
- Provide actionable operational insights

---

## Dataset

- Source: Medical Appointment No Shows Dataset
- Total Appointments: 110,521
- Link : https://www.kaggle.com/datasets/joniarroba/noshowappointments/data

---

## Tech Stack

- SQL (MySQL)
- Power BI
- DAX

---

## Dataset Overview & Data Cleaning Workflow

### Primary Tables & Views
1. **`KaggleV2-May-2016-ascii`**: Raw dataset from Kaggle
2.  **`appointments`**: Cleaned baseline dataset containing patient demographic attributes, clinical conditions, booking dates, and attendance outcomes.
3. **`v_appointment_risk`**: A custom analytical SQL view built with window functions to track patient historical attendance and bucket appointments into actionable risk tiers.

### Data Cleaning & Transformation Pipeline
- **Column Standardization**: Cleaned key field names (`Hipertension` $
ightarrow$ `hypertension`, `Handcap` $
ightarrow$ `disability_count`, `No-show` $
ightarrow$ `no_show`).
- **Date/Time Formatting**: Parsed ISO strings (`ScheduledDay`, `AppointmentDay`) into proper SQL `DATETIME` and `DATE` objects using `STR_TO_DATE`.
- **Data Integrity Filtering**: Deleted invalid records containing negative ages (`Age = -1`) and impossible booking windows (`lead_time_days < 0`).
- **Feature Engineering**: Engineered `lead_time_days` as `DATEDIFF(AppointmentDay, DATE(ScheduledDay))` and computed rolling prior attendance ratios per patient.

---

## Key Exploratory Data Analysis (EDA) Findings

### 1. Lead Time Analysis (Booking-to-Appointment Gap)
Lead time emerged as the single strongest driver of patient no-shows.

| Lead Time Bucket | Lead Time Range | Total Appointments | No-Show Count | No-Show Rate (%) |
| :--- | :--- | :---: | :---: | :---: |
| **Same Day** | 0 Days | 38,562 | 1,793 | **4.65%** |
| **Short** | 1–3 Days | 14,675 | 3,359 | **22.89%** |
| **Within a Week** | 4–7 Days | 17,510 | 4,413 | **25.20%** |
| **Long Lead** | 8+ Days | 39,774 | 12,749 | **32.06%** |

> **Key Insight**: Appointments booked for the same day have a **95.35%** completion rate. When lead time extends past 8 days, the no-show rate rises to **32.06%** (nearly 1 in 3 patients).

### 2. Demographic & Socioeconomic Patterns

#### Age Group Stratification
- **Teens (13–19)**: Highest non-attendance rate at **25.95%** (9,374 appts).
- **Young Adults (20–39)**: Second highest non-attendance rate at **23.13%** (28,868 appts).
- **Children (0–12)**: **20.47%** no-show rate (21,035 appts).
- **Adults (40–59)**: **18.81%** no-show rate (30,072 appts).
- **Seniors (60+)**: Most reliable group with a **15.31%** no-show rate (21,172 appts).

#### Welfare Assistance (`Scholarship`)
- **Scholarship Recipients (`1`)**: **23.74%** no-show rate (10,861 appts).
- **Non-Recipients (`0`)**: **19.80%** no-show rate (99,660 appts).
- *Implication*: Welfare recipients show a ~4 percentage point higher no-show rate, indicating possible structural barriers such as transit availability or hourly job constraints.

---

### 3. The SMS Reminders Paradox

| SMS Status | Total Appointments | No-Show Rate (%) |
| :--- | :---: | :---: |
| **Received SMS (`1`)** | 35,482 | **27.57%** |
| **No SMS (`0`)** | 75,039 | **16.70%** |

> **Root Cause Analysis**: SMS notifications are primarily dispatched for longer lead-time appointments ($\ge 3$ days), which inherently carry high baseline non-attendance risk. Simple unidirectional SMS reminders without confirmation links are insufficient to offset long-lead drop-off.

| Lead time bucket | Total Appointments | SMS Sent Count | SMS Reception Rate % |
| :--- | :---: | :---: | :--: |
| **Same Day**  | 38,562 | 0 | **0.00** |
| **Short** | 16,675 | 906 | **6.17** |
| **Within a Week** | 17,510 | 10,642 | **60.78** |
| **Long Lead** | 39,774 | 23,934 | **60.17** |

---

### 4. Day of the Week Performance

| Day | Total Appointments | No-Shows | No-Show Rate (%) |
| :--- | :---: | :---: | :---: |
| **Saturday** | 39 | 9 | **23.08%** |
| **Friday** | 19,019 | 4,037 | **21.23%** |
| **Monday** | 22,713 | 4,689 | **20.64%** |
| **Tuesday** | 25,638 | 5,150 | **20.09%** |
| **Wednesday** | 25,866 | 5,092 | **19.69%** |
| **Thursday** | 17,246 | 3,337 | **19.35%** |

---

### 5. High-Risk Neighborhood Analysis
Neighborhoods with $\ge 100$ total appointments exhibiting the highest no-show rates:

1. **SANTOS DUMONT**: **28.92%** (1,276 appts)
2. **SANTA CECILIA**: **27.46%** (448 appts)
3. **SANTA CLARA**: **26.48%** (506 appts)
4. **ITARARE**: **26.27%** (3,514 appts)
5. **JESUS DE NAZARETH**: **24.40%** (2,853 appts)

---

### 6. Clinical Conditions & Comorbidities
- Baseline patients without Hypertension, Diabetes, or Alcoholism: **20.90%** no-show rate.
- Patients with **Alcoholism alone**: **21.46%** no-show rate.
- Patients with **Hypertension alone**: **17.08%** no-show rate.
- Patients managing multiple chronic conditions demonstrate overall higher attendance consistency.

---

## Patient Risk Stratification Framework

To operationalize these insights, the SQL view `v_appointment_risk` uses window functions (`COUNT(*) OVER` and `SUM(...) OVER`) to construct historical tracking features per patient (`prior_appointments`, `prior_no_shows`) and assign a `risk_tier`.

### Model Evaluation & Validation

| Risk Tier | Criteria / Logic | Total Appts | Percentage | Actual No-Shows | Actual No-Show Rate |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **High Risk** | `prior_no_show_rate >= 50%` OR `lead_time_days >= 8` | 22,187 | 20.07% | 6,941 | **31.28%** |
| **Medium Risk** | `prior_no_show_rate >= 20%` OR `lead_time_days BETWEEN 4 AND 7` | 8,870 | 8.03% | 1,922 | **21.67%** |
| **New Patient** | `prior_appointments = 0` | 62,298 | 56.37% | 11,959 | **19.20%** |
| **Low Risk** | Established attendance history & low lead time | 17,166 | 15.53% | 1,492 | **8.69%** |

> **Model Performance**: The framework isolates high-risk bookings, achieving a **31.28%** no-show rate in the High Risk tier—over **3.6x higher** than the Low Risk tier (**8.69%**).

---

## Strategic & Operational Recommendations

1. **Interactive Two-Way Confirmations**:
   - Upgrade SMS reminders for appointments with lead times $\ge 4$ days to interactive systems requiring binary confirmation (`REPLY 1 to CONFIRM / 2 to CANCEL`). Auto-release unconfirmed slots 48 hours prior.
2. **Targeted Engagement for Young Demographics**:
   - Implement push notifications and automated calendar invites for patients aged 13–39, who show the highest default rate (~23%–26%).
3. **Smart Overbooking & Buffer Scheduling**:
   - Use the `High Risk` classification tag in scheduling systems to allow double-booking or overbooking buffers specifically in high-risk neighborhoods (e.g., SANTOS DUMONT, ITARARE).
4. **Targeted Transportation Support**:
   - Partner with local transit programs or community health workers for patients on welfare scholarships to mitigate socioeconomic access barriers.

---

## Dashboard Overview

(images/dashboard.png)

---

## Repository Structure

```text
├── sql/
│   ├── wrangling.sql
│   ├── eda.sql
├── dashboard.pbix
├── README.md
└── INSIGHTS.md
```
