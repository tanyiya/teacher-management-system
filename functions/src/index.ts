import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Triggered when a new user is created in Firebase Authentication.
 * Disables the account immediately to require admin approval.
 */
export const disableNewUser = functions.auth.user().onCreate(async (user) => {
  console.log(`New user created: ${user.uid}. Disabling account pending approval.`);
  try {
    await admin.auth().updateUser(user.uid, {
      disabled: true,
    });
    console.log(`Successfully disabled user: ${user.uid}`);
  } catch (error) {
    console.error(`Error disabling user ${user.uid}:`, error);
  }
});

/**
 * Triggered when a user document in Firestore is updated.
 * If the status changes to "Approved", the Authentication account is re-enabled.
 */
export const onUserApproval = functions.firestore
  .document("users/{uid}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Check if status changed from Pending to Approved
    if (previousValue.status === "Pending" && newValue.status === "Approved") {
      const uid = context.params.uid;
      console.log(`User ${uid} approved. Re-enabling account.`);
      try {
        await admin.auth().updateUser(uid, {
          disabled: false,
        });
        console.log(`Successfully re-enabled user: ${uid}`);
      } catch (error) {
        console.error(`Error re-enabling user ${uid}:`, error);
      }
    }
  });
