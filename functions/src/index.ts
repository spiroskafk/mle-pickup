/**
 * MLE Cloud Functions — the server-authoritative core.
 *
 * Clients never write `playerIds`, `status`, or capacity directly (Firestore
 * rules deny it). All match mutations go through these callable functions,
 * which run with the Admin SDK and enforce the rules in transactions so
 * concurrent joins can't oversubscribe a match.
 */

import {initializeApp} from "firebase-admin/app";
import {
  getFirestore,
  FieldValue,
  Timestamp,
  GeoPoint,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {
  onCall,
  HttpsError,
  CallableRequest,
} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

initializeApp();
const db = getFirestore();

type MatchStatus = "open" | "full" | "cancelled" | "finished";

interface MatchDoc {
  sport: string;
  organizerId: string;
  venue: {name: string; geo: FirebaseFirestore.GeoPoint};
  startAt: Timestamp;
  totalPlayers: number;
  status: MatchStatus;
  playerIds: string[];
  chatLink?: string | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/** Requires an authenticated caller; returns the uid. */
function requireUid(req: CallableRequest): string {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }
  return req.auth.uid;
}

/**
 * createMatch — validates client input, then creates the match with the
 * organizer as the first participant. The client cannot preset playerIds or
 * status; we own those.
 */
export const createMatch = onCall(async (req) => {
  const uid = requireUid(req);
  const d = req.data ?? {};

  // Contract with the client: startAt is sent as `startAtMs` (epoch millis),
  // and the venue location as separate `lat`/`lng` numbers. This keeps the
  // callable payload plain JSON — no reliance on how a Firestore Timestamp or
  // GeoPoint serializes over the wire.
  const sport = String(d.sport ?? "");
  const totalPlayers = Number(d.totalPlayers ?? 0);
  const venueName = String(d.venue?.name ?? "").trim();
  const lat = Number(d.venue?.lat ?? NaN);
  const lng = Number(d.venue?.lng ?? NaN);
  const startAtMs = Number(d.startAtMs ?? NaN);

  if (!sport) throw new HttpsError("invalid-argument", "Sport is required.");
  if (!Number.isFinite(totalPlayers) || totalPlayers < 2) {
    throw new HttpsError("invalid-argument", "totalPlayers must be >= 2.");
  }
  if (!venueName) {
    throw new HttpsError("invalid-argument", "Venue name is required.");
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new HttpsError("invalid-argument", "Venue location is required.");
  }
  if (!Number.isFinite(startAtMs)) {
    throw new HttpsError("invalid-argument", "Valid startAt is required.");
  }
  const startAt = Timestamp.fromMillis(startAtMs);
  const geo = new GeoPoint(lat, lng);

  const ref = db.collection("matches").doc();
  const now = FieldValue.serverTimestamp();

  await ref.set({
    sport,
    organizerId: uid,
    venue: {name: venueName, geo},
    startAt,
    totalPlayers,
    status: totalPlayers <= 1 ? "full" : "open",
    playerIds: [uid], // organizer occupies the first spot
    chatLink: d.chatLink ? String(d.chatLink) : null,
    createdAt: now,
    updatedAt: now,
  });

  await ref.collection("participants").doc(uid).set({
    uid,
    role: "organizer",
    joinedAt: now,
  });

  return {matchId: ref.id};
});

/**
 * joinMatch — transactionally claims a spot. Rejects if the match is not open,
 * is full, or the caller already joined. The transaction guarantees two users
 * racing for the last spot can't both succeed.
 */
export const joinMatch = onCall(async (req) => {
  const uid = requireUid(req);
  const matchId = String(req.data?.matchId ?? "");
  if (!matchId) {
    throw new HttpsError("invalid-argument", "matchId is required.");
  }

  const ref = db.collection("matches").doc(matchId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Match not found.");
    }
    const m = snap.data() as MatchDoc;

    if (m.status === "cancelled" || m.status === "finished") {
      throw new HttpsError("failed-precondition", "Match is closed.");
    }
    if (m.playerIds.includes(uid)) {
      throw new HttpsError("already-exists", "You already joined.");
    }
    if (m.playerIds.length >= m.totalPlayers) {
      throw new HttpsError("failed-precondition", "Match is full.");
    }

    const nextCount = m.playerIds.length + 1;
    tx.update(ref, {
      playerIds: FieldValue.arrayUnion(uid),
      status: nextCount >= m.totalPlayers ? "full" : "open",
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(ref.collection("participants").doc(uid), {
      uid,
      role: "player",
      joinedAt: FieldValue.serverTimestamp(),
    });
  });

  return {ok: true};
});

/**
 * leaveMatch — transactionally releases the caller's spot, reopening the match.
 * The organizer cannot leave (they cancel instead).
 */
export const leaveMatch = onCall(async (req) => {
  const uid = requireUid(req);
  const matchId = String(req.data?.matchId ?? "");
  if (!matchId) {
    throw new HttpsError("invalid-argument", "matchId is required.");
  }

  const ref = db.collection("matches").doc(matchId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Match not found.");
    }
    const m = snap.data() as MatchDoc;

    if (!m.playerIds.includes(uid)) {
      throw new HttpsError("failed-precondition", "You're not in this match.");
    }
    if (m.organizerId === uid) {
      throw new HttpsError(
        "failed-precondition",
        "Organizer can't leave; cancel the match instead.",
      );
    }

    tx.update(ref, {
      playerIds: FieldValue.arrayRemove(uid),
      status: "open", // a freed spot always reopens
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.delete(ref.collection("participants").doc(uid));
  });

  return {ok: true};
});

/** cancelMatch — organizer-only. */
export const cancelMatch = onCall(async (req) => {
  const uid = requireUid(req);
  const matchId = String(req.data?.matchId ?? "");
  if (!matchId) {
    throw new HttpsError("invalid-argument", "matchId is required.");
  }

  const ref = db.collection("matches").doc(matchId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Match not found.");
  }
  if ((snap.data() as MatchDoc).organizerId !== uid) {
    throw new HttpsError("permission-denied", "Only the organizer can cancel.");
  }

  await ref.update({
    status: "cancelled",
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {ok: true};
});

/**
 * onMatchStatusChange — sends a push when a match fills up, and when a spot
 * reopens. Fires on any match update and diffs the status.
 */
export const onMatchStatusChange = onDocumentUpdated(
  "matches/{matchId}",
  async (event) => {
    const before = event.data?.before.data() as MatchDoc | undefined;
    const after = event.data?.after.data() as MatchDoc | undefined;
    if (!before || !after) return;
    if (before.status === after.status) return;

    let title: string | null = null;
    let body: string | null = null;

    if (after.status === "full") {
      title = "We have a game! ⚽";
      body = `${after.venue.name} is full. See you there.`;
    } else if (before.status === "full" && after.status === "open") {
      title = "A spot just opened";
      body = `Someone left ${after.venue.name}. Grab the spot.`;
    }
    if (!title) return;

    const tokens = await collectTokens(after.playerIds);
    if (tokens.length === 0) return;

    await getMessaging().sendEachForMulticast({
      tokens,
      notification: {title, body: body ?? ""},
      data: {matchId: event.params.matchId},
    });
  },
);

/** Gathers FCM tokens for a set of user ids. */
async function collectTokens(uids: string[]): Promise<string[]> {
  if (uids.length === 0) return [];
  const snaps = await db.getAll(
    ...uids.map((u) => db.collection("users").doc(u)),
  );
  const tokens: string[] = [];
  for (const s of snaps) {
    const t = (s.data()?.fcmTokens as string[] | undefined) ?? [];
    tokens.push(...t);
  }
  return tokens;
}
