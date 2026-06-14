# Teacher Management System

Follow the following file structure when implementing
```
lib/
├── main.dart
├── app_theme.dart
├── routes.dart
│
├── core/                          # Shared across all modules
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── firestore_constants.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── validators.dart
│   ├── widgets/                   # Reusable UI components
│   │   ├── loading_spinner.dart
│   │   └── error_message.dart
│   └── services/
│       ├── auth_service.dart
│       └── database_seeder.dart
│
├── providers/                     # Global app state
│   ├── app_state_provider.dart
│   └── auth_provider.dart
│
└── modules/
    ├── auth/                      # Member A owns this
    │   ├── models/
    │   ├── providers/
    │   ├── services/
    │   └── screens/
    │
    ├── duty/                      # Member B owns this
    │   ├── models/
    │   │   ├── duty.dart
    │   │   └── duty_location.dart
    │   ├── providers/
    │   │   └── duty_provider.dart
    │   ├── services/
    │   │   └── duty_service.dart
    │   └── screens/
    │       ├── duty_list_screen.dart
    │       └── duty_detail_screen.dart
    │
    ├── training/                  # Member C owns this
    │   ├── models/
    │   ├── providers/
    │   ├── services/
    │   └── screens/
    │
    ├── teacher/                   # Member D owns this
    │   ├── models/
    │   │   └── teacher.dart
    │   ├── providers/
    │   ├── services/
    │   └── screens/
    │
    └── dashboard/                 # Member E owns this
        ├── models/
        ├── providers/
        ├── services/
        └── screens/
```