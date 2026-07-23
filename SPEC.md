# MLE — Product & Technical Spec

> **MLE** = *Mas Leipei Enas* (Greek: "we're one short") — the thing everyone says when a
> pickup game is missing a player. This app fills that gap.

Status: **v1 core loop code-complete.** Landed: domain models, Firestore repositories, auth
service, app skeleton with auth gate, sign-in + discover screens, Firestore security rules,
Cloud Functions (create/join/leave/cancel + notifications), and the create-match, venue
picker, and match-detail (join/leave/cancel) screens. Remaining before it runs: Firebase
project setup (`flutterfire configure`), `flutter create` for native folders, and an
end-to-end test pass. Follow-ups: map view of matches, sport filter, my-matches, profile,
push wiring. This document is the source of truth for scope, data model, and screens;
changes go through commits so the reasoning is tracked.

---

## 1. Problem

Organizing a casual pickup game (football 5x5, basketball, etc.) constantly breaks on one
thing: **someone drops out and you're one player short.** The fallback today is spamming
group chats and hoping. There's no fast, local way to broadcast "one spot open, tonight,
this court" and let nearby players claim it.

## 2. Product vision

A crowd-sourced, hyper-local, time-bound way to fill open spots in pickup games. A player
creates a match (sport + venue + time + how many are missing); nearby players see it and
claim a spot; when it fills, everyone gets notified.

**Success metric (v1):** the author and their circle actually use it to fill real games.
Nothing else matters yet — no growth, no revenue targets.

## 3. Scope decisions (locked)

- **Closed-circle first.** v1 targets the author + friends + friends-of-friends, not
  strangers. This sidesteps the marketplace liquidity problem and lets us skip trust/rating
  in v1.
- **Cross-platform** (iOS + Android) from one codebase.
- **No payments.** Court cost is split in cash between players, off-app.
- **No in-app chat.** Link to an existing WhatsApp/Viber group per match instead.

## 4. Core loop

```
Organizer   creates match  ->  venue (map) + sport + date/time + total players + spots missing
Players     browse open matches nearby  ->  tap "I'm in" (join a spot)
When full   match locks  ->  push notification to everyone: "we have a game"
If someone leaves  ->  a spot reopens  ->  match goes back to "open", players notified
```

If this loop feels fast and reliable, the app has succeeded.

## 5. v1 features (in)

- **Auth:** email + Google sign-in (Firebase Auth).
- **Create match:** sport, venue picked on a map, date + time, total players, spots missing,
  optional external chat link (WhatsApp/Viber).
- **Discover:** list + map of open matches near the user, filterable by sport.
- **Join / leave:** claim or release a spot; state updates live for all participants.
- **Notifications (FCM):** match full, spot reopened, match starting soon.
- **Basic profile:** name, avatar, preferred sports.

## 6. Explicitly out of v1 (deferred)

| Feature | Why deferred |
|---|---|
| Payments / court cost split | Cash off-app. Payments = KYC/refunds/disputes, huge scope. |
| Rating / reputation / no-show tracking | Not needed in a closed circle. Add before opening to strangers. |
| In-app chat | WhatsApp/Viber already exists; link out. |
| Teams / leagues / standings / stats | v2 social layer. |
| Recurring matches | v2 convenience. |

## 7. Data model (Cloud Firestore)

Firestore over Realtime Database: better querying for "open matches near me, by sport".

### `users/{uid}`
```
{
  uid: string,
  displayName: string,
  photoUrl: string | null,
  preferredSports: string[],        // e.g. ["football", "basketball"]
  fcmTokens: string[],              // for push targeting
  createdAt: timestamp
}
```

### `matches/{matchId}`
```
{
  id: string,
  sport: string,                    // enum: football | basketball | tennis | ...
  organizerId: string,              // users/{uid}
  venue: {
    name: string,                   // "Athlopolis, Patra"
    geo: geopoint,                  // for proximity queries
  },
  startAt: timestamp,
  totalPlayers: number,             // e.g. 14 (7v7)
  status: string,                   // enum: open | full | cancelled | finished
  chatLink: string | null,          // external WhatsApp/Viber invite
  playerIds: string[],              // denormalized for quick "am I in?" checks
  spotsMissing: number,             // derived: totalPlayers - playerIds.length (kept in sync
                                    //          server-side to stay authoritative)
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### `matches/{matchId}/participants/{uid}` (subcollection)
```
{
  uid: string,
  joinedAt: timestamp,
  role: string                      // organizer | player
}
```

**Why a subcollection AND a `playerIds` array:** the array makes "is this match full?" and
list rendering cheap; the subcollection is the authoritative membership record with
timestamps. Kept in sync by a Cloud Function (see below).

## 8. Server-authoritative logic (Cloud Functions)

Learning from the previous project: **do not let clients mutate shared/derived state
directly.** These run server-side:

- `onJoinMatch` — transactionally add participant, recompute `spotsMissing`, flip `status`
  to `full` when it hits 0. Reject if already full or already joined.
- `onLeaveMatch` — remove participant, reopen a spot, flip `status` back to `open`.
- `onMatchFull` — send FCM to all participants ("we have a game").
- `onSpotReopened` — notify participants a spot opened up.
- Scheduled `matchStartingSoon` — reminder push before `startAt`.

## 9. Firestore Security Rules (v1 intent)

- A user can read/write only their own `users/{uid}` doc.
- Anyone signed-in can **read** `open`/`full` matches.
- Only the organizer can edit core match fields or cancel.
- `playerIds`, `spotsMissing`, `status` are **writable only by Cloud Functions** (clients
  join/leave via callable functions, never by writing these fields directly).

## 10. Screens (v1)

1. **Auth** — sign in (email / Google), register.
2. **Home / Discover** — map + list toggle of open matches nearby, sport filter.
3. **Match detail** — venue, time, who's in, spots missing, Join/Leave, chat link.
4. **Create match** — form + map venue picker.
5. **My matches** — matches I organize or joined.
6. **Profile** — name, avatar, preferred sports, sign out.

## 11. Tech stack

| Concern | Choice |
|---|---|
| App | Flutter (Dart), one codebase for iOS + Android |
| Auth | Firebase Auth (email + Google) |
| Database | Cloud Firestore |
| Push | Firebase Cloud Messaging (FCM) |
| Maps | `google_maps_flutter` |
| Backend logic | Cloud Functions (join/leave/notify only) |

Rationale: zero servers to maintain, generous free tier, everything integrates. Firestore
chosen over Realtime DB specifically for geo/sport queries.

## 12. Roadmap

- **v1** — core loop above, closed circle.
- **v1.1** — rating / no-show tracking (prerequisite for opening to strangers).
- **v2** — recurring matches, teams, in-app chat, stats.

The full backlog — app features, infrastructure/observability, DevOps, and
ideas — lives in [ROADMAP.md](./ROADMAP.md).

## 13. Open questions

- Proximity query approach: Firestore geohashing (`geoflutterfire`) vs. simple city/area tag
  filter for v1? (Leaning: area tag is enough for v1, geohash later.)
- Google Places for venue autocomplete, or free-text + map pin only? (Leaning: map pin only
  in v1 to avoid Places API cost/complexity.)
- Minimum viable notification set — is "match full" alone enough to be useful?
