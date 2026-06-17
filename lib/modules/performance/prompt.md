Below is your **ready-to-use `prompt.md`** file.

You can copy this directly into your project root or into VS Code and use it with your agentic AI.

It is strictly scoped so the AI **ONLY modifies your `performance/` folder** and does not touch anything else.

---

# 📄 `prompt.md`

````md
# 🧠 Agentic AI Instruction: Teacher Performance KPI Module

## 🚨 STRICT SCOPE RULE
You are ONLY allowed to modify files inside:

performance/
│── model/
│── providers/
│── screen/
│── services/

❌ DO NOT modify any other folders (auth, firebase setup, main app, routing, etc.)
❌ DO NOT change global theme, navigation, or unrelated modules
❌ DO NOT refactor outside this module
✔ ONLY implement, fix, or enhance PERFORMANCE MODULE functionality

---

# 🎯 MODULE OBJECTIVE
You are implementing a **Teacher Performance KPI System** using Flutter + Firebase Firestore.

This module handles:
- Teacher performance scoring
- KPI calculation logic
- Performance logs (merit & deduction)
- Yearly KPI aggregation
- Notifications & warnings
- Principal evaluation controls
- Teacher KPI dashboard views

---

# 🧱 FIREBASE COLLECTION STRUCTURE

## 1. teachers
Stores teacher profile + performance score.

```typescript
TeacherRecord {
  id: string;
  username: string;
  email: string;
  fullName: string;
  role: "teacher" | "principal";
  icNumber: string;
  gender: string;
  dob: string;
  address: string;
  phoneNumber: string;
  maritalStatus: string;

  emergencyContactName: string;
  emergencyContactNumber: string;

  documents: {
    myKad: object;
    passportPhoto: object;
    resume: object;
    academicCertificates: object;
    medicalReport: object;
    bankStatement: object;
  };

  completionProgress: number;
  currentScore: number;
  yearlyKpi: number;
}
````

---

## 2. performance_logs

Stores merit/deduction actions.

```typescript
PerformanceLog {
  id: string;
  teacherId: string;
  principalId: string;
  amount: number;
  reason: string;
  timestamp: timestamp;
  category: string;
  criterion: string;
  severity: "Minor" | "Normal" | "Major" | "Critical";
}
```

---

## 3. yearly_kpis

```typescript
YearlyKpiRecord {
  id: string;
  teacherId: string;
  year: number;
  averageMonthlyScore: number;
  trendFactor: number;
  finalScore: number;
  rating: "A" | "B" | "C" | "D" | "E";
  status: "Pending" | "Reviewed" | "Adjusted";
  notes: string;
  timestamp: timestamp;
}
```

---

## 4. notifications

System alerts (auto-generated).

## 5. warnings

Institutional warning records.

---

# 📊 PERFORMANCE SCORING RULES

## Merit (Positive)

* Minor → +1
* Normal → +1
* Major → +2
* Critical → +3

## Deduction (Negative)

* Minor → -1
* Normal → -2
* Major → -3
* Critical → -5

---

# 🚨 AUTOMATION RULES

## 1. Daily Safety Threshold

If deductions exceed -30 per day:
→ Show warning modal in admin UI

---

## 2. Critical Alert

If severity == "Critical" AND deduction:
→ Create notification:
"CRITICAL ALERT: {Teacher Name}"

---

## 3. Score Threshold Alert

If teacher currentScore < -30:
→ Trigger warning:
"Score Threshold Alert: {Teacher Name}"

---

# 📈 KPI CALCULATION LOGIC

Implement centralized calculation inside services/performance_service.dart:

### Steps:

1. Fetch all performance_logs for teacher + year

2. Group by month

3. Compute monthly totals

4. Compute yearly average

5. Trend factor:

   * improving → 1.1
   * stable → 1.0
   * declining → 0.9

6. Final Score:
   averageMonthlyScore × trendFactor

7. Rating:

* A ≥ 85
* B ≥ 70
* C ≥ 55
* D ≥ 40
* E < 40

---

# 👨‍🏫 ADMIN WORKFLOW (PRINCIPAL)

## Must implement in provider/service:

### 1. Add Performance Log

* Select teacher
* Select category + criterion
* Select severity
* Choose + or -
* Save to Firestore

Auto update:

* teachers.currentScore
* notifications
* warnings (if needed)

---

### 2. Run Yearly KPI Calculation

* Iterate all teachers
* Compute KPI
* Save to yearly_kpis
* Set status = "Pending"

---

### 3. Audit Logs

* View performance history
* Filter by teacher
* Filter by severity

---

# 👩‍🏫 TEACHER WORKFLOW

## KPI Screen must support:

### 1. View current score

### 2. View performance logs

### 3. View notifications

### 4. View warnings

### 5. View yearly KPI (read-only)

---

# 📱 FILE RESPONSIBILITIES

## model/performance.dart

* Define all Firestore models
* Include fromJson / toJson

---

## providers/performance_provider.dart

* State management
* Teacher KPI state
* Loading / error states
* Notify listeners

---

## services/performance_service.dart

MUST contain:

* addPerformanceLog()
* fetchTeacherLogs()
* calculateMonthlyScores()
* calculateYearlyKPI()
* runAllKPIForYear()
* updateTeacherScore()
* triggerNotifications()
* triggerWarnings()

---

## screen/performance_screen.dart

* Admin interface
* Add/edit performance logs
* View logs list

---

## screen/kpi_screen.dart

* Teacher KPI dashboard
* Score overview
* Chart display
* Notifications panel
* Read-only yearly KPI view

---

# ⚠️ UI REQUIREMENTS

* Use clean KPI dashboard UI

* Use color indicators:

  * Green → improving
  * Yellow → stable
  * Red → declining

* Use charts for KPI trends (fl_chart allowed)

---

# ❌ STRICT LIMITATIONS

* DO NOT modify Firebase initialization
* DO NOT touch authentication system
* DO NOT modify routing or main.dart
* DO NOT create new modules outside performance/

---

# 🎯 FINAL GOAL

A fully functional KPI system where:

* Principal can evaluate teachers
* System auto-calculates KPI
* Teachers can view performance in real time
* Yearly KPI is centrally computed and stored
* Notifications & warnings are automated

```

---

