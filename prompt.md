```markdown
# 🧑‍💻 AI Agent Prompt — Flutter Duty Module (STRICT SCOPE)

You are working inside an existing Flutter project.

## 🚫 STRICT RULE

Only modify or create files inside:

```

/lib/modules/duty/

```

Do NOT modify any other directory in the project.

You must build a complete **Duty Management Module** using ONLY the existing module structure.

---

## 📁 FILES YOU MUST USE

- `/duty/models/duty.dart`
- `/duty/providers/duty_provider.dart`
- `/duty/services/duty_service.dart`
- `/duty/screens/duty_schedule_screen.dart`

You may refactor and extend these files, but must NOT create or modify files outside `/lib/modules/duty/`.

---

# 🎯 GOAL

Build a **School Duty Management System** with:

- Google Calendar-style schedule view
- List view (role-based)
- Task tracking with photo proof
- Duty swapping system
- Role-based permissions (Teacher vs Principal)
- Duty scheduling engine

---

# 👥 USER ROLES

## 👩‍🏫 Teacher
- View all duty schedules (calendar view)
- Only see own duties in list view
- Complete assigned tasks via camera photo
- Can initiate swap requests (own duties only)

## 👨‍💼 Principal
- Full access to all duties
- Create / edit / delete duties
- Add locations
- Assign teachers
- Approve or bypass swaps
- Filter duties by teacher or venue

---

# 📅 CALENDAR VIEW (DEFAULT SCREEN)

Implement a **scrollable grid calendar (Google Calendar style)**.

## Layout

### Axis Structure:
- LEFT: TIME slots (vertical axis)
- TOP: Locations OR Teachers (toggle mode)

## Toggle Modes:

### Mode 1: Location View
- Columns = locations
- Block color = teacher

### Mode 2: Teacher View
- Columns = teachers
- Block color = location

---

## Duty Block UI

Each block must show:
- Task name
- Teacher in charge
- Location

### Interactions:
- Tap → Duty detail view
- Principal only:
  - Pencil icon → edit duty
  - Add location button (only in location mode)

---

## Floating Action Button (FAB)

- Visible only to Principal
- Used to create new duty

---

## Date Navigation

At top:
- Date selector
- Range: **-10 days to +10 days**

---

# 📋 LIST VIEW (TOGGLE BUTTON TOP RIGHT)

Switch between Calendar ↔ List view

## Teacher View:
- Only show own duties

## Principal View:
- Show all duties

## Layout:

Split into:
- TODO
- COMPLETED

Each item shows:
- Duty name
- Time
- Location
- Teacher in charge
- Expand arrow (>) → shows tasks

---

# 📸 TASK COMPLETION SYSTEM

Each duty contains multiple tasks.

## Completion Rules:
- Must take photo using camera
- Photo becomes task thumbnail
- Last completed task becomes duty thumbnail
- Duty is complete when all tasks are done

## Time Constraint:
Task can only be completed:
- 1 hour before scheduled time
- 1 hour after scheduled time

---

# 📋 DUTY DETAIL SCREEN (VIEW FIRST BEFORE EDIT)

Before editing, user must see:

- Duty name
- Time range
- Locations
- Assigned teachers per location
- Task list
- Completion status per teacher

---

# ✏️ DUTY EDITING (PRINCIPAL ONLY)

Accessible from:
- Calendar block
- List item pencil icon

## Editable Fields:
- Duty name
- Time (all-day or range)
- Multiple locations
- Minimum teachers per venue
- Task list
- Teacher assignments

## Location Picker:
- Multi-select
- Add new location allowed

---

# 🔄 SWAP SYSTEM

## FIX SWAP LOGIC

Replace incorrect logic with:

```

A.start <= B.start AND A.end >= B.end

