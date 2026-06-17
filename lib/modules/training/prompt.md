You are working inside an existing Flutter + Firebase CPD Training module.

You MUST focus ONLY on debugging and fixing issues. Do NOT refactor architecture or rewrite unrelated code.

Allowed scope:
- lib/modules/training/** only

Existing structure:
- models/training.dart
- services/training_service.dart
- providers/training_provider.dart
- screens/admin_training_screen.dart
- screens/teacher_training.dart

Firebase is already configured and working.

---

# 🎯 TASK 1 — FIX APPLY ERROR (CRITICAL)

## Error:
dart exception thrown from converted future
Use properties 'error' and 'stack' to debug

---

## REQUIREMENTS:

When a user applies for training:

- Locate applyTraining / application submission logic
- Wrap ALL async Firestore calls in proper try-catch
- Ensure errors are NOT swallowed or converted incorrectly
- Log and return actual Firebase error message and stack trace

---

## MUST FIX:

- incorrect Future conversion
- missing await handling
- improper async chain in provider/service
- null or invalid postId / teacherId submissions

---

## EXPECTED RESULT:

- Teacher can apply successfully
- If error occurs, it must show real Firebase error (not generic Dart exception wrapper)

---

# 🎯 TASK 2 — FIX USER PROFILE LOAD FAILURE

## Problem:

Clicking on user avatar does NOT load profile or past posts.

---

## REQUIREMENTS:

Fix user profile system so that:

- Clicking author avatar opens profile view
- Profile fetches ALL posts by that user (authorId match)
- Uses Firestore query:
  where('authorId', isEqualTo: selectedUserId)

---

## MUST IMPLEMENT:

- Ensure query is correct and indexed
- Ensure provider updates state properly
- Ensure UI rebuilds when data is received
- Handle empty state properly (no posts)

---

## EXPECTED RESULT:

- Facebook-style profile view
- Shows all historical posts of selected user
- Real-time or streamed updates preferred

---

# 🎯 TASK 3 — FIX FIREBASE STORAGE ERROR (CRITICAL)

## Error:
[firebase_storage/object-not-found] No object exists at the desired reference

---

## REQUIREMENTS:

In training_service.dart:

- Fix uploadImageToStorage logic
- Ensure correct Storage reference path
- Ensure upload completes BEFORE getDownloadURL()
- Do NOT manually construct download URLs
- Ensure same reference is used for upload and retrieval

---

## MUST ENSURE:

- Unique file naming (timestamp or UUID)
- await uploadTask completion
- correct Firebase Storage bucket path

---

# 🎯 TASK 4 — FIX UI OVERFLOW ISSUES

## Problems:
- Right overflow in image preview (~35px)
- Bottom overflow when keyboard appears (~49px)

---

## REQUIREMENTS:

### Image preview fix:
- Use Flexible / Expanded / ConstrainedBox
- Ensure no fixed width usage
- Use BoxFit.cover or contain properly

---

### Keyboard overflow fix:
- Wrap screen with SafeArea
- Use Scaffold(resizeToAvoidBottomInset: true)
- Use SingleChildScrollView where needed
- Add padding using MediaQuery.viewInsets.bottom

---

## EXPECTED RESULT:

- No RenderFlex overflow errors
- Fully responsive UI on all screen sizes
- Works with keyboard open/close

---

# ⚠️ CONSTRAINTS

- DO NOT modify files outside lib/modules/training/**
- DO NOT refactor entire architecture
- DO NOT change Firestore schema
- DO NOT remove existing features
- DO NOT introduce new state management libraries
- MUST preserve real-time feed behavior

---

# 🎯 FINAL EXPECTATION

After fixes:

1. Training application works without Dart Future conversion error
2. User profile loads all past posts correctly
3. Firebase Storage upload works without object-not-found error
4. UI has no overflow issues anywhere in training module
5. System remains stable, real-time, and production-ready