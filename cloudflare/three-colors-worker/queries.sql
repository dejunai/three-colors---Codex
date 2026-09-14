-- Event totals and distinct playthroughs. The fixed UUID below belongs to the
-- deployment verification batch and should never count as a player session.
SELECT event, COUNT(*) AS events, COUNT(DISTINCT session_id) AS sessions
FROM game_events
WHERE session_id != '11111111-1111-4111-8111-111111111111'
GROUP BY event
ORDER BY event;

-- Typical transition cost and duration by route.
SELECT from_world, to_world, COUNT(*) AS trips,
       ROUND(AVG(real_seconds_elapsed), 2) AS avg_real_seconds,
       ROUND(AVG(game_minutes_elapsed), 2) AS avg_game_minutes
FROM game_events
WHERE event = 'district_transition'
  AND session_id != '11111111-1111-4111-8111-111111111111'
GROUP BY from_world, to_world
ORDER BY trips DESC;

-- Day-phase reach and social activity.
SELECT day, new_phase, COUNT(DISTINCT session_id) AS sessions,
       ROUND(AVG(npcs_spoken_to_this_phase), 2) AS avg_npcs_spoken_to
FROM game_events
WHERE event = 'phase_change'
  AND session_id != '11111111-1111-4111-8111-111111111111'
GROUP BY day, new_phase
ORDER BY day, CASE new_phase WHEN 'morning' THEN 1 WHEN 'noon' THEN 2 WHEN 'evening' THEN 3 ELSE 4 END;

-- Completed conversations by NPC, topic, and Walter's coat.
SELECT npc_id, topic_id, coat_state, COUNT(*) AS completions,
       COUNT(DISTINCT session_id) AS sessions
FROM game_events
WHERE event = 'conversation'
  AND session_id != '11111111-1111-4111-8111-111111111111'
GROUP BY npc_id, topic_id, coat_state
ORDER BY sessions DESC, completions DESC, npc_id, topic_id;

-- End-of-slice tester impressions.
SELECT town_feel, time_natural, COUNT(*) AS responses
FROM game_events
WHERE event = 'debrief'
  AND session_id != '11111111-1111-4111-8111-111111111111'
GROUP BY town_feel, time_natural
ORDER BY responses DESC;

-- Completion and abandonment signals.
SELECT ended_via, final_day, COUNT(*) AS sessions,
       ROUND(AVG(total_real_seconds) / 60.0, 1) AS avg_real_minutes
FROM game_events
WHERE event = 'session_end'
  AND session_id != '11111111-1111-4111-8111-111111111111'
GROUP BY ended_via, final_day
ORDER BY final_day, ended_via;