```

## Rules:
- Swap allowed only if requested ≤ 1 hour before duty start
- Teacher can only swap own duties
- Principal can swap any duty

## Swap Flow:
- Show eligible teachers list
- Show duty + venue + time
- Request swap → notification created

---

## Notifications:

### Teacher initiated:
- Requires approval from target teacher

### Principal initiated:
- Auto-approved for both parties

---

# 🧠 SCHEDULING ENGINE

Auto-assign duties based on:
- Teacher status = active
- Not on leave
- Not in training

---

# 🧾 DUTY TYPES (SUPPORT STRUCTURE)

Support recurring templates:

- Cleaning Duty (daily)
- Arrival Duty (daily)
- Dismissal Duty (daily)
- Transition Duty (daily)
- Assembly Duty (weekly/monthly)

Include checklist support.

---

# 🎨 COLOR RULES

- Location view → color by teacher
- Teacher view → color by location

Maintain consistent mapping per entity.

---

# 📊 DATA MODELS

## Duty:
- id
- title
- date
- time range
- locations (list)
- teachers assigned
- tasks
- completion state
- thumbnails
- swap state
- status

## Task:
- name
- completed
- photoUrl
- timestamp
- teacher
- location

---

# 🔧 SERVICE LAYER (DutyService)

Must implement:
- fetch duties by date
- fetch by teacher
- create duty
- update duty
- delete duty
- assign teachers
- swap request handling
- task completion update
- scheduling logic

---

# 🧠 PROVIDER (DutyProvider)

Must manage:
- selected date
- view mode (calendar/list)
- grouping mode (teacher/location)
- user role
- duty state
- loading/error states
- swap state

---

# 📱 SCREEN (DutyScheduleScreen)

Must include:
- Top bar:
  - date navigation
  - toggle view
  - filter (principal only)

- Body:
  - Calendar grid OR list view

- FAB:
  - Principal only → add duty

- Interactions:
  - block → view duty
  - edit → edit duty
  - task → camera capture

---

# ⚠️ CONSTRAINTS

- ONLY modify `/lib/modules/duty`
- No external architectural changes
- Provider-based state management only
- Must support scroll both horizontal + vertical in calendar
- Must be null-safe Flutter code

---

# ✅ OUTPUT REQUIREMENT

Generate a fully working module with:

- Calendar grid UI
- List view UI
- Role-based permissions
- Duty CRUD system
- Task completion with camera
- Swap system
- Scheduling engine
- Clean architecture inside module only
```
# ☁️ Cloudinary Integration Requirement (Duty Module)

The project uses Cloudinary for image uploads. This must be integrated inside the `/lib/modules/duty` module only.

---

## 🔐 Environment Variables (DO NOT MODIFY)

These already exist in the root `.env` file:

```

CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
CLOUDINARY_UPLOAD_PRESET

````

---

## 📸 TASK COMPLETION IMAGE FLOW

When a teacher completes a task:

1. Open device camera
2. Capture image
3. Upload image to Cloudinary
4. Store returned `secure_url` as task proof

---

## 📦 STORAGE RULES

Each Task must include:

```dart
String? photoUrl;      // Cloudinary image URL
DateTime? completedAt; // completion timestamp
bool isCompleted;
````

Each Duty must include:

```dart
String? thumbnailUrl; // last completed task image
```

---

## 🔧 IMPLEMENTATION LOCATION

All Cloudinary-related logic must be implemented inside:

```
/lib/modules/duty/services/duty_service.dart
```

or helper files inside:

```
/lib/modules/duty/services/
```

---

## ☁️ UPLOAD IMPLEMENTATION RULES

* Use Cloudinary HTTP upload API
* Use `upload_preset` authentication (no server-side signing required on client)
* Upload using multipart/form-data
* Return and store `secure_url`

---

## ⚠️ CONSTRAINTS

* Do NOT modify `.env`
* Do NOT hardcode any API keys
* Do NOT introduce backend dependency
* Must work fully client-side
* Must handle upload failure gracefully

```
```

