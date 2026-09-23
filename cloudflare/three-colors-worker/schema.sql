CREATE TABLE IF NOT EXISTS game_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_key TEXT,
  session_id TEXT NOT NULL,
  event TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  from_world TEXT,
  to_world TEXT,
  real_seconds_elapsed REAL,
  game_minutes_elapsed REAL,
  day INTEGER,
  new_phase TEXT,
  npcs_spoken_to_this_phase INTEGER,
  real_seconds_since_day3_start REAL,
  town_feel TEXT,
  time_natural TEXT,
  total_real_seconds REAL,
  final_day INTEGER,
  ended_via TEXT,
  npc_id TEXT,
  topic_id TEXT,
  coat_state TEXT,
  world TEXT,
  phase TEXT,
  dev_brisk_used INTEGER,
  page_origin TEXT,
  received_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_game_events_session ON game_events(session_id);
CREATE INDEX IF NOT EXISTS idx_game_events_event ON game_events(event);
CREATE INDEX IF NOT EXISTS idx_game_events_timestamp ON game_events(timestamp);
CREATE UNIQUE INDEX IF NOT EXISTS idx_game_events_event_key ON game_events(event_key);
CREATE INDEX IF NOT EXISTS idx_game_events_conversation_npc ON game_events(npc_id) WHERE event = 'conversation';
