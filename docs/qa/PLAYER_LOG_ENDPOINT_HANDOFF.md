# Anonymous player log endpoint handoff

The game-side logger is enabled at `https://three-colors-worker.dejunai.workers.dev` through the single `three_colors/telemetry_endpoint` setting in `project.godot`.

The selected receiver is the `three-colors-worker` Cloudflare Worker backed by the `three-colors-logs` R2 bucket, bound to the Worker as `BUCKET_ONE`. Its source and Wrangler configuration live in `cloudflare/three-colors-worker/`.

Deployment verified on 2026-09-13 as Cloudflare Worker version `87e1bd4e-9646-468a-b3be-1397534feb4b`. Live GitHub Pages and itch.io preflights, a synthetic `session_start`, and the later `debrief` event all returned HTTP 204. Because the Worker awaits `BUCKET_ONE.put()` before returning 204, each successful POST also verifies the R2 write path.

The Worker must accept `POST` with a JSON body shaped as `{ "events": [event, ...] }`. Every event has only `session_id`, `event`, and a UTC client timestamp plus the event fields defined in `docs/LOG_PLAYER_ASK.md`. The receiver should reject unknown keys, avoid copying request headers or IP addresses into storage, and return a 2xx response only after storage succeeds.

CORS must allow `POST` and `Content-Type` from the GitHub Pages and itch.io origins used for testing. The implementation should answer browser preflight `OPTIONS` requests. Test both deployed origins before enabling the endpoint in a published build.

The author can inspect or download stored JSON batches through the Cloudflare R2 dashboard. The Worker deliberately has no public read route.

Game-side behavior:

- Each New Game creates a cryptographically random UUID v4 and replaces the internal resume token.
- Continue in the same process keeps the current ID; reopening the application and loading the current save restores the ID from `user://anonymous_playthrough_session.json`.
- Events remain buffered when the endpoint is blank or unreachable. A failed request waits for the next event before trying again and never stalls gameplay.
- Completed sessions remove the internal resume token.
- Browser close delivery is best effort. Earlier events are sent incrementally, so closing a tab can lose only the current buffered request rather than the full playthrough.
