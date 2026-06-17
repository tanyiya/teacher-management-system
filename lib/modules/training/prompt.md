You are working inside an existing Flutter + Firebase project.

⚠️ STRICT SCOPE RULE:
You are ONLY allowed to modify files inside:
- lib/modules/training/**

DO NOT touch any other modules, folders, or global app features.

Existing training module structure:
- models/training.dart
- services/training_service.dart
- providers/training_provider.dart
- screens/admin_training_screen.dart
- screens/teacher_training.dart

Firebase is already configured and working.

---

# 🎯 TASK 1 — FIX FIREBASE STORAGE IMAGE UPLOAD

## Problem:
[firebase_storage/object-not-found] No object exists at the desired reference

---

## REQUIRED FIX:

In:
services/training_service.dart

Fix uploadImageToStorage():

- Ensure Firebase Storage reference is correctly created
- Use a unique filename (timestamp or UUID)
- Upload file FIRST, then only call getDownloadURL()
- DO NOT manually construct download URLs
- MUST use same reference for upload and download

---

## FLOW MUST BE:

1. Pick image
2. Upload to Firebase Storage
3. WAIT for upload completion
4. Get download URL from same reference
5. Save URL into Firestore (photoUrl)

---

# 🎯 TASK 2 — REMOVE FONT CUSTOMISATION (TRAINING MODULE ONLY)

## IMPORTANT SCOPE:

Remove font customization ONLY inside training module posting system.

DO NOT touch any other app features.

---

## REMOVE FROM TRAINING MODULE ONLY:

Inside:
- admin_training_screen.dart
- teacher_training.dart
- training provider logic (if related)

Remove:
- fontStyle selection UI
- dropdowns for font selection
- any font preset logic used ONLY for post creation
- any UI controls that let users choose fonts when posting

---

## RULE:

- DO NOT modify TrainingPost model globally
- DO NOT affect other modules using fontStyle (if any exist)
- Only remove font customization from POSTING UI

---

## RESULT:

All training posts use default system text style only.

---

# 🎯 TASK 3 — FIX IMAGE PREVIEW OVERFLOW (35px RIGHT OVERFLOW)

## Problem:

Image preview in post composer overflows on the right side.

---

## FIX REQUIREMENTS:

In training screens:

- Wrap image preview in Flexible / Expanded / ConstrainedBox
- Ensure image uses BoxFit.cover or BoxFit.contain
- NEVER use fixed width values
- Ensure responsiveness across all screen sizes

---

# 🎯 TASK 4 — FIX KEYBOARD BOTTOM OVERFLOW (49px)

## Problem:

When keyboard opens during posting, bottom overflow occurs.

---

## FIX REQUIREMENTS:

Wrap training screens with:

- SafeArea
- Scaffold(resizeToAvoidBottomInset: true)
- SingleChildScrollView OR proper scroll handling

Also:

- Add padding using MediaQuery.viewInsets.bottom
- Ensure input fields remain visible above keyboard

---

# ⚠️ CONSTRAINTS (VERY IMPORTANT)

- ONLY modify files inside lib/modules/training/**
- DO NOT touch other modules or global providers
- DO NOT refactor unrelated code
- DO NOT change app-wide UI systems
- MUST preserve Firestore schema
- MUST preserve real-time feed functionality
- MUST NOT break existing training application workflow

---

# 🎯 FINAL EXPECTATION

After implementation:

1. Firebase Storage upload works without object-not-found error
2. Font customization is removed ONLY from training posting UI
3. Image preview no longer overflows horizontally
4. Keyboard no longer causes bottom overflow
5. Training module remains fully functional and isolated from rest of app