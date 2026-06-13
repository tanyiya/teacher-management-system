# System Specification & Context Teacher Management System (FlutterDart Migration)

This document is a comprehensive architectural, functional, and structural blueprint of the Teacher Management System (School Staff Management Portal). It is written to serve as the absolute single source of truth for rewriting the entire application in Flutter (Dart) while preserving every user experience path, custom workflow, visual aesthetic, and database behavior of the original system.

---

## 1. Executive Summary & Persona Architecture

The application is a full-stack administrative ecosystem designed for educational institutions to coordinate staff, evaluate monthly teaching performance, manage daily campus duties (arrival, cleanup, transitions, assembly), administer leave approvals, track facility complaints, and engage staff through a professional LinkedIn-style training network (formerly Reporting, now Training). 

The application is structured around a single login gateway supporting two distinct workflows with role-based access control

### A. The Principal Workflow (Administrator  Supervisor)
   Role Scope High-level system configuration, visual audit tracking, roster management, performance tracking, dynamic disciplinary interventions, leave administration, incident triaging, and CPD course orchestration.
   Key Needs Fast actionability on leaves and performance penalties, direct overview of daily campus duty checklists, and real-time review of professional training applications.
   Core Personality Active coordinator, observer, authoritative decision-maker.

### B. The Teacher Workflow (Frontline Staff)
   Role Scope Individual agenda monitoring, daily duty completion with real-time photographic proof submission, professional leafsick application, direct facility issue reporting, professional training participation, and personal administrative profile maintenance.
   Key Needs Highly intuitive interfaces for quick checklists, easy form filing, transparent grading insight, and direct professional development opportunities within a simple feed.
   Core Personality Task-oriented, collaborator, active career developer.

---

## 2. Technical Stack & State Operations

To migrate the existing React + ESM + CJS codebase to a native or responsive Flutter workspace, the selected platform libraries and services must directly map the active web dependencies

 Original ReactVite Asset  Target FlutterDart Dependency  Purpose & Mapping 
 ---  ---  --- 
 react  react-dom  flutter (SDK)  Core responsive UI rendering with CupertinoMaterial layers 
 firebaseapp & firestore  `firebase_core` & `cloud_firestore`  Real-time database synchronizations & document listeners 
 motionreact (AnimatePresence)  `flutter_animate` or standard `PageRouteBuilder`  Transitions, custom slide and fade presets on role change 
 recharts  `fl_chart` or `syncfusion_flutter_charts`  KPI Performance and monthly trend evaluation graphics 
 jspdf  jspdf-autotable  `pdf` & `printing`  Printable executive PDF performance reports 
 lucide-react  `lucide_icons` or customized SVG assets  UI-wide indicator icons and visual accents 
 Browser File Readers  `image_picker`  `file_picker`  Camera capture & document upload simulation 

---

## 3. Database Schemata (Firestore Implementation)

The Firestore collections must support the exact properties mapped out in `srctypes.ts`. All documents are stored in a flat collection hierarchy utilizing real-time collection listeners (`onSnapshot`  `StreamStream`).

