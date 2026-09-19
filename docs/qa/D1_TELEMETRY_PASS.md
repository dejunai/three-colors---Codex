# D1 telemetry migration — 2026-09-14

The deployed `three-colors-worker` now dual-writes every validated telemetry event to the queryable `three-colors-db` D1 database and preserves the original batch in the `three-colors-logs` R2 bucket. R2 remains available as a raw verification archive while D1 becomes the analysis store.

Updated 2026-09-14: completed authored conversations are now a dedicated
`conversation` event. Each row records canonical `npc_id` and `topic_id`,
Walter's `coat_state` (`police` or `plain`), `world`, `day`, and `phase`.
Logging occurs only after the entire topic path completes; opening a topic
menu, abandoning a sequence, or pausing at an intermediate fork does not
count. The additive D1 migration and Worker deployment were completed as
version `e8796fae-2b80-4ba5-a856-f6cdce93dc4f`. A reserved synthetic event
returned HTTP 204 and was queried back with every field intact.

Telemetry duration normalization was added immediately afterward: new real
elapsed durations are emitted as whole seconds, and transition game time is
rounded to one decimal minute. This is a game-side payload cleanup only;
existing D1 `REAL` columns and historical rows require no migration.

The remote table was upgraded additively with typed columns for every currently accepted event family and a deterministic SHA-256 `event_key`. A unique index plus `INSERT OR IGNORE` makes D1 ingestion idempotent when the game retries a batch after a partial network or storage failure. Existing session, event and timestamp indexes remain in place.

Worker version `3d0b619c-c5f3-4e4e-959b-2c0d3b07b894` was deployed with both live bindings:

- `env.DB` → `three-colors-db`
- `env.BUCKET_ONE` → `three-colors-logs`

Verification used the reserved synthetic session `11111111-1111-4111-8111-111111111111`. One seven-event batch covered `session_start`, `first_objective`, `district_transition`, `phase_change`, `day3_bed_reached`, `debrief`, and `session_end`; the endpoint returned HTTP 204 and all seven typed rows were queried successfully from remote D1. Sending the identical batch again returned HTTP 204 while D1 remained at seven rows with seven distinct event keys.

`cloudflare/three-colors-worker/queries.sql` contains starter aggregate queries and excludes this reserved verification session. The R2 copy of the synthetic batch remains intentionally as deployment evidence.
