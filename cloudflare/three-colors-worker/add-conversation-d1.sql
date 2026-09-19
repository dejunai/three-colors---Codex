ALTER TABLE game_events ADD COLUMN npc_id TEXT;
ALTER TABLE game_events ADD COLUMN topic_id TEXT;
ALTER TABLE game_events ADD COLUMN coat_state TEXT;
ALTER TABLE game_events ADD COLUMN world TEXT;
ALTER TABLE game_events ADD COLUMN phase TEXT;
CREATE INDEX IF NOT EXISTS idx_game_events_conversation_npc
  ON game_events(npc_id) WHERE event = 'conversation';