### I. Collection `teachers`
   Document ID Authentic `teacher_id` or auto-generated string.
   Variables
       `username` (`String`) unique login identifier.
       `email` (`String`) administrative contact address.
       `fullName` (`String`) legal display name of faculty member.
       `role` (`String`) `'teacher'` or `'principal'`.
       `icNumber` (`String`) Identity Card Number.
       `gender` (`String`) `'Male'`, `'Female'`, or `'Other'`.
       `dob` (`String`) Date of birth (`YYYY-MM-DD`).
       `address` (`String`) permanent physical residence.
       `phoneNumber` (`String`) contact number.
       `maritalStatus` (`String`) `'Single'`, `'Married'`, `'Divorced'`, `'Widowed'`.
       `emergencyContactName` (`String`) emergency point of contact.
       `emergencyContactNumber` (`String`) emergency relative's contact number.
       `completionProgress` (`Int`) calculated dynamically or cached (0 to 100).
       `currentScore` (`Int`) active points balance in current grading month (usually seeded at 60-90, fluctuates based on logs).
       `yearlyKpi` (`Int`) cumulative performance score index.
       `status` (`String`) `'active'` or `'terminated'`.
       `documents` (`Map`)
        ```json
        {
          myKad { id myKad, name Copy of Identification Card (MyKad), type imagepdf, status emptyuploadedverified, url String },
          passportPhoto { id passportPhoto, name Passport Photo, type image, status emptyuploadedverified, url String },
          resume { id resume, name ResumeCV, type pdf, status emptyuploadedverified, url String },
          academicCertificates { id academicCertificates, name Latest Academic Certificates, type imagepdf, status emptyuploadedverified, url String },
          medicalReport { id medicalReport, name Medical Check Up Report, type imagepdf, status emptyuploadedverified, url String },
          bankStatement { id bankStatement, name Header of Bank Statement, type imagepdf, status emptyuploadedverified, url String }
        }
        ```

### II. Collection `duty_locations`
   Document ID Location identifier (e.g. `'assembly-hall'`).
   Variables
       `name` (`String`) Display name (e.g. `'Assembly Hall'`).
       `description` (`String`) Short location coordinates text.

### III. Collection `duty_tasks`
   Document ID Auto-generated string.
   Variables
       `name` (`String`) Duty identifier (e.g., `'Arrival Main Door'`).
       `timeStart` (`String`) HHmm formatted starting trigger (e.g., `'0730'`).
       `timeEnd` (`String`) HHmm formatted ending mark (e.g., `'0800'`).
       `frequency` (`String`) `'Daily'`, `'Weekly'`, or `'Monthly'`.
       `locations` (`ListString`) Array of registered `duty_location` database IDs.
       `minPeople` (`Int`) minimal assigned teachers requirement (e.g., `1` or `2`).
       `checklistTemplates` (`ListString`) predefined bullet templates for actions (e.g., `['Greet students', 'Verify ID']`).
       `genderRequirement` (`String`) `'Male'`, `'Female'`, or `null`.
       `dayOfWeek` (`Int`) `0-6` for Weekly duties (1=Monday... 0=Sunday).
       `dayOfMonth` (`Int`) `1-31` for Monthly duties.

### IV. Collection `duty_assignments`
   Document ID Auto-generated string.
   Variables
       `taskId` (`String`) parent `duty_task` reference ID.
       `taskName` (`String`) cached task name.
       `date` (`String`) assignment calendar date in `YYYY-MM-DD` standard.
       `locationId` (`String`) associated location document ID.
       `locationName` (`String`) cached location name.
       `teacherIds` (`ListString`) participating teacher IDs.
       `status` (`String`) `'pending'`, `'in-progress'`, or `'completed'`.
       `timeStart` (`String`) HHmm.
       `timeEnd` (`String`) HHmm.
       `isReplacement` (`Boolean`) defaults to `false`.
       `checklist` (`ListMap`)
        ```json
        [
          {
            id String,
            description String,
            isCompleted Boolean,
            photoUrl String,
            completedAt Timestamp
          }
        ]
        ```

### V. Collection `duty_swaps`
   Document ID Auto-generated.
   Variables
       `assignmentId` (`String`) target `duty_assignment` ID.
       `fromTeacherId` (`String`) requester teacher ID.
       `toTeacherId` (`String`) recipient teacher ID.
       `status` (`String`) `'pending'`, `'approved'`, or `'rejected'`.
       `timestamp` (`Timestamp`) submission speed logs.
       `requestedBy` (`String`) `'teacher'` or `'principal'`.

