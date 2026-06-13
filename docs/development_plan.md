# Flutter Implementation & Development Plan: Teacher Management System

This document maps out a structured, step-by-step master checklist to guide the complete rewrite of the React/TypeScript system into a native, high-performance **Flutter (Dart)** application. It defines the folder architecture, required packages, domain data models, business logic classes, responsive layout views, and real-time state mechanics.

---

## 1. Project Directory Blueprint

The Flutter project must adapt standard clean architecture patterns. Group files by features or technical layers in your `lib/` directory:

```text
lib/
│
├── main.dart                      # App entry point, Provider initializations, Theme
├── app_theme.dart                 # iOS-inspired colors, shadows, and text styles
├── routes.dart                    # GoRouter or basic PageRoute transition rules
│
├── models/                        # Domain models & state schemas
│   ├── teacher.dart               # TeacherRecord, Gender, MaritalStatus, Document
│   ├── duty.dart                  # DutyTask, Location, Assignment, Checklist, Swap
│   ├── leave.dart                 # LeaveRecord, LeaveType
│   ├── performance.dart           # PerformanceLog, Warning, Categories
│   ├── report.dart                # Facility Incident Report Model
│   ├── training.dart              # TrainingPost, Comment, Application
│   └── alarm_or_notification.dart # Alert Notification Model
│
├── services/                      # Firebase and API integrations
│   ├── auth_service.dart          # Local role switcher & Session caching
│   ├── database_service.dart      # Real-time collection streams and Firestore CRUD
│   ├── database_seeder.dart       # Seeding of base tasks, teachers, and locations
│   └── pdf_service.dart           # KPI document compiler and viewer
│
├── providers/                     # State management layers (Provider / Riverpod)
│   ├── app_state_provider.dart    # Active user role session state
│   ├── duty_provider.dart         # Active dates assignments and swaps
│   ├── training_provider.dart     # Postings, comments feed, and applied lists
│   └── leave_report_provider.dart # Administrative flows
│
├── widgets/                       # Reusable UI Atoms & Components
│   ├── ios_card.dart              # Rounded corner container with thin borders & soft shadow
│   ├── ios_button.dart            # Moss Green / Accent action buttons
│   ├── rich_renderer.dart         # Rich text formatting parser (matches [Link](url) & bullet lists)
│   └── attachment_viewer.dart     # Image picker and uploaded pdf visualization
│
└── screens/                       # Full layout screen scaffolds
    ├── login_screen.dart          # Gateway credential selector
    │
    ├── teacher/                   # Teacher Portal
    │   ├── teacher_dashboard.dart # Core tab controller (Home, Training, KPI, Alerts, Profile)
    │   ├── home_tab.dart          # Radial KPI widget, shortcuts list, today assignments
    │   ├── training_tab.dart      # Social posts feeds and CPD enrollments
    │   ├── performance_tab.dart   # fl_charts monthly ratings lists
    │   ├── alerts_tab.dart        # Real-time user notification center
    │   └── profile_tab.dart       # Form checklist & documents uploads
    │
    └── principal/                 # Principal/Admin Portal
        ├── principal_dashboard.dart # Core Tab (Home, Training, Schedules, KPI, Alerts, Leaves, Reports)
        ├── principal_home_tab.dart  # Faculty records lists & stats summary
        ├── duty_scheduler_tab.dart  # Task setups, calendar assign, and swap reviews
        ├── leave_approval_tab.dart  # Administrative review sheet
        └── report_triaging_tab.dart # Incidents inbox inspector
```

---

## 2. Shared Packages (`pubspec.yaml` Specification)

Configure these dependencies in the `pubspec.yaml` file of the Flutter project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core & Firestore
  firebase_core: ^3.10.0
  cloud_firestore: ^5.6.0
  
  # State Management & DI
  provider: ^6.1.2
  
  # Routing & Transitions
  go_router: ^14.2.0
  
  # Elegant Animations
  flutter_animate: ^4.5.0
  
  # Aesthetic Charts (KPI Trends)
  fl_chart: ^0.70.0
  
  # PDF document compilation
  pdf: ^3.11.1
  printing: ^5.13.2
  
  # Image uploads & camera access (Duty Checklists & Reports)
  image_picker: ^1.1.2
  file_picker: ^8.1.4
  
  # Interactive icons
  lucide_icons: ^3.0.0
  
  # Caching and local persistence
  shared_preferences: ^2.3.2
