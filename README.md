# MLE

**MLE** stands for *Mas Leipei Enas* — Greek for **"we're one short"**, the phrase every
pickup-game organizer knows too well. It's a crowd-sourced, hyper-local app for filling the
last open spots in casual sports games (football 5x5, basketball, and more).

You've booked the court — *Athlopolis, Patra, Wednesday 22:00, 13 players, one missing.* MLE
broadcasts that open spot to nearby players so the game actually happens.

## Status

🚧 **Early — spec stage.** No app code yet. The full plan lives in
**[SPEC.md](./SPEC.md)**: product scope, core loop, Firestore data model, screens, and the
tech stack.

## How it works (core loop)

1. **Create a match** — pick a sport, a venue on the map, a date/time, and how many players
   you're missing.
2. **Nearby players discover it** — browse open matches on a map or list, filtered by sport.
3. **They claim a spot** — one tap to join.
4. **It fills → everyone's notified** — "we have a game." If someone drops, the spot reopens.

## Tech stack

- **Flutter** (iOS + Android from one codebase)
- **Firebase** — Auth, Cloud Firestore, Cloud Messaging (push)
- **Cloud Functions** for server-authoritative join/leave/notify logic
- **Google Maps** for venue selection and discovery

## Roadmap

- **v1** — the core loop above, for a closed circle of friends. **Built and
  verified end-to-end against the Firebase emulators.**
- **v1.1** — player ratings & no-show tracking (before opening to strangers).
- **v2** — recurring matches, teams, in-app chat, stats.

See [SPEC.md](./SPEC.md) for the v1 spec and [ROADMAP.md](./ROADMAP.md) for the
full backlog (app features, infrastructure/observability, and ideas).

## License

MIT — see [LICENSE](./LICENSE).
