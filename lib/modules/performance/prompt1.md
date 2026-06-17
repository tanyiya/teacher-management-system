# 🧠 Agentic AI Instruction: FULL FIX Teacher Performance KPI Module

## 🚨 ABSOLUTE SCOPE RULE
You are ONLY allowed to modify:

performance/
│── model/
│── providers/
│── screen/
│── services/

❌ DO NOT modify:
- authentication system
- main.dart
- routing/navigation outside module
- firebase initialization
- other unrelated features

✔ ONLY FIX AND COMPLETE PERFORMANCE MODULE

---

# 🚨 CRITICAL PROBLEMS TO FIX

## ❌ ISSUE 1: Teacher KPI shows SAME score every day
### Problem:
- All teachers show identical KPI values
- No performance logs are displayed
- No variation per teacher

### REQUIRED FIX:
✔ Ensure each teacher has UNIQUE performance_logs
✔ KPI must be computed per teacherId
✔ Prevent shared/global state bugs

### MUST DO:
- Check provider state isolation
- Ensure Firestore queries are filtered by teacherId
- Add dummy data generator for testing

---

## ❌ ISSUE 2: Admin dropdown not working
### Problem:
- Dropdown shows only 1 teacher OR not selectable
- Cannot select different teachers

### REQUIRED FIX:
✔ Replace broken dropdown with functional StreamBuilder OR FutureBuilder
✔ Fetch ALL teachers from Firestore collection "teachers"
✔ Ensure selection updates state correctly

### MUST IMPLEMENT:
- Teacher list fetch function
- Proper dropdown state management
- onChanged must update selectedTeacherId
- UI must reflect selection instantly

---

## ❌ ISSUE 3: KPI Admin Screen overflow (37px right overflow)
### Problem:
- UI not responsive
- Overflow on mobile screen

### REQUIRED FIX:
✔ Make entire screen responsive

### MUST IMPLEMENT:
- Wrap content in SingleChildScrollView
- Use Expanded/Flexible properly
- Replace Row overflow with Wrap OR scrollable horizontal list
- Ensure no fixed width containers

---

## ❌ ISSUE 4: Admin functions NOT working (CRITICAL)
### Problem:
- No real functionality exists
- Buttons do nothing
- No KPI calculation
- No performance viewing

### REQUIRED FIX:
YOU MUST FULLY IMPLEMENT ADMIN FEATURES:

---

# 👨‍💼 ADMIN FEATURES (MUST IMPLEMENT FULLY)

## 1. Add Performance Log (FUNCTIONAL)
Implement:

- Select teacher
- Select category
- Select criterion
- Select severity
- Choose (+ Merit / - Deduction)
- Save to Firestore

### MUST ALSO:
- Update teachers.currentScore instantly
- Trigger notifications if needed
- Write to performance_logs collection

---

## 2. View Teacher Performance Logs (NEW FEATURE)
Admin must be able to:

✔ Select teacher
✔ View list of performance_logs
✔ Filter by:
   - category
   - severity
   - date range

---

## 3. Run Yearly KPI Calculation (CRITICAL FEATURE)

Implement FULL FUNCTION:

### MUST DO:
- Fetch ALL teachers
- Fetch ALL logs per teacher
- Group logs by month
- Compute monthly score
- Compute yearly average
- Apply trend factor:
  - improving → 1.1
  - stable → 1.0
  - declining → 0.9

- Save into:
  yearly_kpis collection

- Set status = "Pending"

---

## 4. View Overall KPI Dashboard (NEW REQUIRED SCREEN LOGIC)

Admin must see:

- List of all teachers
- Current score
- KPI rating
- Trend indicator (↑ ↓ →)
- Tap to view details

---

## 5. Fix Teacher Dropdown (MANDATORY)

Replace broken dropdown with:

✔ Live Firestore stream
✔ Multi-teacher selection support
✔ Correct state update

---

# 👩‍🏫 TEACHER SIDE FIXES

## ISSUE: No performance logs visible

### REQUIRED FIX:
✔ Teacher screen must fetch:

performance_logs WHERE teacherId == currentUserId

### MUST SHOW:
- list of logs
- timestamp
- category
- severity
- score change

---

## ISSUE: KPI always same

### REQUIRED FIX:
✔ Ensure teacher KPI screen:
- reads from Firestore
- NOT hardcoded state
- updates per teacherId

---

# 🧪 DUMMY DATA GENERATOR (MANDATORY)

IF Firestore is empty:

CREATE function in service:

seedDummyPerformanceData()

### MUST GENERATE:
For each teacher:
- 10–30 random performance_logs
- mix of:
  - merit (+1 to +3)
  - deduction (-1 to -5)
- spread across multiple months

---

# 📊 UI FIX REQUIREMENTS

## Admin KPI Screen:
✔ Must be fully scrollable
✔ No overflow allowed
✔ Use:
- SingleChildScrollView
- ListView
- Wrap instead of Row when needed

---

## KPI Cards:
✔ responsive width
✔ no fixed pixel layout
✔ mobile-friendly spacing

---

# ⚙️ SERVICE LAYER REQUIREMENTS

performance_service.dart MUST INCLUDE:

- fetchAllTeachers()
- fetchTeacherLogs(teacherId)
- addPerformanceLog()
- updateTeacherScore()
- calculateMonthlyScore()
- calculateYearlyKPI()
- runFullKPIComputation()
- seedDummyPerformanceData()
- getTeacherKPIDetails()

---

# 🧠 PROVIDER REQUIREMENTS

performance_provider.dart MUST:

✔ manage selectedTeacherId
✔ manage loading states
✔ manage teacher list stream
✔ notify UI updates correctly
✔ isolate state per teacher

---

# 🔥 FIREBASE RULE

ALL operations MUST be based on:

✔ teacherId filtering
✔ no global shared KPI state
✔ real-time Firestore sync

---

# 🚨 FINAL ACCEPTANCE CRITERIA

System is ONLY correct if:

✔ Admin can select ANY teacher
✔ Admin can add performance logs successfully
✔ Admin can run yearly KPI calculation
✔ Teachers see unique KPI values
✔ Teachers see their own logs
✔ No UI overflow on any screen
✔ Dummy data works if database is empty
✔ No frozen or static data exists

---

# 🎯 FINAL GOAL

A fully working KPI system where:

- Principal manages performance dynamically
- Teachers have individual KPI tracking
- All data is stored in Firestore
- System is responsive and production-ready
- No UI bugs or static placeholders