```

---

## 3. Implementation Step-by-Step Milestones

Follow this checklist sequentially to construct the system systematically. Note that each step builds upon the data structures or database flows created previously:

### Phase 1: Models & Domain Definitions
- [ ] Create `lib/models/teacher.dart` defining enums for `Gender` and `MaritalStatus`. Define `TeacherRecord` with nested document lists mapping to MyKad, Resume, and academic papers statuses.
- [ ] Create `lib/models/duty.dart` with enums for `DutyFrequency` and maps for checklist items (`isCompleted`, `photoUrl`, `completedAt`). Add models for `DutyTask`, `DutyLocation`, `DutyAssignment`, and `DutySwapRequest`.
- [ ] Create `lib/models/leave.dart` mapping leave classifications (`annual`, `medical`, `sick`, `unpaid`, etc.) and status boundaries.
- [ ] Create `lib/models/training.dart` containing models for `TrainingPost`, `TrainingComment`, and `TrainingApplication`. Include fields for formatting font styles, trainee seat ceilings, and enrollment types.
- [ ] Create remaining domain model files for warning records, performance points distribution, and dismissible alerts.

### Phase 2: Core Database Seeder & Connection Setup
- [ ] Establish initial Firebase connections inside `lib/services/database_service.dart`.
- [ ] Write `lib/services/database_seeder.dart`. Create a `seedDatabase()` function that triggers on app initialization (equivalent to React's `dutyService.seedInitialData()`).
- [ ] Check if the `teachers` collection is empty. If empty, write the three default mock teachers: *Sarah Jenkins*, *David Kim*, and *Michael Lee* into Firestore with full personal records and 100% completed profile states.
- [ ] Check if locations are initialized. Seed the 17 unique campus facilities (Assembly Hall, Dining Area, etc.).
- [ ] Seed the default tasks registry, including the daily arrival duties, cleaning checklists, transition guidelines, and the Monday weekly assembly with its specialized curriculum checklist items.

### Phase 3: Reactive State Management Layer (Changenotifiers)
- [ ] Create `lib/providers/app_state_provider.dart` to handle runtime session logs: handle current user caching using `shared_preferences` for hot resets.
- [ ] Create `lib/providers/duty_provider.dart` mapping date check routines. Implement real-time listener bindings using `.snapshots()` to keep checklists and duty swap counters up to date.
- [ ] Create `lib/providers/training_provider.dart` syncing social media updates, filtering comments matching active posts, and listing CPD enrollment indicators.
- [ ] Combine all state components within your `MultiProvider` configuration in `main.dart`.

### Phase 4: UI Design System & Component Library
- [ ] Define the application themes in `lib/app_theme.dart`. Build custom implementations for Moss Green `#B2C2B2` as primary color, Wood Tan `#F2E8DA` accents, and deep gray `#4A4A4A` fonts.
- [ ] Assemble `lib/widgets/ios_card.dart` rendering rounded material cards styled with thin borders `#F0EFEC` and soft shadows on custom borders.
- [ ] Write custom visual parser `lib/widgets/rich_renderer.dart`. Create a text converter wrapping inline markdown links `[Label](url)` in stylized colored buttons, while appending custom list views for point forms.
- [ ] Develop `lib/widgets/attachment_viewer.dart` allowing user file selection using `image_picker` and mocking PDFs rendering as local files layouts.

### Phase 5: Routing, Login Security, and Dashboard Integration
- [ ] Write `lib/screens/login_screen.dart`. Incorporate credentials selection mapping the two primary roles smoothly. Use `flutter_animate` to introduce layout shifts, transitioning to corresponding dashboards.
- [ ] Code `lib/screens/teacher/teacher_dashboard.dart` embedding the native Cupertino-style bottom tabs bar (Home, Training, Performance, Alerts, Profile) with badge counters listening directly to the unread alerts provider.
- [ ] Code `lib/screens/principal/principal_dashboard.dart` linking tabs (Home, Training, Schedule, KPI, Alerts, Leaves, Reports).

### Phase 6: Operational Features (Replicating Core Screens)
- [ ] **Shortcuts & Core Home Tab (Teacher)**: Code dynamic radial KPI trackers, custom shortcuts routing buttons to Leaves/Reports, and active duty schedule summaries.
- [ ] **Home & Faculty List (Principal)**: Build directory grids display, overall metrics tracking, and actions buttons launching KPI adjustments forms or Warning records dispatchers.
- [ ] **Checklist & Image Proofing (Teacher)**: Establish duty checklists views. Trigger camera prompt on tick actions to capture proof images, updating Firestore `duty_assignments` database paths.
- [ ] **Leaves Module**: Teacher submits dates and document files. Principal reviews notifications lists, pulls up details, checks files, adds notes, and clicks Approve/Decline.
- [ ] **Incident Reports Module**: Teacher submits complaints with categories and images. Principal reviews items from the Reports triaging view, assigns status, updates notes, and sets prioritizations.

### Phase 7: Coordinated Training & CPD Module
- [ ] **LinkedIn Social Feed Feed**: Implement vertical social listing items supporting text formatting, inline file rendering, and instant comment panel expanded drawers.
- [ ] **CPM Course Builder (Principal)**: Build training setup parameters selection (Seats limits, Volunteer vs Assigned). If assigned, present list of staff toggles to register teachers into Firestore `traineeIds` array.
- [ ] **Apply & Approve Pipeline**: Implement Volunteer limits checks. Control application creation flow and approval switches in Principal notifications, handling status updates dynamically.

---

## 4. Best Practices & Quality Controls

*   **Responsive Canvas Handling**: Since the web design is responsive and wrapped inside desktop frames while supporting mobile views, the Flutter application must use responsive widgets (`LayoutBuilder` / `Adaptive` structures) to scale neatly across tablets and phone screens.
*   **Preventing State Sync Loops**: When updating nested checklists in `duty_assignments` or likes lists in `training_posts`, avoid rebuilding entire lists from raw assets. Bind views directly to specific document paths to avoid reading data recursively.
*   **Offline Support Activation**: Enable Firestore local caching on startup to allow teachers to check schedules and complete local checkers while offline during signal drops across the campus:
    ```dart
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    ```
*   **Platform Assets Protection**: When compiling files, never reference absolute directory variables. Place all external graphics safely inside standard folders mapping references in `pubspec.yaml` assets list.
