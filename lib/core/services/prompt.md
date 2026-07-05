# Feature Specification: Teacher Registration with Admin Approval (Firebase Authentication + Cloud Functions + Firebase Admin SDK)

## Objective

Implement a teacher registration workflow where newly registered teachers **cannot log in until their account has been reviewed and approved by an administrator**.

This feature must use:

- Firebase Authentication (Email & Password)
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Admin SDK

The approval process **must not rely solely on client-side checks**. Newly registered users should have their Firebase Authentication account **disabled** immediately after registration using the Firebase Admin SDK. Only an administrator can enable the account.

---

# Overall Workflow

```
Teacher registers
        │
        ▼
Firebase Authentication
(Create Email & Password)
        │
        ▼
Teacher profile saved in Firestore
status = Pending
role = Teacher
        │
        ▼
Cloud Function automatically disables
the Firebase Auth account
        │
        ▼
Registration Successful screen
"Your account is awaiting administrator approval."
        │
        ▼
Teacher attempts login
        │
        ▼
Firebase Authentication
returns user-disabled
        │
        ▼
Display friendly message
"Your account is still awaiting administrator approval."
        │
        ▼
Administrator approves account
        │
        ├── Firestore:
        │      status = Approved
        │
        └── Firebase Admin SDK:
               disabled = false
        │
        ▼
Teacher can log in normally
```

---

# Registration Screen

Create a registration screen specifically for teachers.

## Form Fields

### Personal Information

- Full Name
    - Text Field
    - Required

- IC Number
    - Text Field
    - Required
    - Validate Malaysian IC format (basic validation acceptable)

- Gender
    - Dropdown
    - Options:
        - Male
        - Female

- Date of Birth
    - Date Picker
    - Cannot be a future date
    - Required

---

### Contact Information

- Email
    - Email input
    - Required
    - Must follow email format

- Phone Number
    - Phone input
    - Required

- Address
    - Multi-line text field
    - Required

---

### Additional Information

- Marital Status
    - Dropdown
    - Options:
        - Single
        - Married
        - Divorced
        - Widowed

---

### Emergency Contact

- Emergency Contact Name
    - Text Field
    - Required

- Emergency Contact Number
    - Phone input
    - Required

---

### Account Credentials

- Password
    - Password field
    - Required
    - Minimum 8 characters
    - Show/Hide toggle

- Confirm Password
    - Password field
    - Required
    - Show/Hide toggle

Validation:

- Passwords must match.
- Prevent submission if they do not.

---

### Hidden Fields

These must NOT appear on the form.

```
role = Teacher

status = Pending
```

These values should automatically be stored in Firestore.

---

# Firestore Document Structure

Collection:

```
users
```

Document ID:

```
Firebase Authentication UID
```

Example:

```json
{
  "uid": "firebase_uid",
  "fullName": "John Tan",
  "icNumber": "010203071234",
  "gender": "Male",
  "dateOfBirth": "2001-02-03",
  "email": "john@gmail.com",
  "phoneNumber": "0123456789",
  "address": "Bukit Mertajam",
  "maritalStatus": "Single",
  "emergencyContact": "Jane Tan",
  "emergencyNumber": "0191234567",

  "role": "Teacher",
  "status": "Pending",

  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

# Registration Process

When the Register button is pressed:

## Step 1

Validate every input field.

Do not submit if any validation fails.

---

## Step 2

Create Firebase Authentication account using Email and Password.

---

## Step 3

Create Firestore document with:

```
status = Pending

role = Teacher
```

---

## Step 4

Trigger a Cloud Function.

The Cloud Function must:

- receive the newly created user
- use Firebase Admin SDK
- disable the Authentication account

Equivalent Admin SDK operation:

```
admin.auth().updateUser(uid, {
    disabled: true
});
```

This ensures the user cannot authenticate until approval.

---

## Step 5

Sign the user out (if still signed in after registration).

---

## Step 6

Navigate to a success screen or show a success dialog.

Display a friendly message such as:

> Registration submitted successfully.
>
> Your account is currently awaiting administrator approval before it can be used.
>
> Please contact your system administrator if you have any questions or require urgent access.

Include a button:

```
Back to Login
```

---

# Login Behaviour

When a teacher attempts to log in:

Attempt Firebase Authentication normally.

Possible outcomes:

## Account Approved

Firebase Authentication succeeds.

User enters the application.

---

## Account Pending

Firebase returns:

```
user-disabled
```

Display a user-friendly message such as:

> Your account has not yet been approved by the administrator.
>
> Please contact your administrator for assistance.
>
> You will be able to sign in once your account has been approved.

Do not allow login.

---

## Invalid Email

Display:

```
No account exists with this email address.
```

---

## Wrong Password

Display:

```
Incorrect password.
```

---

## Network Error

Display an appropriate connection error message.

---

# Administrator Approval Workflow

Administrator page displays all users where:

```
status == Pending
```

Each pending teacher should display:

- Full Name
- Email
- Phone Number
- IC Number
- Registration Date

Buttons:

- Approve
- Reject

---

## Approve

When administrator presses Approve:

### Firestore

Update:

```
status = Approved
updatedAt = current timestamp
```

### Firebase Admin SDK

Enable Authentication account:

```
admin.auth().updateUser(uid, {
    disabled: false
});
```

Teacher can now log in normally.

---

## Reject

When administrator presses Reject:

Update Firestore:

```
status = Rejected
```

Disable account remains true.

(Optional: Future enhancement may include deleting rejected accounts after a configurable retention period.)

---

# Firestore Security Considerations

Teachers must never be able to modify:

- role
- status

Only administrators may update:

- status
- role

Users may edit only their own permitted profile fields after approval.

---

# Cloud Functions

Implement secure backend Cloud Functions using Firebase Admin SDK for:

1. Automatically disabling newly registered Authentication accounts.
2. Enabling Authentication accounts when an administrator approves them.
3. (Optional) Keeping Firestore status and Authentication disabled state synchronized.

No client application should directly enable or disable Firebase Authentication accounts.

---

# User Experience Requirements

- Use clear validation messages for every required field.
- Disable the Register button while submission is in progress.
- Show a loading indicator during registration.
- Prevent duplicate submissions.
- Use friendly, non-technical language for all success and error messages.
- Ensure the interface is responsive and accessible across supported device sizes.

---

# Acceptance Criteria

- Teacher registration form collects all required information.
- Hidden fields automatically assign:
  - role = Teacher
  - status = Pending
- Password and Confirm Password must match.
- Firebase Authentication account is created successfully.
- Firestore profile document is created successfully.
- Cloud Function immediately disables the Firebase Authentication account.
- User sees a registration success message instructing them to await administrator approval.
- Pending users cannot log in.
- Login displays a clear approval message when the account is disabled.
- Administrator can approve a pending teacher.
- Approval updates Firestore and re-enables the Authentication account through the Firebase Admin SDK.
- Approved teachers can log in successfully.
```