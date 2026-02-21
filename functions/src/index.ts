import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldPath, FieldValue } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();

/**
 * Helper: send multicast FCM and clean up invalid tokens
 */
async function sendNotifications(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
  logPrefix: string
) {
  if (tokens.length === 0) {
    logger.info(`${logPrefix}: No FCM tokens to send to`);
    return;
  }

  const message: MulticastMessage = {
    tokens,
    notification: { title, body },
    data,
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
  };

  try {
    const response = await getMessaging().sendEachForMulticast(message);
    logger.info(
      `${logPrefix}: ${response.successCount} success, ${response.failureCount} failures`
    );

    if (response.failureCount > 0) {
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (
          resp.error &&
          (resp.error.code === "messaging/invalid-registration-token" ||
            resp.error.code === "messaging/registration-token-not-registered")
        ) {
          invalidTokens.push(tokens[idx]);
        }
      });

      if (invalidTokens.length > 0) {
        const batch = db.batch();
        const usersSnap = await db
          .collection("users")
          .where("fcmToken", "in", invalidTokens.slice(0, 30))
          .get();

        usersSnap.docs.forEach((doc) => {
          batch.update(doc.ref, { fcmToken: FieldValue.delete() });
        });

        await batch.commit();
        logger.info(`${logPrefix}: Cleaned up ${invalidTokens.length} invalid tokens`);
      }
    }
  } catch (error) {
    logger.error(`${logPrefix}: Error sending notifications`, error);
  }
}

/**
 * Helper: fetch FCM tokens for a list of user IDs
 */
async function fetchTokens(userIds: string[]): Promise<string[]> {
  const tokens: string[] = [];
  const batches: string[][] = [];
  for (let i = 0; i < userIds.length; i += 30) {
    batches.push(userIds.slice(i, i + 30));
  }

  for (const batch of batches) {
    const usersSnap = await db
      .collection("users")
      .where(FieldPath.documentId(), "in", batch)
      .get();

    usersSnap.docs.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) {
        tokens.push(token);
      }
    });
  }

  return tokens;
}

/**
 * Triggered when a new note request is created in Firestore.
 * Sends push notification to targeted user or all group members.
 * (Kept as v1 function to avoid needing to delete and recreate)
 */
export const onRequestCreated = onDocumentCreated(
  "requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { authorName, authorId, subject, groupId, targetUserId } = data;
    const requestId = event.params.requestId;

    let notificationBody: string;
    const recipientIds: string[] = [];

    if (targetUserId) {
      notificationBody = `${authorName} has requested ${subject} notes from you`;
      if (targetUserId !== authorId) {
        recipientIds.push(targetUserId);
      }
    } else {
      notificationBody = `${authorName} is looking for ${subject} notes`;

      const groupDoc = await db.collection("groups").doc(groupId).get();
      const groupData = groupDoc.data();
      if (!groupData?.members) return;

      const memberIds: string[] = groupData.members;
      recipientIds.push(...memberIds.filter((id: string) => id !== authorId));
    }

    if (recipientIds.length === 0) return;

    const tokens = await fetchTokens(recipientIds);
    await sendNotifications(
      tokens,
      "ClassNotes",
      notificationBody,
      { type: "note_request", requestId, groupId: groupId || "" },
      `onRequestCreated(${requestId})`
    );
  }
);

/**
 * Triggered when a new post (notes) is created in Firestore.
 * Notifies:
 *   1. Authors of open requests for same subject in the group
 *   2. If no matching requests, all group members except the author
 */
export const onPostCreated = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { authorName, authorId, subject, groupId } = data;
    const postId = event.params.postId;

    // Find open requests for the same subject in the same group
    const requestsSnap = await db
      .collection("requests")
      .where("groupId", "==", groupId)
      .where("subject", "==", subject)
      .where("status", "==", "open")
      .get();

    const requesterIds = new Set<string>();
    requestsSnap.docs.forEach((doc) => {
      const reqData = doc.data();
      if (reqData.authorId && reqData.authorId !== authorId) {
        requesterIds.add(reqData.authorId);
      }
      if (reqData.targetUserId && reqData.targetUserId !== authorId) {
        requesterIds.add(reqData.targetUserId);
      }
    });

    let notificationBody: string;
    const recipientIds: string[] = [];

    if (requesterIds.size > 0) {
      notificationBody = `${authorName} shared ${subject} notes you requested!`;
      recipientIds.push(...Array.from(requesterIds));
    } else {
      notificationBody = `${authorName} shared ${subject} notes`;

      const groupDoc = await db.collection("groups").doc(groupId).get();
      const groupData = groupDoc.data();
      if (!groupData?.members) return;

      const memberIds: string[] = groupData.members;
      recipientIds.push(...memberIds.filter((id: string) => id !== authorId));
    }

    if (recipientIds.length === 0) return;

    const tokens = await fetchTokens(recipientIds);
    await sendNotifications(
      tokens,
      "ClassNotes",
      notificationBody,
      { type: "notes_shared", postId, groupId: groupId || "" },
      `onPostCreated(${postId})`
    );
  }
);
