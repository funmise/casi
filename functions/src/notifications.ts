import * as admin from 'firebase-admin';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

// --- Admin init
if (!admin.apps.length) admin.initializeApp();
const db = getFirestore();
const msg = getMessaging();

// --- Topics
// for app-wide broadcasts you may want in the future.
const GENERAL_TOPIC = 'casi_general';

// Per-quarter topic helper, e.g. "survey_2025-Q3"
const topicForQuarter = (q: string) => `survey_${q}`;

// ---------- Helpers ----------

// Return the "current" quarter id to target.
// Prefers an active one that hasn't closed; otherwise newest active by opensAt.
async function getActiveQuarterId(): Promise<string | null> {
  const now = Timestamp.now();

  const qs = await db.collection('survey_instances')
    .where('isActive', '==', true)
    .where('closesAt', '>=', now)
    .orderBy('closesAt', 'asc')
    .limit(1)
    .get();

  if (!qs.empty) {
    const d = qs.docs[0];
    const data = d.data() as any;
    return data.quarter ?? d.id;
  }

  const qs2 = await db.collection('survey_instances')
    .where('isActive', '==', true)
    .orderBy('opensAt', 'desc')
    .limit(1)
    .get();

  if (qs2.empty) return null;
  const d2 = qs2.docs[0];
  const data2 = d2.data() as any;
  return data2.quarter ?? d2.id;
}

// Subscribe tokens in safe chunks (Admin API limit is 1000)
async function subscribeTokensToTopic(tokens: string[], topic: string) {
  if (tokens.length === 0) return;
  const BATCH = 900;
  for (let i = 0; i < tokens.length; i += BATCH) {
    const chunk = tokens.slice(i, i + BATCH);
    await msg.subscribeToTopic(chunk, topic);
  }
}

// Send a notification to a topic with Android channel + APNS defaults
async function sendTopicNotification(opts: {
  topic: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}) {
  const { topic, title, body, data } = opts;
  await msg.send({
    topic,
    notification: { title, body },
    data: data ?? {},
    android: {
      priority: 'high',
      notification: { channelId: 'casi_general' }, // must match app's channel id
    },
    apns: {
      payload: { aps: { sound: 'default', contentAvailable: true as any } },
    },
  });
}

// Check whether a user has submitted the given quarter
async function userHasSubmitted(uid: string, quarterId: string): Promise<boolean> {
  const doc = await db.collection('users').doc(uid)
    .collection('surveys').doc(quarterId).get();

  // Treat as submitted if a status flag or submittedAt timestamp exists
  return (
    doc.exists &&
    (
      doc.get('status') === 'submitted' ||
      !!doc.get('submittedAt')
    )
  );
}

// ---------- Triggers ----------

/**
 * A) When an FCM token doc is written/rotates:
 *    - subscribe it to the app-wide GENERAL_TOPIC
 *    - subscribe it to the active quarter topic if the user hasn't submitted
 *
 * Path: users/{uid}/fcmTokens/{token}
 * We store tokens as documents whose IDs are the token strings.
 */
export const onFcmTokenWritten = onDocumentWritten(
  'users/{uid}/fcmTokens/{token}',
  async (event) => {
    const uid = event.params.uid as string;
    const tokenId = event.params.token as string;
    const after = event.data?.after;
    if (!after) return; // deleted -> ignore

    // 1) Optional app-wide broadcast topic
    await subscribeTokensToTopic([tokenId], GENERAL_TOPIC);

    // 2) Put this token on the active quarter's topic if eligible
    const qid = await getActiveQuarterId();
    if (!qid) return;

    const submitted = await userHasSubmitted(uid, qid);
    if (!submitted) {
      await subscribeTokensToTopic([tokenId], topicForQuarter(qid));
    }
  }
);

/**
 * B) When a quarter becomes active:
 *    - Move/subscribe ALL eligible users' tokens to the quarter topic
 *    - Mark "openBroadcastSent" to keep it idempotent
 *    - Send the one-time "Quarter Open" message to that topic
 */
export const onSurveyInstanceActivatedSendReminder = onDocumentWritten(
  'survey_instances/{quarterId}',
  async (event) => {
    const before = event.data?.before?.data() as any | undefined;
    const after = event.data?.after?.data() as any | undefined;
    if (!after) return;

    const becameActive = !!after.isActive && !before?.isActive;
    if (!becameActive) return;

    const quarterId =
      (after.quarter as string | undefined) ?? (event.params.quarterId as string);

    // Idempotency guard
    if (after.openBroadcastSent === true) return;

    // Build uid -> tokens[] from all known fcmTokens
    const tokenDocs = await db.collectionGroup('fcmTokens').get();
    const tokensByUid = new Map<string, string[]>();
    tokenDocs.forEach((t) => {
      const uid = t.ref.parent.parent!.id; // users/{uid}/fcmTokens/{token}
      const arr = tokensByUid.get(uid) ?? [];
      arr.push(t.id); // token is the doc id
      tokensByUid.set(uid, arr);
    });

    // Filter to users who have NOT submitted this quarter
    const tokensToSubscribe: string[] = [];
    for (const [uid, tokens] of tokensByUid.entries()) {
      const submitted = await userHasSubmitted(uid, quarterId);
      if (!submitted) tokensToSubscribe.push(...tokens);
    }

    await subscribeTokensToTopic(tokensToSubscribe, topicForQuarter(quarterId));

    // Mark sent (idempotent) & send "Quarter Open"
    await event.data!.after!.ref.set({
      openBroadcastSent: true,
      openBroadcastSentAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    await sendTopicNotification({
      topic: topicForQuarter(quarterId),
      title: `Quarter ${quarterId} is open`,
      body: `Tap to complete this quarter's CASI survey.`,
      data: { kind: 'quarter_open', quarterId },
    });
  }
);

/**
 * C) Weekly reminder (Mon 9:00 AM America/Regina).
 *    Tokens should already be on the quarter topic from A/B above.
 */
export const weeklySurveyReminder = onSchedule(
  { schedule: '0 9 * * 1', timeZone: 'America/Regina' },
  async () => {
    const quarterId = await getActiveQuarterId();
    if (!quarterId) return;

    await sendTopicNotification({
      topic: topicForQuarter(quarterId),
      title: `Reminder: ${quarterId} survey`,
      body: `Quick check-in: please complete this quarter's CASI survey.`,
      data: { kind: 'weekly_reminder', quarterId },
    });
  }
);
