# TASK: Replace Demo Login System with Production-Ready Authentication System

You are a senior Flutter + Firebase architect.

The current application contains a demo login/logout implementation where users are selected from a list and logged in locally. This must be completely replaced with a secure production-ready authentication system using Firebase Authentication and Firestore.

## IMPORTANT REQUIREMENTS

### General Rules

* Do NOT create a fake login system.
* Do NOT store passwords locally.
* Do NOT bypass Firebase Authentication.
* Do NOT use hardcoded users.
* Do NOT use insecure local authentication.
* Follow Flutter, Firebase, and security best practices.
* Code must be clean, modular, scalable, and production-ready.
* Use Provider architecture if the project already uses Provider.
* Follow existing project structure where possible.

---

# AUTHENTICATION FEATURES

## Login Screen

Replace the existing user selection login with:

### Inputs

1. Email Address Field
2. Password Field

### Email Validation

Must validate:

* Not empty
* Proper email format
* Trim whitespace
* Convert to lowercase before authentication

Example:

Valid:

* [user@gmail.com](mailto:user@gmail.com)
* [user@company.com](mailto:user@company.com)

Invalid:

* user
* user@
* @gmail.com

Display user-friendly validation messages.

---

### Password Validation

Must validate:

* Not empty
* Minimum 8 characters
* Maximum 128 characters
* Reject leading/trailing whitespace
* Prevent common weak passwords

Display validation errors immediately.

---

### Security Requirements

Prevent:

* Injection attacks
* XSS-style payloads
* Unexpected special-character abuse
* Invalid input lengths
* Malicious copy-paste payloads

Implement:

* Input sanitization
* Length limits
* Validation before submission

Never trust client input.

---

### Password Field Features

Include:

* Show Password button
* Hide Password button
* Proper keyboard types
* Autofill support

---

# FIREBASE AUTHENTICATION

Use Firebase Authentication.

### Login Flow

When Login button is pressed:

1. Validate form
2. Sanitize input
3. Show loading state
4. Authenticate using Firebase Auth
5. Handle Firebase exceptions properly
6. Navigate based on user role

Examples:

* Teacher → Teacher Dashboard
* Admin → Admin Dashboard
* Principal → Principal Dashboard

Role information should come from Firestore.

---

# REMEMBER ME FEATURE

Add a Remember Me checkbox.

## If NOT checked

After logout:

* No quick login account saved
* User must enter credentials again

---

## If checked

Store ONLY safe information locally:

Store:

* uid
* display name
* email
* profile image URL (if available)
* role

DO NOT STORE:

* password
* auth tokens manually
* sensitive credentials

Use:

* flutter_secure_storage
* encrypted local storage

---

# MULTI-ACCOUNT QUICK LOGIN

Support multiple remembered accounts.

Example:

Device remembers:

* John (Teacher)
* Sarah (Admin)
* David (Principal)

Show them on login screen.

---

## Quick Login UI

Display saved accounts:

Avatar
Name
Email
Role

Options:

### Login as John

Tapping account:

* Autofills email
* Focuses password field
* User enters password
* Login proceeds

OR

If secure Firebase session still exists:

* Restore session automatically

---

### Login as Another Person

Button:

"Use Another Account"

Shows normal login form.

---

### Remove Account

Each remembered account must include:

Remove Account button shown minimally

When pressed:

* Delete saved account from device
* Remove from quick-login list
* Do not affect Firebase account itself

Only remove local remembered account.

---

# FORGOT PASSWORD FEATURE

Add:

"Forgot Password?"

under password field.

---

## Forgot Password Flow

Step 1:

User enters email.

Validate email.

---

Step 2:

Verify account exists.

---

Step 3:

Use Firebase password reset flow.

Send password reset email.

---

## User Experience

Show:

Success:
"Password reset email sent."

Failure:
"Email address not found."

Network:
"Unable to send reset email. Check connection."

---

# SESSION MANAGEMENT

Implement proper session handling.

---

## Auto Login

If Firebase session exists:

Automatically login.

Do not show login screen.

Navigate directly to correct dashboard.

---

## Session Expired

Handle:

* Expired session
* Revoked session
* Disabled account

Redirect to login.

Show appropriate message.

---

# LOGOUT SYSTEM

Replace demo logout screen.

---

## Logout Flow

When logout button pressed:

1. Show confirmation dialog

Title:
"Sign Out"

Message:
"Are you sure you want to sign out?"

Buttons:

* Cancel
* Sign Out

---

## Sign Out Action

Perform:

FirebaseAuth.instance.signOut()

Clear:

* Cached session data
* Temporary auth state

Keep:

* Remembered accounts (if user selected Remember Me)

---

## After Logout

Navigate to login screen.

No back navigation possible.

User must not be able to return using Android back button.

Use route replacement.

---

# FIRESTORE USER DATA

Create user document structure.

Example:

users/{uid}

{
uid: "",
email: "",
fullName: "",
role: "",
profileImage: "",
isActive: true,
createdAt: timestamp,
lastLogin: timestamp
}

---

## Login Checks

Before allowing access:

Verify:

* User document exists
* Account active
* Role valid

Reject login if:

* User disabled
* User record missing
* Invalid role

---

# UI / UX REQUIREMENTS

The UI must look modern and professional.

---

## Responsive Design

Must work perfectly on:

* Small phones
* Large phones
* Tablets
* Desktop
* Web

No overflow errors.

No RenderFlex overflow.

No pixel overflow.

No clipping.

No hidden buttons.

No fixed-width layouts that break.

Use:

* LayoutBuilder
* MediaQuery
* Responsive constraints
* Flexible
* Expanded
* SingleChildScrollView where appropriate

---

## Accessibility

Support:

* Screen readers
* Keyboard navigation
* Focus traversal
* Proper labels

---

## Loading States

Show loading indicators for:

* Login
* Logout
* Password reset
* Session restore

Disable buttons during loading.

Prevent duplicate requests.

---

## Error Handling

Display friendly messages.

Never expose:

* Firebase stack traces
* Internal exceptions
* Technical errors

Log technical errors internally only.

---

# CODE QUALITY

Create separate layers:

## Services

AuthService

Responsibilities:

* Firebase Auth
* Password reset
* Session management

---

## Repositories

UserRepository

Responsibilities:

* Firestore user data

---

## Providers

AuthProvider

Responsibilities:

* Login
* Logout
* Current user
* Loading state
* Remembered accounts

---

## Models

AppUser
RememberedAccount

---

# DELIVERABLES

Implement:

1. Firebase Authentication integration
2. Login screen
3. Logout flow
4. Remember Me
5. Multi-account quick login
6. Remove remembered account
7. Forgot password
8. Session restoration
9. Role-based navigation
10. Firestore integration
11. Secure storage
12. Responsive UI
13. Input validation
14. Production-level error handling

Do not stop after planning.

Apply the changes directly to the codebase and provide all modified files with complete code.
