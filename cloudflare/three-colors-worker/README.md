# three-colors-worker

This Worker accepts the game's anonymous event batches and dual-writes each accepted event to D1 (`three-colors-db`) and each accepted batch to the `three-colors-logs` R2 bucket under `events/YYYY-MM-DD/<random UUID>.json`. D1 is the queryable store; R2 remains the raw verification archive during migration. A deterministic event key makes retried D1 inserts idempotent.

It stores only the allowlisted game-event fields. It does not copy request headers, IP addresses, user agents, or other request metadata into either store. There is no public read route.

Deploy from this directory with `npx wrangler deploy`. After deployment, copy the resulting HTTPS URL into the Godot project setting `three_colors/telemetry_endpoint`. Confirm a real GitHub Pages request and a real itch.io request both return HTTP 204 before publishing a telemetry-enabled build.
