import * as functions from "firebase-functions/v1";
import { setGlobalOptions } from "firebase-functions/v2";

import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import type { UserRecord } from "firebase-admin/auth";

import { onSchedule } from "firebase-functions/v2/scheduler";
//import { onCall } from "firebase-functions/v2/https";


/** Global defaults for non-v1 triggers. */
setGlobalOptions({ region: "northamerica-northeast1" });

/**
 * Auth v1 triggers still need an explicit region.
 * Keep blocking triggers in us-central1 so they appear in the console.
 */
const authFns = functions.region("us-central1");

if (!admin.apps.length) admin.initializeApp();
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
      { merge: true },
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
        { merge: true },
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


/**
 * Compute the *reporting* quarter (previous quarter) for a given date.
 * Example: On 2025-04-01, reportingQuarterId = "2025-Q1",
 * opensAt = 2025-04-01T00:00:00-06:00, closesAt = 2025-06-30T23:59:59.999-06:00
 * @param now
 */
function computeReportingQuarter(now: Date): {
  reportingQuarterId: string;
  opensAt: FirebaseFirestore.Timestamp;
  closesAt: FirebaseFirestore.Timestamp;
} {
  // "Current calendar quarter" for `now`
  const month = now.getUTCMonth(); // 0..11
  const yearUTC = now.getUTCFullYear();
  const currQuarter = Math.floor(month / 3) + 1; // 1..4

  // Reporting quarter is the previous quarter
  const repQuarter = currQuarter === 1 ? 4 : currQuarter - 1;
  const repYear = currQuarter === 1 ? yearUTC - 1 : yearUTC;

  // The reporting window is the *current* quarter window:
  //   opens at the *start of the current quarter*
  //   closes at the *end of the current quarter*
  const currQStartMonth = (currQuarter - 1) * 3; // 0,3,6,9

  // window open = first day of current quarter at 00:00:00.000 UTC
  const openUTC = new Date(Date.UTC(yearUTC, currQStartMonth, 1, 0, 0, 0, 0));

  // window close = last millisecond of current quarter
  const nextQStartUTC =
    currQuarter === 4 ?
      new Date(Date.UTC(yearUTC + 1, 0, 1, 0, 0, 0, 0)) :
      new Date(Date.UTC(yearUTC, currQStartMonth + 3, 1, 0, 0, 0, 0));

  // 23:59:59.999 of last day
  const closeUTC = new Date(nextQStartUTC.getTime() - 1);

  const reportingQuarterId = `${repYear}-Q${repQuarter}`;
  return {
    reportingQuarterId,
    opensAt: admin.firestore.Timestamp.fromDate(openUTC),
    closesAt: admin.firestore.Timestamp.fromDate(closeUTC),
  };
}

/**
 * Activate (or create+activate) the survey instance for the current
 * reporting quarter and deactivate all others. Idempotent.
 * @param opts
 * @param opts.templateVersion
 * @param opts.now
 */
async function rolloverQuarterSurvey(
  opts?: { templateVersion?: string; now?: Date }
): Promise<{ activated: string; deactivated: string[] }> {
  const db = admin.firestore();
  const templateVersion = opts?.templateVersion ?? "v1";
  const now = opts?.now ?? new Date();

  const { reportingQuarterId, opensAt, closesAt } = computeReportingQuarter(now);

  const col = db.collection("survey_instances");
  const targetRef = col.doc(reportingQuarterId);

  // Deactivate all others (and collect ids for logging)
  const snap = await col.get();
  const toDeactivate: FirebaseFirestore.DocumentReference[] = [];
  snap.forEach((d) => {
    if (d.id !== reportingQuarterId) toDeactivate.push(d.ref);
  });

  const bw = db.bulkWriter();

  // Upsert the target (active) doc with correct window
  bw.set(
    targetRef,
    {
      quarter: reportingQuarterId,
      opensAt,
      closesAt,
      isActive: true,
      templateVersion,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  // Flip off all others
  toDeactivate.forEach((ref) => {
    bw.set(
      ref,
      {
        isActive: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });

  await bw.close();

  return {
    activated: reportingQuarterId,
    deactivated: toDeactivate.map((r) => r.id),
  };
}

/**
 * Scheduled: runs 00:00 on Jan 1, Apr 1, Jul 1, Oct 1 in America/Regina.
 * Creates/activates the *previous* quarter's survey and deactivates others.
 */
export const advanceQuarterWindow = onSchedule(
  {
    schedule: "0 0 1 Jan,Apr,Jul,Oct *",
    timeZone: "America/Regina",
  },
  async () => {
    const result = await rolloverQuarterSurvey({ templateVersion: "v1" });
    console.log(
      `Activated ${result.activated};` +
      ` deactivated [${result.deactivated.join(", ")}]`
    );
  }
);

export { rolloverQuarterSurvey };
export { onSurveySubmittedExport, nightlyExportRebuild } from './export_quarter';
