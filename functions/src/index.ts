import * as admin from "firebase-admin";

admin.initializeApp();

// Login gating (active/inactive) is enforced client-side in the Flutter app
// (see lib/core/repositories/user_repository.dart), driven by the
// `users/{uid}.isActive` field that the admin sets via the Teachers list
// approve/reject actions. There is intentionally no Firebase Auth-level
// (disabled flag) enforcement at this time.
