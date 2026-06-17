You are working inside an existing Flutter + Firebase CPD Training module.

Current architecture already exists:
- models/training.dart
- services/training_service.dart
- providers/training_provider.dart
- screens/admin_training_screen.dart
- screens/teacher_training.dart

Firebase is already configured and working.
Do NOT refactor the project structure. Only extend and fix existing code.

---

# 🎯 TASK OVERVIEW

You must implement feature enhancements + UI bug fixes for the CPD Training Social Feed module.

---

# 🧩 PART 1 — CRITICAL UI BUG FIXES

## 1. Admin screen right overflow (63px issue)

Fix horizontal overflow in admin interface.

Requirements:
- Ensure all Row widgets use:
  - Expanded
  - Flexible
  - or SingleChildScrollView (horizontal if needed)
- Prevent any widget from exceeding screen width
- Ensure responsive layout for:
  - form inputs
  - buttons
  - application lists

NO hardcoded widths allowed.

---

## 2. Keyboard bottom overflow (46px issue)

Fix bottom overflow when keyboard appears.

Requirements:
- Wrap main admin layout with:
  - SingleChildScrollView OR
  - SafeArea + ResizeToAvoidBottomInset
- Ensure form fields remain visible when keyboard opens
- Add proper padding using MediaQuery viewInsets

Must fully eliminate overflow warnings.

---

# 🧩 PART 2 — POST INTERACTION ENHANCEMENTS

## 3. Image upload from local storage

When user (teacher or principal) creates a post:

Add ability to:
- click image upload button inside post composer
- pick image from device storage
- upload to Firebase Storage
- store returned image URL in Firestore (photoUrl field)

Requirements:
- Use image_picker package
- Create reusable function in training_service:
  uploadImageToStorage()

- Must support:
  - admin post
  - teacher post
  - training post

---

## 4. Clickable links inside posts

Enable hyperlink detection in post content.

Requirements:
- Detect URLs inside post content
- Render them as clickable links
- On tap:
  - open in external browser using url_launcher

Ensure:
- links work inside feed
- links work inside comments if present

---

## 5. Search posts (teacher + principal)

Add search functionality in feed.

Requirements:
- Add search bar in teacher_training.dart and admin_training_screen.dart
- Search by:
  - trainingTitle
  - content
  - authorName

Implementation:
- Use Firestore query OR local filtering from provider stream
- Must update results in real-time as user types

---

## 6. Profile view (Facebook-style post owner profile)

When clicking on post author avatar:

Open profile page/modal showing:

Required:
- authorName
- authorRole
- all posts created by that user

Feed requirements:
- Display posts in chronological order
- Same UI style as main feed
- Allow:
  - like posts
  - comment on posts

Data source:
- Filter TrainingPost where authorId == selected userId

---

# 🧩 PART 3 — SOCIAL INTERACTIONS

Ensure existing features remain functional:
- like system
- comments system
- trainee application system

BUT extend them to:
- support real-time UI updates
- reflect changes instantly in feed and profile view

---

# 🧠 SERVICE LAYER RULES (STRICT)

All Firebase logic MUST be inside:
services/training_service.dart

Add or extend functions:

- uploadImageToStorage()
- searchPosts(query)
- getPostsByAuthor(authorId)
- openLink(url handling is UI but detection helper can be here if needed)

NO Firestore calls inside UI or provider directly.

---

# 📦 PROVIDER RULES

training_provider.dart must:

- expose search state
- manage filtered post list
- maintain full post stream
- support profile post filtering state
- ensure real-time sync with Firestore

---

# 📱 UI REQUIREMENTS

## teacher_training.dart
Must include:
- feed
- search bar
- image upload post composer
- clickable links in posts
- profile navigation on avatar click

---

## admin_training_screen.dart
Must include:
- fixed layout (no overflow)
- post creation with image upload
- search bar
- application approval system
- profile navigation support

---

## profile view (new or modal)
Must show:
- user info header
- list of all their posts
- interactive feed behavior

---

# ⚠️ CONSTRAINTS

- Do NOT change project structure
- Do NOT remove existing models
- Do NOT break Firestore schema
- Must use existing TrainingPost / TrainingComment / TrainingApplication models
- Must maintain null safety
- Must ensure responsive UI on mobile screens
- Must not introduce duplicated service logic

---

# 🎯 FINAL EXPECTATION

After implementation:

1. Admin UI has no overflow issues
2. Keyboard no longer causes bottom overflow
3. Users can upload images to posts
4. Links in posts are clickable and open browser
5. Search works in both admin and teacher feeds
6. Clicking profile shows all past posts (Facebook-style)
7. System remains fully real-time with Firebase

Build this as production-quality Flutter code.