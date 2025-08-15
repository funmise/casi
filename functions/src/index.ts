import * as functions from "firebase-functions/v1";
import {setGlobalOptions} from "firebase-functions/v2";

import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";
import type {UserRecord} from "firebase-admin/auth";

/** Global defaults for non-v1 triggers. */
setGlobalOptions({region: "northamerica-northeast1"});

/**
 * Auth v1 triggers still need an explicit region.
 * Keep blocking triggers in us-central1 so they appear in the console.
 */
const authFns = functions.region("us-central1");

admin.initializeApp();
const db = admin.firestore();

/** Minimal shape passed to the Auth beforeSignIn hook. */
interface BlockingUserInfo {
    uid: string;
    email?: string | null;
    displayName?: string | null;
    photoURL?: string | null;
    phoneNumber?: string | null;
    emailVerified?: boolean;
    disabled?: boolean;
    providerInfo?: Array<{ providerId?: string }>;
}

/** Public user document stored at /users/{uid}. */
interface PublicUser {
    uid: string;
    email: string | null;
    displayName: string | null;
    photoURL: string | null;
    phoneNumber: string | null;
    emailVerified: boolean;
    disabled: boolean;
    providerIds: string[];
}

/**
 * Check if a payload has `providerData` (Admin `UserRecord`).
 * @param {UserRecord|BlockingUserInfo} u
 * The user-like object from Auth.
 * @returns {u is UserRecord}
 * True when the object is a `UserRecord`.
 */
function hasProviderData(
  u: UserRecord | BlockingUserInfo,
): u is UserRecord {
  return "providerData" in u;
}

/**
 * Check if a payload has `providerInfo` (blocking sign-in payload).
 * @param {UserRecord|BlockingUserInfo} u
 * The user-like object from the blocking hook.
 * @returns {u is BlockingUserInfo}
 * True when the object is a blocking payload.
 */
function hasProviderInfo(
  u: UserRecord | BlockingUserInfo,
): u is BlockingUserInfo {
  return "providerInfo" in u;
}

/**
 * Convert any user payload into the public Firestore user shape.
 * Works for both Admin `UserRecord` and blocking sign-in payloads.
 * @param {UserRecord|BlockingUserInfo} u
 * User information from Auth.
 * @returns {PublicUser}
 * The sanitized user document to store in Firestore.
 */
function toPublicUser(u: UserRecord | BlockingUserInfo): PublicUser {
  const ids = hasProviderData(u) ?
    u.providerData
      .map((p) => p?.providerId)
      .filter((id): id is string => !!id) :
    hasProviderInfo(u) ?
      (u.providerInfo ?? [])
        .map((p) => p?.providerId)
        .filter((id): id is string => !!id) :
      [];

  return {
    uid: u.uid,
    email: u.email ?? null,
    displayName: u.displayName ?? null,
    photoURL: u.photoURL ?? null,
    phoneNumber: u.phoneNumber ?? null,
    emailVerified: !!u.emailVerified,
    disabled: !!u.disabled,
    providerIds: ids,
  };
}

/**
 * Create/seed `/users/{uid}` when the account is created.
 * @param {UserRecord} user
 * The newly created Auth user.
 * @returns {Promise<void>}
 * Resolves when the write completes.
 */
export const onAuthUserCreated = authFns
  .auth
  .user()
  .onCreate(async (user: UserRecord): Promise<void> => {
    await db.doc(`users/${user.uid}`).set(
      {
        ...toPublicUser(user),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        lastSignInAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });

/**
 * Refresh the user doc on every sign-in (blocking).
 * @param {BlockingUserInfo} event
 * The blocking sign-in payload.
 * @returns {Promise<object>}
 * Empty object to continue sign-in without changing claims.
 */
export const refreshUserDocOnSignIn = authFns
  .auth
  .user()
  .beforeSignIn(
    async (event: BlockingUserInfo): Promise<object> => {
      await db.doc(`users/${event.uid}`).set(
        {
          ...toPublicUser(event),
          updatedAt: FieldValue.serverTimestamp(),
          lastSignInAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      return {};
    },
  );

/**
 * Delete `/users/{uid}` when the account is deleted.
 * @param {UserRecord} user
 * The deleted Auth user.
 * @returns {Promise<void>}
 * Resolves after the delete attempt.
 */
export const onAuthUserDeleted = authFns
  .auth
  .user()
  .onDelete(async (user: UserRecord): Promise<void> => {
    await db.doc(`users/${user.uid}`).delete().catch(() => null);
  });