### VI. Collection `leaves`
   Document ID Auto-generated.
   Variables
       `teacherId` (`String`) applicant teacher ID.
       `teacherName` (`String`) applicant display name.
       `startDate` (`String`) `YYYY-MM-DD`.
       `endDate` (`String`) `YYYY-MM-DD`.
       `duration` (`Double`) decimal calculated length in days (e.g. `1.0`, `3.0`, `0.5`).
       `type` (`String`) `'annual'`, `'medical'`, `'unpaid'`, `'sick'`, `'emergency'`, etc.
       `status` (`String`) `'pending'`, `'approved'`, or `'rejected'`.
       `documentUrl` (`String`) attachment URL (sick certs, receipts).
       `documentName` (`String`) file display identifier.
       `remarks` (`String`) worker notes.
       `principalNotes` (`String`) admin review feedback words.
       `createdAt` (`Timestamp`) submission timestamp.

### VII. Collection `reports`
   Document ID Auto-generated.
   Variables
       `teacherId` (`String`) reporting staff ID.
       `teacherName` (`String`) reporter display name.
       `category` (`String`) complaint topic (e.g. `'Broken Furniture'`, `'Plumbing Leak'`).
       `description` (`String`) breakdown.
       `photoUrl` (`String`) attached problem photograph.
       `status` (`String`) `'Submitted'`, `'Under Review'`, `'Action Taken'`, or `'Resolved'`.
       `priority` (`String`) `'Low'`, `'Medium'`, or `'High'`.
       `managementNotes` (`String`) administrative triaging text.
       `createdAt` (`Timestamp`) reports date.
       `lastUpdated` (`Timestamp`) modification speed logs.

### VIII. Collection `training_posts`
   Document ID Auto-generated.
   Variables
       `authorId` (`String`) creator user document ID.
       `authorName` (`String`) creator name.
       `authorRole` (`String`) `'teacher'` or `'principal'`.
       `content` (`String`) post main text or description.
       `photoUrl` (`String`) accompanying visual evidencebanner.
       `likes` (`ListString`) user IDs who have favorited this document.
       `commentsCount` (`Int`) cached totals.
       `createdAt` (`Timestamp`) chronological sorting factor.
       `fontStyle` (`String`) `'sans'`, `'serif'`, `'mono'`, `'playful'`, or `'elegant'`.
       `isTraining` (`Boolean`) true if this is an administrative CPD Training post.
       `trainingTitle` (`String`) custom-built CPD label.
       `trainingDescription` (`String`) CPD outline summary.
       `maxTrainees` (`Int`) total seat capacities (e.g., `5` or `12`).
       `type` (`String`) `'volunteer'` (Open to apply) or `'assigned'` (Direct target).
       `traineeIds` (`ListString`) approved teacher IDs recorded for direct enrollment.

### IX. Collection `training_comments`
   Document ID Auto-generated.
   Variables
       `postId` (`String`) parent `training_posts` ID.
       `authorId` (`String`) comment author ID.
       `authorName` (`String`) name.
       `authorRole` (`String`) `'teacher'` or `'principal'`.
       `text` (`String`) message content.
       `createdAt` (`Timestamp`) datetime stamp.

### X. Collection `training_applications`
   Document ID Auto-generated.
   Variables
       `postId` (`String`) referential `training_post` ID.
       `trainingTitle` (`String`) title reference.
       `teacherId` (`String`) applicant teacher ID.
       `teacherName` (`String`) name of teacher.
       `status` (`String`) `'pending'`, `'approved'`, or `'rejected'`.
       `createdAt` (`Timestamp`) submission timestamp.

### XI. Collection `performance_logs`
   Document ID Auto-generated.
   Variables
       `teacherId` (`String`) subject teacher ID.
       `principalId` (`String`) evaluator administrator ID.
       `amount` (`Double`) scoring credit adjustments (e.g., `+10` or `-15`).
       `reason` (`String`) behavior text.
       `category` (`String`) active `PerformanceCategory` string.
       `criterion` (`String`) evaluation standard.
       `severity` (`String`) `'Minor'`, `'Normal'`, `'Major'`, `'Critical'`.
       `timestamp` (`Timestamp`) point adjustments recording time.

