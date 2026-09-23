# three-colors-worker

This Worker accepts the game's anonymous event batches and dual-writes each accepted event to D1 (`three-colors-db`) and each accepted batch to the `three-colors-logs` R2 bucket under `events/YYYY-MM-DD/<random UUID>.json`. D1 is the queryable store; R2 remains the raw verification archive during migration. A deterministic event key makes retried D1 inserts idempotent.

It stores only the allowlisted game-event fields. Session endings include the sticky `dev_brisk_used` boolean so development-speed playthroughs can be separated from player-speed timing data. It does not copy request headers, IP addresses, user agents, or other request metadata into either store. There is no public read route. Apply `add-dev-brisk-d1.sql` to an existing D1 database before deploying this Worker revision.

Accepted POSTs return HTTP 200 with a small JSON acknowledgement body (`{"accepted": n}`). Keep this body: Godot 4.7 Web exports report a successful 204 response as a connection error with response code 0, which prevents the client from retiring delivered events. The game caps ordinary request batches at this Worker's 32-event maximum.

Deploy from this directory with `npx wrangler deploy`. After deployment, copy the resulting HTTPS URL into the Godot project setting `three_colors/telemetry_endpoint`. Confirm a real GitHub Pages request and a real itch.io request both return HTTP 200 with the accepted count before publishing a telemetry-enabled build.
