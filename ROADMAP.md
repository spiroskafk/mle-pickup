# MLE — Roadmap

Where the project is and what could come next. This is a living wishlist, not a
commitment — it's a side project. [SPEC.md](./SPEC.md) is the source of truth
for what v1 *is*; this file is for what's *next*.

Legend: ✅ done · 🔜 next up · 💤 later · 💭 idea

---

## Where we are today

The v1 core loop is **built and verified end-to-end against the Firebase
Emulator Suite**:

- ✅ Auth (email/password), register + sign-in
- ✅ Create match (sport, venue, time, player count, chat link)
- ✅ Discover open matches (live list)
- ✅ Join / leave / cancel — server-authoritative via Cloud Functions
- ✅ Notification trigger on match full / spot reopened (FCM)
- ✅ Firestore security rules (clients can't write shared state)
- ✅ CI (GitHub Actions: analyze, test, format, functions build)
- ✅ IaC (Terraform: GCP project, APIs, Firestore, budget alert)

Not yet run on a real Firebase project (needs a billing account) or on physical
devices with a Google Maps key.

---

## App features

### 🔜 Next up
- **My matches** screen — matches I organize or joined (repository method
  `watchForPlayer` already exists; needs a screen + nav).
- **Profile** screen — display name, avatar, preferred sports (edit path).
- **Sport filter** on the discover screen (repository already supports it).
- **Register/sign-in polish** — password reset, better validation messages.

### 💤 Later
- **Map view of matches** on discover (pins by location). Needs a maps
  provider — see *Maps* under Infrastructure.
- **Match detail improvements** — participant list with names/avatars, "starts
  in 3h" relative time, deep-link to the chat.
- **Push notifications wired client-side** — FCM token registration into
  `users/{uid}` (the backend already targets these tokens; the client isn't
  registering them yet).
- **Recurring matches** — "every Wednesday 22:00" templates.

### 💭 Ideas (need product thought first)
- **Ratings / no-show tracking** — prerequisite before opening to strangers
  (deliberately skipped in the closed-circle v1; see SPEC §6).
- **Teams / leagues / standings / stats** — the social layer.
- **In-app chat** — currently we link out to WhatsApp/Viber on purpose.
- **Waitlist** — when a match is full, queue players for reopened spots.
- **Invite links** — share a match to a group chat, join via link.

---

## Infrastructure & DevOps

### 🔜 Next up
- **Observability**
  - Structured logging in Cloud Functions (request id, uid, matchId) instead of
    default logs.
  - Firebase **Crashlytics** + **Performance Monitoring** (near plug-and-play).
  - Cloud Functions logs → **Cloud Logging** → export to **Grafana**
    (log-based metrics, error-rate alerts on the callables).
- **Terraform `apply`** to a real `dev` project once a billing account is
  attached (config is written and `validate`s today; only `apply` is deferred).

### 💤 Later
- **Maps provider decision** — Google Maps SDK (free on mobile, needs a billing
  account) vs. `flutter_map` + OpenStreetMap/MapTiler (no card). Currently the
  venue picker falls back to a manual form on web. See discussion in git history.
- **Remote Terraform state** — move to a GCS backend (block is ready to
  uncomment in `infra/versions.tf`) once more than one machine/person touches it.
- **CI extensions**
  - `terraform fmt -check` + `terraform validate` job in CI.
  - Firestore rules unit tests (`@firebase/rules-unit-testing`) run in CI.
  - Build + upload debug APK as a CI artifact per PR.
- **Release engineering** — Fastlane for signing + store deployment, semantic
  versioning, changelog generation.
- **Preview/staging environment** — `dev` vs `prod` Firebase projects from the
  same Terraform (tfvars already separate them); wire CI to deploy `dev` on
  merge to `main`.

### 💭 Ideas
- **CD to Firebase** — auto `firebase deploy` (rules + functions) on merge, once
  a real project exists and CI holds deploy credentials (Workload Identity).
- **Cost dashboard** — surface the budget/usage in Grafana alongside the app
  metrics.
- **E2E tests** against the emulator in CI (integration_test + emulators).

---

## Known limitations to revisit

- **Google sign-in doesn't work on the Auth emulator** — real OAuth flow needs a
  real project. Email/password works everywhere.
- **No Maps on web** — falls back to manual venue entry until a maps provider is
  wired up.
- **Firestore proximity queries** — v1 has no geo-radius query; discover shows
  all open matches. Options: Firestore geohashing (`geoflutterfire`) or a simple
  area/city tag. See SPEC §13.
- **Single region** — Firestore location is fixed at creation; chosen `eur3`.

---

## Contributing to this roadmap

Anything here is up for grabs and reorderable. When something moves from 🔜 to
✅, update [SPEC.md](./SPEC.md)'s status line too so the two stay in sync.
