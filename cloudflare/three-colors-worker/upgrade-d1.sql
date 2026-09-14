ALTER TABLE game_events ADD COLUMN event_key TEXT;
ALTER TABLE game_events ADD COLUMN real_seconds_since_day3_start REAL;
ALTER TABLE game_events ADD COLUMN town_feel TEXT;
ALTER TABLE game_events ADD COLUMN time_natural TEXT;
ALTER TABLE game_events ADD COLUMN total_real_seconds REAL;
ALTER TABLE game_events ADD COLUMN final_day INTEGER;
ALTER TABLE game_events ADD COLUMN ended_via TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_game_events_event_key ON game_events(event_key);
