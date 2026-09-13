# Anonymous player log endpoint handoff

The game-side logger is implemented with its endpoint blank. It stays entirely inert on the network until `three_colors/telemetry_endpoint` is configured in `project.godot` or at deployment time.

The recommended receiver is a Cloudflare Worker backed by D1. It has little maintenance overhead, gives the project a queryable event table, and avoids adding a third-party analytics SDK. This choice still needs the author's approval before the receiver is created or the game is pointed at it.

The Worker must accept `POST` with a JSON body shaped as `{ "events": [event, ...] }`. Every event has only `session_id`, `event`, and a UTC client timestamp plus the event fields defined in `docs/LOG_PLAYER_ASK.md`. The receiver should reject unknown keys, avoid copying request headers or IP addresses into storage, and return a 2xx response only after storage succeeds.

CORS must allow `POST` and `Content-Type` from the GitHub Pages and itch.io origins used for testing. The implementation should answer browser preflight `OPTIONS` requests. Test both deployed origins before enabling the endpoint in a published build.

The author will need read-only access to the D1 database or a small authenticated export route that returns JSON/CSV. Do not expose collected events through a public unauthenticated route.

Game-side behavior:

- Each New Game creates a cryptographically random UUID v4 and replaces the internal resume token.
- Continue in the same process keeps the current ID; reopening the application and loading the current save restores the ID from `user://anonymous_playthrough_session.json`.
- Events remain buffered when the endpoint is blank or unreachable. A failed request waits for the next event before trying again and never stalls gameplay.
- Completed sessions remove the internal resume token.
- Browser close delivery is best effort. Earlier events are sent incrementally, so closing a tab can lose only the current buffered request rather than the full playthrough.
