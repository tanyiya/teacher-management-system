You are working inside an existing Flutter + Firebase CPD Training module.

Existing architecture (DO NOT CHANGE STRUCTURE):
- models/training.dart
- services/training_service.dart
- providers/training_provider.dart
- screens/admin_training_screen.dart
- screens/teacher_training.dart

Firebase is already configured and working.

Your task is to FIX bugs and IMPLEMENT missing features without breaking existing functionality.

---

# 🎯 TASK 1 — FIX IMAGE UPLOAD (CRITICAL)

Implement full working image upload flow for posts.

## Requirements:

When user creates a post (teacher or admin):

1. User selects image using:
   - image_picker package

2. Upload image to:
   - Firebase Storage

3. Get download URL from Storage

4. Save URL into Firestore:
   - TrainingPost.photoUrl (String field)

---

## Implementation rules:

All logic MUST be inside:
- services/training_service.dart

Add or fix function:
- uploadImageToStorage(File imageFile) → returns download URL

Ensure:
- supports jpg/png
- unique file naming
- returns valid public download URL

---

## UI integration:

In:
- teacher_training.dart
- admin_training_screen.dart

Add:
- image picker button in post composer
- preview selected image before upload
- ensure post only saves AFTER upload completes

---

# 🎯 TASK 2 — FIX MISSING POSTS IN FEED (CRITICAL BUG)

## Problem:
- Some posts do NOT appear in main feed
- But appear AFTER using search

## Root cause to investigate:
- incorrect Firestore query filtering
- provider filtering logic
- isTraining flag filtering
- stream vs cached list mismatch

---

## Requirements:

Fix feed so that:

- ALL posts appear in teacher feed (unless explicitly filtered)
- training posts AND normal posts show correctly
- no posts are hidden due to local filtering bug
- real-time Firestore stream is always source of truth

---

## Implementation rules:

In:
- training_provider.dart

Ensure:
- Stream<List<TrainingPost>> is used as primary data source
- remove incorrect client-side filtering that hides posts
- ensure isTraining is NOT accidentally filtering out normal posts

Add debug logging if needed:
- print number of posts received from Firestore stream

---

# 🎯 TASK 3 — FIX LINK CLICKING (URL LAUNCH ISSUE)

## Problem:
Links inside post content cannot be opened.

---

## Requirements:

1. Detect URLs inside:
   - TrainingPost.content

2. Render them as clickable links in UI

3. On tap:
   - open link using url_launcher
   - must open external browser

---

## Implementation rules:

- Use url_launcher package
- Create helper function:
  openUrl(String url)

- Ensure URL is validated before launching:
  - must start with http or https
  - if missing, auto prepend https://

---

## UI requirements:

In post widget:
- links must be tappable
- must be visually distinguishable (blue / underline style)

---

# ⚠️ CONSTRAINTS

- Do NOT change folder structure
- Do NOT remove existing models
- Do NOT duplicate Firestore logic outside service layer
- Must maintain null safety
- Must preserve real-time updates
- Must NOT break existing training application workflow

---

# 🎯 FINAL EXPECTATION

After fixes:

1. Image upload works end-to-end:
   picker → storage → URL → Firestore → UI display

2. All posts reliably appear in feed (no missing posts bug)

3. Links inside posts are clickable and open browser

System must remain fully real-time and production-ready.