### XII. Collection `warnings`
   Document ID Auto-generated.
   Variables
       `teacherId` (`String`) teacher ID.
       `issuedBy` (`String`) admin label.
       `issueDate` (`Timestamp`) issue date.
       `message` (`String`) context note.
       `severity` (`String`) `'Verbal'`, `'Written'`, or `'Final'`.

### XIII. Collection `notifications`
   Document ID Auto-generated.
   Variables
       `userId` (`String`) target user's ID (or `'admin-id'` for administrators).
       `title` (`String`) short alert header.
       `message` (`String`) explicit readable guidelines.
       `read` (`Boolean`) unreadread state toggle.
       `timestamp` (`Timestamp`) transmission order indicator.
       `type` (`String`) `'performance'`, `'admin'`, `'leave'`, `'duty_swap'`, or `'report'`.

---

## 4. Key Business Logic & Computational Lifecycles

### A. Profile Completion Analytics (Dynamic Scale)
The profile completion progress (0-100%) is calculated dynamically based on 10 flat text parameters and 6 core corporate files. In Flutter, implement this via a reactive getter inside your state or entity models
   Total Checked Fields (16 items total weight)
    1.  `fullName` (Non-empty `String`)
    2.  `icNumber` (Non-empty `String`)
    3.  `gender` (Non-empty `String`)
    4.  `dob` (Non-empty `String`)
    5.  `address` (Non-empty `String`)
    6.  `phoneNumber` (Non-empty `String`)
    7.  `email` (Non-empty `String`)
    8.  `maritalStatus` (Non-empty `String`)
    9.  `emergencyContactName` (Non-empty `String`)
    10. `emergencyContactNumber` (Non-empty `String`)
    11. `documents['myKad']` status NOT `'empty'`
    12. `documents['passportPhoto']` status NOT `'empty'`
    13. `documents['resume']` status NOT `'empty'`
    14. `documents['academicCertificates']` status NOT `'empty'`
    15. `documents['medicalReport']` status NOT `'empty'`
    16. `documents['bankStatement']` status NOT `'empty'`
   Calculation formula
    $$text{Progress %} = text{Round}left(frac{text{Count of Active Fields } [0text{-}16]}{16} times 100right)$$

### B. Daily Duty Assignments & Verification Flow
1.  Generation Barrier On entering the schedule dashboard, the system invokes `ensureAssignmentsForDate(date)`. If no assignments exist in target date, the system queries active teachers and schedules tasks based on `dayOfWeek` (Weekly tasks) and standard active daily tasks.
2.  Item Checklists with Visual Proof Teachers cannot toggle items to completed without providing physical proof. Pressing an items checkbox triggers the `image_picker` or simulated capture sheet. Once saved, it writes the custom `photoUrl` to that checklist array item, updates completed status, and moves the parent assignment to `'in-progress'` or `'completed'` (if 100% of sub-checklists are ticked).

### C. Duty Swap Negotiation Protocol
1.  Teacher A requests a swap with Teacher B for a specific `duty_assignment`.
2.  Creates a `'duty_swaps'` document in `'pending'` state, creating an Alert notification in Teacher B's dashboard.
3.  Teacher B reviews the alert
       Disapproved Swaps status changes to `'rejected'`. Teacher A receives an notification.
       Approved Swap status updates to `'approved'`. The parent `duty_assignment`'s `teacherIds` array is modified Teacher A's ID is removed and Teacher B's ID is appended. Both teachers are alerted with notification logs.

### D. Professional CPD Course Lifecycle
   Coordinated Creation Principal compiles standard posts which flag `isTraining true`. They select seat capacity (`maxTrainees`) and coordinate the recruitment mode (`'volunteer'` vs. `'assigned'`).
   Volunteer Enrollment Teachers see volunteer courses. If cumulative enrolled list size `traineeIds.length` is less than `maxTrainees`, the 'Apply' option is active. Clicking this submits a `training_application` in `'pending'` state and targets notifications to `'admin-id'`.
   Approval Pipeline Principal views the pending applications in the notifications or via the Training stream component. If approved the application status sets to `'approved'`, the teacher's ID is pushed into the `traineeIds` list inside the root `training_post` document, and a success notification triggers. If declined setting status to `'rejected'` sends a declining notification.
   Assigned Enrollment If listed `'assigned'`, the training stream displays the status as Assigned instantly. The teacher bypasses manual application and is auto-registered inside the `traineeIds` array without review.

---

## 5. Visual System & Typography Specs

The Flutter implementation must adhere to an ultra-clean, minimal, layout design following custom themed parameters mimicking clean iOS design styles.

### A. Color Palette Design System
In Flutter's `ThemeData`, customize the color schemes to match these specific token definitions
   Canvas Base Background `#F5F5F3` or `#FAF9F6` (Ambient Off-White)
   Accent Container Cards `#FFFFFF` with custom thin outlines and subtle shadows.
   Primary Active Color `#B2C2B2` (Moss Green Tint)
   Secondary Accent `#BCCCDC` (Soft Powder Blue)
   Warm Pink accents `#E8D1D1` (Pale CherryBlush)
   Aesthetic Wood Tan `#F2E8DA` (Light Linen Oat)
   Deep Charcoal Core Text `#4A4A4A` (Highly readable dark text)
   Muted Text Accent `#8E8E8E` (Secondary gray strings)
   Subtle Gray Boundaries `#F0EFEC` (Clean divider elements)

### B. Structural Layout System
   Shadow System (iOS-inspired)
    ```dart
    final iosBoxShadow = BoxShadow(
      color Colors.black.withOpacity(0.03),
      offset const Offset(0, 4),
      blurRadius 12,
    );
    ```
   Aesthetic Border Radius (2D curves) Rounded contours using `BorderRadius.circular(24)` or `16` for cards, and `12` for buttons.
   Negative Spacing Generous layout margins `16.0` or `20.0` px on responsive safe areas. Mobile devices must restrict horizontal overflow entirely (no horizontal scroll bars).

---

## 6. Layout Hierarchy Mapping

Your screens must route accurately according to role logs

### 1. Gateway Route `LoginScreen`
A high-contrast aesthetic gateway page containing teacher vs. principal mock credential selection. Uses standard animated sliding containers to ease dashboard entry on validation bounds.

### 2. Teacher Portal Route `TeacherDashboard`
Navigated with an iOS bottom tab element
1.  Home Tab Dynamic KPI scorecard radial tracker, Daily Duty Assignments checklist builder, three quick-action shortcuts (File Report, Leaves Status, Schedules Overview), current day duty progress indicators.
2.  Training Tab Highly searchable LinkedIn social network feed, featuring point form list modifiers, links integration, liking counters, commenting sub-panels, and volunteer application controls.
3.  Performance Tab Monthly ratings visualizer charts, warning records details.
4.  Alerts Tab Chronological unread alerts counting badges and dismissible notifications.
5.  Profile Tab Comprehensive record completion indicator, interactive forms, and simulated file uploads.

### 3. Principal Portal Route `PrincipalDashboard`
Governed by a parallel navigation flow
1.  Home Tab Active registered faculty directory, aggregated KPI monitoring, and 4 quick actions (View Tasks, KPI Performance, Incidents Inbox (for Reports), Leave Approval).
2.  Training Tab Coordinated training creation gateway (including volunteer and assigned target parameters) together with inline registrationapprovals check sheets.
3.  Schedule Tab Full tasks setup calendars, assignee modifications, checkable lists review, and swap negotiations.
4.  KPI Performance Tab Points allocation, criteria mapping, and Warning issuance forms.
5.  Alerts Tab Administrator action notifications.
6.  Leaves Tab Reviewer controls with attachments.
7.  Reports Tab Institutional Triaging portal for structural reports.
